
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Simple Notification Service
## version: 2010-03-31
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon Simple Notification Service</fullname> <p>Amazon Simple Notification Service (Amazon SNS) is a web service that enables you to build distributed web-enabled applications. Applications can use Amazon SNS to easily push real-time notification messages to interested subscribers over multiple delivery protocols. For more information about this product see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. For detailed information about Amazon SNS features and their associated API calls, see the <a href="https://docs.aws.amazon.com/sns/latest/dg/">Amazon SNS Developer Guide</a>. </p> <p>We also provide SDKs that enable you to access Amazon SNS from your preferred programming language. The SDKs contain functionality that automatically takes care of tasks such as: cryptographically signing your service requests, retrying requests, and handling error responses. For a list of available SDKs, go to <a href="http://aws.amazon.com/tools/">Tools for Amazon Web Services</a>. </p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/sns/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "sns.ap-northeast-1.amazonaws.com", "ap-southeast-1": "sns.ap-southeast-1.amazonaws.com",
                           "us-west-2": "sns.us-west-2.amazonaws.com",
                           "eu-west-2": "sns.eu-west-2.amazonaws.com", "ap-northeast-3": "sns.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "sns.eu-central-1.amazonaws.com",
                           "us-east-2": "sns.us-east-2.amazonaws.com",
                           "us-east-1": "sns.us-east-1.amazonaws.com", "cn-northwest-1": "sns.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "sns.ap-south-1.amazonaws.com",
                           "eu-north-1": "sns.eu-north-1.amazonaws.com", "ap-northeast-2": "sns.ap-northeast-2.amazonaws.com",
                           "us-west-1": "sns.us-west-1.amazonaws.com",
                           "us-gov-east-1": "sns.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "sns.eu-west-3.amazonaws.com",
                           "cn-north-1": "sns.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "sns.sa-east-1.amazonaws.com",
                           "eu-west-1": "sns.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "sns.us-gov-west-1.amazonaws.com", "ap-southeast-2": "sns.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "sns.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "sns.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "sns.ap-southeast-1.amazonaws.com",
      "us-west-2": "sns.us-west-2.amazonaws.com",
      "eu-west-2": "sns.eu-west-2.amazonaws.com",
      "ap-northeast-3": "sns.ap-northeast-3.amazonaws.com",
      "eu-central-1": "sns.eu-central-1.amazonaws.com",
      "us-east-2": "sns.us-east-2.amazonaws.com",
      "us-east-1": "sns.us-east-1.amazonaws.com",
      "cn-northwest-1": "sns.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "sns.ap-south-1.amazonaws.com",
      "eu-north-1": "sns.eu-north-1.amazonaws.com",
      "ap-northeast-2": "sns.ap-northeast-2.amazonaws.com",
      "us-west-1": "sns.us-west-1.amazonaws.com",
      "us-gov-east-1": "sns.us-gov-east-1.amazonaws.com",
      "eu-west-3": "sns.eu-west-3.amazonaws.com",
      "cn-north-1": "sns.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "sns.sa-east-1.amazonaws.com",
      "eu-west-1": "sns.eu-west-1.amazonaws.com",
      "us-gov-west-1": "sns.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "sns.ap-southeast-2.amazonaws.com",
      "ca-central-1": "sns.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "sns"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_PostAddPermission_601042 = ref object of OpenApiRestCall_600426
proc url_PostAddPermission_601044(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostAddPermission_601043(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601045 = query.getOrDefault("Action")
  valid_601045 = validateParameter(valid_601045, JString, required = true,
                                 default = newJString("AddPermission"))
  if valid_601045 != nil:
    section.add "Action", valid_601045
  var valid_601046 = query.getOrDefault("Version")
  valid_601046 = validateParameter(valid_601046, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601046 != nil:
    section.add "Version", valid_601046
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601047 = header.getOrDefault("X-Amz-Date")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Date", valid_601047
  var valid_601048 = header.getOrDefault("X-Amz-Security-Token")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-Security-Token", valid_601048
  var valid_601049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "X-Amz-Content-Sha256", valid_601049
  var valid_601050 = header.getOrDefault("X-Amz-Algorithm")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Algorithm", valid_601050
  var valid_601051 = header.getOrDefault("X-Amz-Signature")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-Signature", valid_601051
  var valid_601052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601052 = validateParameter(valid_601052, JString, required = false,
                                 default = nil)
  if valid_601052 != nil:
    section.add "X-Amz-SignedHeaders", valid_601052
  var valid_601053 = header.getOrDefault("X-Amz-Credential")
  valid_601053 = validateParameter(valid_601053, JString, required = false,
                                 default = nil)
  if valid_601053 != nil:
    section.add "X-Amz-Credential", valid_601053
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   AWSAccountId: JArray (required)
  ##               : The AWS account IDs of the users (principals) who will be given access to the specified actions. The users must have AWS accounts, but do not need to be signed up for this service.
  ##   Label: JString (required)
  ##        : A unique identifier for the new policy statement.
  ##   ActionName: JArray (required)
  ##             : <p>The action you want to allow for the specified principal(s).</p> <p>Valid values: any Amazon SNS action name.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_601054 = formData.getOrDefault("TopicArn")
  valid_601054 = validateParameter(valid_601054, JString, required = true,
                                 default = nil)
  if valid_601054 != nil:
    section.add "TopicArn", valid_601054
  var valid_601055 = formData.getOrDefault("AWSAccountId")
  valid_601055 = validateParameter(valid_601055, JArray, required = true, default = nil)
  if valid_601055 != nil:
    section.add "AWSAccountId", valid_601055
  var valid_601056 = formData.getOrDefault("Label")
  valid_601056 = validateParameter(valid_601056, JString, required = true,
                                 default = nil)
  if valid_601056 != nil:
    section.add "Label", valid_601056
  var valid_601057 = formData.getOrDefault("ActionName")
  valid_601057 = validateParameter(valid_601057, JArray, required = true, default = nil)
  if valid_601057 != nil:
    section.add "ActionName", valid_601057
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601058: Call_PostAddPermission_601042; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  let valid = call_601058.validator(path, query, header, formData, body)
  let scheme = call_601058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601058.url(scheme.get, call_601058.host, call_601058.base,
                         call_601058.route, valid.getOrDefault("path"))
  result = hook(call_601058, url, valid)

proc call*(call_601059: Call_PostAddPermission_601042; TopicArn: string;
          AWSAccountId: JsonNode; Label: string; ActionName: JsonNode;
          Action: string = "AddPermission"; Version: string = "2010-03-31"): Recallable =
  ## postAddPermission
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   AWSAccountId: JArray (required)
  ##               : The AWS account IDs of the users (principals) who will be given access to the specified actions. The users must have AWS accounts, but do not need to be signed up for this service.
  ##   Label: string (required)
  ##        : A unique identifier for the new policy statement.
  ##   Action: string (required)
  ##   ActionName: JArray (required)
  ##             : <p>The action you want to allow for the specified principal(s).</p> <p>Valid values: any Amazon SNS action name.</p>
  ##   Version: string (required)
  var query_601060 = newJObject()
  var formData_601061 = newJObject()
  add(formData_601061, "TopicArn", newJString(TopicArn))
  if AWSAccountId != nil:
    formData_601061.add "AWSAccountId", AWSAccountId
  add(formData_601061, "Label", newJString(Label))
  add(query_601060, "Action", newJString(Action))
  if ActionName != nil:
    formData_601061.add "ActionName", ActionName
  add(query_601060, "Version", newJString(Version))
  result = call_601059.call(nil, query_601060, nil, formData_601061, nil)

var postAddPermission* = Call_PostAddPermission_601042(name: "postAddPermission",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=AddPermission", validator: validate_PostAddPermission_601043,
    base: "/", url: url_PostAddPermission_601044,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddPermission_600768 = ref object of OpenApiRestCall_600426
proc url_GetAddPermission_600770(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAddPermission_600769(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ActionName: JArray (required)
  ##             : <p>The action you want to allow for the specified principal(s).</p> <p>Valid values: any Amazon SNS action name.</p>
  ##   Action: JString (required)
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Version: JString (required)
  ##   Label: JString (required)
  ##        : A unique identifier for the new policy statement.
  ##   AWSAccountId: JArray (required)
  ##               : The AWS account IDs of the users (principals) who will be given access to the specified actions. The users must have AWS accounts, but do not need to be signed up for this service.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ActionName` field"
  var valid_600882 = query.getOrDefault("ActionName")
  valid_600882 = validateParameter(valid_600882, JArray, required = true, default = nil)
  if valid_600882 != nil:
    section.add "ActionName", valid_600882
  var valid_600896 = query.getOrDefault("Action")
  valid_600896 = validateParameter(valid_600896, JString, required = true,
                                 default = newJString("AddPermission"))
  if valid_600896 != nil:
    section.add "Action", valid_600896
  var valid_600897 = query.getOrDefault("TopicArn")
  valid_600897 = validateParameter(valid_600897, JString, required = true,
                                 default = nil)
  if valid_600897 != nil:
    section.add "TopicArn", valid_600897
  var valid_600898 = query.getOrDefault("Version")
  valid_600898 = validateParameter(valid_600898, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600898 != nil:
    section.add "Version", valid_600898
  var valid_600899 = query.getOrDefault("Label")
  valid_600899 = validateParameter(valid_600899, JString, required = true,
                                 default = nil)
  if valid_600899 != nil:
    section.add "Label", valid_600899
  var valid_600900 = query.getOrDefault("AWSAccountId")
  valid_600900 = validateParameter(valid_600900, JArray, required = true, default = nil)
  if valid_600900 != nil:
    section.add "AWSAccountId", valid_600900
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600901 = header.getOrDefault("X-Amz-Date")
  valid_600901 = validateParameter(valid_600901, JString, required = false,
                                 default = nil)
  if valid_600901 != nil:
    section.add "X-Amz-Date", valid_600901
  var valid_600902 = header.getOrDefault("X-Amz-Security-Token")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-Security-Token", valid_600902
  var valid_600903 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600903 = validateParameter(valid_600903, JString, required = false,
                                 default = nil)
  if valid_600903 != nil:
    section.add "X-Amz-Content-Sha256", valid_600903
  var valid_600904 = header.getOrDefault("X-Amz-Algorithm")
  valid_600904 = validateParameter(valid_600904, JString, required = false,
                                 default = nil)
  if valid_600904 != nil:
    section.add "X-Amz-Algorithm", valid_600904
  var valid_600905 = header.getOrDefault("X-Amz-Signature")
  valid_600905 = validateParameter(valid_600905, JString, required = false,
                                 default = nil)
  if valid_600905 != nil:
    section.add "X-Amz-Signature", valid_600905
  var valid_600906 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600906 = validateParameter(valid_600906, JString, required = false,
                                 default = nil)
  if valid_600906 != nil:
    section.add "X-Amz-SignedHeaders", valid_600906
  var valid_600907 = header.getOrDefault("X-Amz-Credential")
  valid_600907 = validateParameter(valid_600907, JString, required = false,
                                 default = nil)
  if valid_600907 != nil:
    section.add "X-Amz-Credential", valid_600907
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600930: Call_GetAddPermission_600768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  let valid = call_600930.validator(path, query, header, formData, body)
  let scheme = call_600930.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600930.url(scheme.get, call_600930.host, call_600930.base,
                         call_600930.route, valid.getOrDefault("path"))
  result = hook(call_600930, url, valid)

proc call*(call_601001: Call_GetAddPermission_600768; ActionName: JsonNode;
          TopicArn: string; Label: string; AWSAccountId: JsonNode;
          Action: string = "AddPermission"; Version: string = "2010-03-31"): Recallable =
  ## getAddPermission
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ##   ActionName: JArray (required)
  ##             : <p>The action you want to allow for the specified principal(s).</p> <p>Valid values: any Amazon SNS action name.</p>
  ##   Action: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Version: string (required)
  ##   Label: string (required)
  ##        : A unique identifier for the new policy statement.
  ##   AWSAccountId: JArray (required)
  ##               : The AWS account IDs of the users (principals) who will be given access to the specified actions. The users must have AWS accounts, but do not need to be signed up for this service.
  var query_601002 = newJObject()
  if ActionName != nil:
    query_601002.add "ActionName", ActionName
  add(query_601002, "Action", newJString(Action))
  add(query_601002, "TopicArn", newJString(TopicArn))
  add(query_601002, "Version", newJString(Version))
  add(query_601002, "Label", newJString(Label))
  if AWSAccountId != nil:
    query_601002.add "AWSAccountId", AWSAccountId
  result = call_601001.call(nil, query_601002, nil, nil, nil)

var getAddPermission* = Call_GetAddPermission_600768(name: "getAddPermission",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=AddPermission", validator: validate_GetAddPermission_600769,
    base: "/", url: url_GetAddPermission_600770,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCheckIfPhoneNumberIsOptedOut_601078 = ref object of OpenApiRestCall_600426
proc url_PostCheckIfPhoneNumberIsOptedOut_601080(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCheckIfPhoneNumberIsOptedOut_601079(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601081 = query.getOrDefault("Action")
  valid_601081 = validateParameter(valid_601081, JString, required = true, default = newJString(
      "CheckIfPhoneNumberIsOptedOut"))
  if valid_601081 != nil:
    section.add "Action", valid_601081
  var valid_601082 = query.getOrDefault("Version")
  valid_601082 = validateParameter(valid_601082, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601082 != nil:
    section.add "Version", valid_601082
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601083 = header.getOrDefault("X-Amz-Date")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-Date", valid_601083
  var valid_601084 = header.getOrDefault("X-Amz-Security-Token")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "X-Amz-Security-Token", valid_601084
  var valid_601085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Content-Sha256", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-Algorithm")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Algorithm", valid_601086
  var valid_601087 = header.getOrDefault("X-Amz-Signature")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-Signature", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-SignedHeaders", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Credential")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Credential", valid_601089
  result.add "header", section
  ## parameters in `formData` object:
  ##   phoneNumber: JString (required)
  ##              : The phone number for which you want to check the opt out status.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `phoneNumber` field"
  var valid_601090 = formData.getOrDefault("phoneNumber")
  valid_601090 = validateParameter(valid_601090, JString, required = true,
                                 default = nil)
  if valid_601090 != nil:
    section.add "phoneNumber", valid_601090
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601091: Call_PostCheckIfPhoneNumberIsOptedOut_601078;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ## 
  let valid = call_601091.validator(path, query, header, formData, body)
  let scheme = call_601091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601091.url(scheme.get, call_601091.host, call_601091.base,
                         call_601091.route, valid.getOrDefault("path"))
  result = hook(call_601091, url, valid)

proc call*(call_601092: Call_PostCheckIfPhoneNumberIsOptedOut_601078;
          phoneNumber: string; Action: string = "CheckIfPhoneNumberIsOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## postCheckIfPhoneNumberIsOptedOut
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ##   Action: string (required)
  ##   phoneNumber: string (required)
  ##              : The phone number for which you want to check the opt out status.
  ##   Version: string (required)
  var query_601093 = newJObject()
  var formData_601094 = newJObject()
  add(query_601093, "Action", newJString(Action))
  add(formData_601094, "phoneNumber", newJString(phoneNumber))
  add(query_601093, "Version", newJString(Version))
  result = call_601092.call(nil, query_601093, nil, formData_601094, nil)

var postCheckIfPhoneNumberIsOptedOut* = Call_PostCheckIfPhoneNumberIsOptedOut_601078(
    name: "postCheckIfPhoneNumberIsOptedOut", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CheckIfPhoneNumberIsOptedOut",
    validator: validate_PostCheckIfPhoneNumberIsOptedOut_601079, base: "/",
    url: url_PostCheckIfPhoneNumberIsOptedOut_601080,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCheckIfPhoneNumberIsOptedOut_601062 = ref object of OpenApiRestCall_600426
proc url_GetCheckIfPhoneNumberIsOptedOut_601064(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCheckIfPhoneNumberIsOptedOut_601063(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   phoneNumber: JString (required)
  ##              : The phone number for which you want to check the opt out status.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `phoneNumber` field"
  var valid_601065 = query.getOrDefault("phoneNumber")
  valid_601065 = validateParameter(valid_601065, JString, required = true,
                                 default = nil)
  if valid_601065 != nil:
    section.add "phoneNumber", valid_601065
  var valid_601066 = query.getOrDefault("Action")
  valid_601066 = validateParameter(valid_601066, JString, required = true, default = newJString(
      "CheckIfPhoneNumberIsOptedOut"))
  if valid_601066 != nil:
    section.add "Action", valid_601066
  var valid_601067 = query.getOrDefault("Version")
  valid_601067 = validateParameter(valid_601067, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601067 != nil:
    section.add "Version", valid_601067
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601068 = header.getOrDefault("X-Amz-Date")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "X-Amz-Date", valid_601068
  var valid_601069 = header.getOrDefault("X-Amz-Security-Token")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "X-Amz-Security-Token", valid_601069
  var valid_601070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Content-Sha256", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Algorithm")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Algorithm", valid_601071
  var valid_601072 = header.getOrDefault("X-Amz-Signature")
  valid_601072 = validateParameter(valid_601072, JString, required = false,
                                 default = nil)
  if valid_601072 != nil:
    section.add "X-Amz-Signature", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-SignedHeaders", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Credential")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Credential", valid_601074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601075: Call_GetCheckIfPhoneNumberIsOptedOut_601062;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ## 
  let valid = call_601075.validator(path, query, header, formData, body)
  let scheme = call_601075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601075.url(scheme.get, call_601075.host, call_601075.base,
                         call_601075.route, valid.getOrDefault("path"))
  result = hook(call_601075, url, valid)

proc call*(call_601076: Call_GetCheckIfPhoneNumberIsOptedOut_601062;
          phoneNumber: string; Action: string = "CheckIfPhoneNumberIsOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## getCheckIfPhoneNumberIsOptedOut
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number for which you want to check the opt out status.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601077 = newJObject()
  add(query_601077, "phoneNumber", newJString(phoneNumber))
  add(query_601077, "Action", newJString(Action))
  add(query_601077, "Version", newJString(Version))
  result = call_601076.call(nil, query_601077, nil, nil, nil)

var getCheckIfPhoneNumberIsOptedOut* = Call_GetCheckIfPhoneNumberIsOptedOut_601062(
    name: "getCheckIfPhoneNumberIsOptedOut", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CheckIfPhoneNumberIsOptedOut",
    validator: validate_GetCheckIfPhoneNumberIsOptedOut_601063, base: "/",
    url: url_GetCheckIfPhoneNumberIsOptedOut_601064,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostConfirmSubscription_601113 = ref object of OpenApiRestCall_600426
proc url_PostConfirmSubscription_601115(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostConfirmSubscription_601114(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601116 = query.getOrDefault("Action")
  valid_601116 = validateParameter(valid_601116, JString, required = true,
                                 default = newJString("ConfirmSubscription"))
  if valid_601116 != nil:
    section.add "Action", valid_601116
  var valid_601117 = query.getOrDefault("Version")
  valid_601117 = validateParameter(valid_601117, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601117 != nil:
    section.add "Version", valid_601117
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601118 = header.getOrDefault("X-Amz-Date")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Date", valid_601118
  var valid_601119 = header.getOrDefault("X-Amz-Security-Token")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Security-Token", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Content-Sha256", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-Algorithm")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-Algorithm", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Signature")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Signature", valid_601122
  var valid_601123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601123 = validateParameter(valid_601123, JString, required = false,
                                 default = nil)
  if valid_601123 != nil:
    section.add "X-Amz-SignedHeaders", valid_601123
  var valid_601124 = header.getOrDefault("X-Amz-Credential")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "X-Amz-Credential", valid_601124
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic for which you wish to confirm a subscription.
  ##   AuthenticateOnUnsubscribe: JString
  ##                            : Disallows unauthenticated unsubscribes of the subscription. If the value of this parameter is <code>true</code> and the request has an AWS signature, then only the topic owner and the subscription owner can unsubscribe the endpoint. The unsubscribe action requires AWS authentication. 
  ##   Token: JString (required)
  ##        : Short-lived token sent to an endpoint during the <code>Subscribe</code> action.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_601125 = formData.getOrDefault("TopicArn")
  valid_601125 = validateParameter(valid_601125, JString, required = true,
                                 default = nil)
  if valid_601125 != nil:
    section.add "TopicArn", valid_601125
  var valid_601126 = formData.getOrDefault("AuthenticateOnUnsubscribe")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "AuthenticateOnUnsubscribe", valid_601126
  var valid_601127 = formData.getOrDefault("Token")
  valid_601127 = validateParameter(valid_601127, JString, required = true,
                                 default = nil)
  if valid_601127 != nil:
    section.add "Token", valid_601127
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601128: Call_PostConfirmSubscription_601113; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  let valid = call_601128.validator(path, query, header, formData, body)
  let scheme = call_601128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601128.url(scheme.get, call_601128.host, call_601128.base,
                         call_601128.route, valid.getOrDefault("path"))
  result = hook(call_601128, url, valid)

proc call*(call_601129: Call_PostConfirmSubscription_601113; TopicArn: string;
          Token: string; AuthenticateOnUnsubscribe: string = "";
          Action: string = "ConfirmSubscription"; Version: string = "2010-03-31"): Recallable =
  ## postConfirmSubscription
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ##   TopicArn: string (required)
  ##           : The ARN of the topic for which you wish to confirm a subscription.
  ##   AuthenticateOnUnsubscribe: string
  ##                            : Disallows unauthenticated unsubscribes of the subscription. If the value of this parameter is <code>true</code> and the request has an AWS signature, then only the topic owner and the subscription owner can unsubscribe the endpoint. The unsubscribe action requires AWS authentication. 
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Token: string (required)
  ##        : Short-lived token sent to an endpoint during the <code>Subscribe</code> action.
  var query_601130 = newJObject()
  var formData_601131 = newJObject()
  add(formData_601131, "TopicArn", newJString(TopicArn))
  add(formData_601131, "AuthenticateOnUnsubscribe",
      newJString(AuthenticateOnUnsubscribe))
  add(query_601130, "Action", newJString(Action))
  add(query_601130, "Version", newJString(Version))
  add(formData_601131, "Token", newJString(Token))
  result = call_601129.call(nil, query_601130, nil, formData_601131, nil)

var postConfirmSubscription* = Call_PostConfirmSubscription_601113(
    name: "postConfirmSubscription", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ConfirmSubscription",
    validator: validate_PostConfirmSubscription_601114, base: "/",
    url: url_PostConfirmSubscription_601115, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfirmSubscription_601095 = ref object of OpenApiRestCall_600426
proc url_GetConfirmSubscription_601097(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetConfirmSubscription_601096(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Token: JString (required)
  ##        : Short-lived token sent to an endpoint during the <code>Subscribe</code> action.
  ##   Action: JString (required)
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic for which you wish to confirm a subscription.
  ##   AuthenticateOnUnsubscribe: JString
  ##                            : Disallows unauthenticated unsubscribes of the subscription. If the value of this parameter is <code>true</code> and the request has an AWS signature, then only the topic owner and the subscription owner can unsubscribe the endpoint. The unsubscribe action requires AWS authentication. 
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Token` field"
  var valid_601098 = query.getOrDefault("Token")
  valid_601098 = validateParameter(valid_601098, JString, required = true,
                                 default = nil)
  if valid_601098 != nil:
    section.add "Token", valid_601098
  var valid_601099 = query.getOrDefault("Action")
  valid_601099 = validateParameter(valid_601099, JString, required = true,
                                 default = newJString("ConfirmSubscription"))
  if valid_601099 != nil:
    section.add "Action", valid_601099
  var valid_601100 = query.getOrDefault("TopicArn")
  valid_601100 = validateParameter(valid_601100, JString, required = true,
                                 default = nil)
  if valid_601100 != nil:
    section.add "TopicArn", valid_601100
  var valid_601101 = query.getOrDefault("AuthenticateOnUnsubscribe")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "AuthenticateOnUnsubscribe", valid_601101
  var valid_601102 = query.getOrDefault("Version")
  valid_601102 = validateParameter(valid_601102, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601102 != nil:
    section.add "Version", valid_601102
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601103 = header.getOrDefault("X-Amz-Date")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Date", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Security-Token")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Security-Token", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Content-Sha256", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-Algorithm")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Algorithm", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Signature")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Signature", valid_601107
  var valid_601108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-SignedHeaders", valid_601108
  var valid_601109 = header.getOrDefault("X-Amz-Credential")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-Credential", valid_601109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601110: Call_GetConfirmSubscription_601095; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  let valid = call_601110.validator(path, query, header, formData, body)
  let scheme = call_601110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601110.url(scheme.get, call_601110.host, call_601110.base,
                         call_601110.route, valid.getOrDefault("path"))
  result = hook(call_601110, url, valid)

proc call*(call_601111: Call_GetConfirmSubscription_601095; Token: string;
          TopicArn: string; Action: string = "ConfirmSubscription";
          AuthenticateOnUnsubscribe: string = ""; Version: string = "2010-03-31"): Recallable =
  ## getConfirmSubscription
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ##   Token: string (required)
  ##        : Short-lived token sent to an endpoint during the <code>Subscribe</code> action.
  ##   Action: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic for which you wish to confirm a subscription.
  ##   AuthenticateOnUnsubscribe: string
  ##                            : Disallows unauthenticated unsubscribes of the subscription. If the value of this parameter is <code>true</code> and the request has an AWS signature, then only the topic owner and the subscription owner can unsubscribe the endpoint. The unsubscribe action requires AWS authentication. 
  ##   Version: string (required)
  var query_601112 = newJObject()
  add(query_601112, "Token", newJString(Token))
  add(query_601112, "Action", newJString(Action))
  add(query_601112, "TopicArn", newJString(TopicArn))
  add(query_601112, "AuthenticateOnUnsubscribe",
      newJString(AuthenticateOnUnsubscribe))
  add(query_601112, "Version", newJString(Version))
  result = call_601111.call(nil, query_601112, nil, nil, nil)

var getConfirmSubscription* = Call_GetConfirmSubscription_601095(
    name: "getConfirmSubscription", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ConfirmSubscription",
    validator: validate_GetConfirmSubscription_601096, base: "/",
    url: url_GetConfirmSubscription_601097, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformApplication_601155 = ref object of OpenApiRestCall_600426
proc url_PostCreatePlatformApplication_601157(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreatePlatformApplication_601156(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For GCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For GCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For more information about obtaining the PlatformPrincipal and PlatformCredential for each of the supported push notification services, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-apns.html">Getting Started with Apple Push Notification Service</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-adm.html">Getting Started with Amazon Device Messaging</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-baidu.html">Getting Started with Baidu Cloud Push</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-gcm.html">Getting Started with Google Cloud Messaging for Android</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-mpns.html">Getting Started with MPNS</a>, or <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-wns.html">Getting Started with WNS</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601158 = query.getOrDefault("Action")
  valid_601158 = validateParameter(valid_601158, JString, required = true, default = newJString(
      "CreatePlatformApplication"))
  if valid_601158 != nil:
    section.add "Action", valid_601158
  var valid_601159 = query.getOrDefault("Version")
  valid_601159 = validateParameter(valid_601159, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601159 != nil:
    section.add "Version", valid_601159
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601160 = header.getOrDefault("X-Amz-Date")
  valid_601160 = validateParameter(valid_601160, JString, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "X-Amz-Date", valid_601160
  var valid_601161 = header.getOrDefault("X-Amz-Security-Token")
  valid_601161 = validateParameter(valid_601161, JString, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "X-Amz-Security-Token", valid_601161
  var valid_601162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601162 = validateParameter(valid_601162, JString, required = false,
                                 default = nil)
  if valid_601162 != nil:
    section.add "X-Amz-Content-Sha256", valid_601162
  var valid_601163 = header.getOrDefault("X-Amz-Algorithm")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "X-Amz-Algorithm", valid_601163
  var valid_601164 = header.getOrDefault("X-Amz-Signature")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-Signature", valid_601164
  var valid_601165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-SignedHeaders", valid_601165
  var valid_601166 = header.getOrDefault("X-Amz-Credential")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-Credential", valid_601166
  result.add "header", section
  ## parameters in `formData` object:
  ##   Name: JString (required)
  ##       : Application names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, hyphens, and periods, and must be between 1 and 256 characters long.
  ##   Attributes.0.value: JString
  ##   Attributes.0.key: JString
  ##   Attributes.1.key: JString
  ##   Attributes.2.value: JString
  ##   Platform: JString (required)
  ##           : The following platforms are supported: ADM (Amazon Device Messaging), APNS (Apple Push Notification Service), APNS_SANDBOX, and GCM (Google Cloud Messaging).
  ##   Attributes.2.key: JString
  ##   Attributes.1.value: JString
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Name` field"
  var valid_601167 = formData.getOrDefault("Name")
  valid_601167 = validateParameter(valid_601167, JString, required = true,
                                 default = nil)
  if valid_601167 != nil:
    section.add "Name", valid_601167
  var valid_601168 = formData.getOrDefault("Attributes.0.value")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "Attributes.0.value", valid_601168
  var valid_601169 = formData.getOrDefault("Attributes.0.key")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "Attributes.0.key", valid_601169
  var valid_601170 = formData.getOrDefault("Attributes.1.key")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "Attributes.1.key", valid_601170
  var valid_601171 = formData.getOrDefault("Attributes.2.value")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "Attributes.2.value", valid_601171
  var valid_601172 = formData.getOrDefault("Platform")
  valid_601172 = validateParameter(valid_601172, JString, required = true,
                                 default = nil)
  if valid_601172 != nil:
    section.add "Platform", valid_601172
  var valid_601173 = formData.getOrDefault("Attributes.2.key")
  valid_601173 = validateParameter(valid_601173, JString, required = false,
                                 default = nil)
  if valid_601173 != nil:
    section.add "Attributes.2.key", valid_601173
  var valid_601174 = formData.getOrDefault("Attributes.1.value")
  valid_601174 = validateParameter(valid_601174, JString, required = false,
                                 default = nil)
  if valid_601174 != nil:
    section.add "Attributes.1.value", valid_601174
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601175: Call_PostCreatePlatformApplication_601155; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For GCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For GCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For more information about obtaining the PlatformPrincipal and PlatformCredential for each of the supported push notification services, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-apns.html">Getting Started with Apple Push Notification Service</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-adm.html">Getting Started with Amazon Device Messaging</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-baidu.html">Getting Started with Baidu Cloud Push</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-gcm.html">Getting Started with Google Cloud Messaging for Android</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-mpns.html">Getting Started with MPNS</a>, or <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-wns.html">Getting Started with WNS</a>. </p>
  ## 
  let valid = call_601175.validator(path, query, header, formData, body)
  let scheme = call_601175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601175.url(scheme.get, call_601175.host, call_601175.base,
                         call_601175.route, valid.getOrDefault("path"))
  result = hook(call_601175, url, valid)

proc call*(call_601176: Call_PostCreatePlatformApplication_601155; Name: string;
          Platform: string; Attributes0Value: string = "";
          Attributes0Key: string = ""; Attributes1Key: string = "";
          Action: string = "CreatePlatformApplication";
          Attributes2Value: string = ""; Attributes2Key: string = "";
          Version: string = "2010-03-31"; Attributes1Value: string = ""): Recallable =
  ## postCreatePlatformApplication
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For GCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For GCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For more information about obtaining the PlatformPrincipal and PlatformCredential for each of the supported push notification services, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-apns.html">Getting Started with Apple Push Notification Service</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-adm.html">Getting Started with Amazon Device Messaging</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-baidu.html">Getting Started with Baidu Cloud Push</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-gcm.html">Getting Started with Google Cloud Messaging for Android</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-mpns.html">Getting Started with MPNS</a>, or <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-wns.html">Getting Started with WNS</a>. </p>
  ##   Name: string (required)
  ##       : Application names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, hyphens, and periods, and must be between 1 and 256 characters long.
  ##   Attributes0Value: string
  ##   Attributes0Key: string
  ##   Attributes1Key: string
  ##   Action: string (required)
  ##   Attributes2Value: string
  ##   Platform: string (required)
  ##           : The following platforms are supported: ADM (Amazon Device Messaging), APNS (Apple Push Notification Service), APNS_SANDBOX, and GCM (Google Cloud Messaging).
  ##   Attributes2Key: string
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_601177 = newJObject()
  var formData_601178 = newJObject()
  add(formData_601178, "Name", newJString(Name))
  add(formData_601178, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_601178, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_601178, "Attributes.1.key", newJString(Attributes1Key))
  add(query_601177, "Action", newJString(Action))
  add(formData_601178, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_601178, "Platform", newJString(Platform))
  add(formData_601178, "Attributes.2.key", newJString(Attributes2Key))
  add(query_601177, "Version", newJString(Version))
  add(formData_601178, "Attributes.1.value", newJString(Attributes1Value))
  result = call_601176.call(nil, query_601177, nil, formData_601178, nil)

var postCreatePlatformApplication* = Call_PostCreatePlatformApplication_601155(
    name: "postCreatePlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformApplication",
    validator: validate_PostCreatePlatformApplication_601156, base: "/",
    url: url_PostCreatePlatformApplication_601157,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformApplication_601132 = ref object of OpenApiRestCall_600426
proc url_GetCreatePlatformApplication_601134(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreatePlatformApplication_601133(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For GCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For GCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For more information about obtaining the PlatformPrincipal and PlatformCredential for each of the supported push notification services, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-apns.html">Getting Started with Apple Push Notification Service</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-adm.html">Getting Started with Amazon Device Messaging</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-baidu.html">Getting Started with Baidu Cloud Push</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-gcm.html">Getting Started with Google Cloud Messaging for Android</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-mpns.html">Getting Started with MPNS</a>, or <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-wns.html">Getting Started with WNS</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes.2.key: JString
  ##   Name: JString (required)
  ##       : Application names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, hyphens, and periods, and must be between 1 and 256 characters long.
  ##   Attributes.1.value: JString
  ##   Attributes.0.value: JString
  ##   Action: JString (required)
  ##   Attributes.1.key: JString
  ##   Platform: JString (required)
  ##           : The following platforms are supported: ADM (Amazon Device Messaging), APNS (Apple Push Notification Service), APNS_SANDBOX, and GCM (Google Cloud Messaging).
  ##   Attributes.2.value: JString
  ##   Attributes.0.key: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_601135 = query.getOrDefault("Attributes.2.key")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "Attributes.2.key", valid_601135
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_601136 = query.getOrDefault("Name")
  valid_601136 = validateParameter(valid_601136, JString, required = true,
                                 default = nil)
  if valid_601136 != nil:
    section.add "Name", valid_601136
  var valid_601137 = query.getOrDefault("Attributes.1.value")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "Attributes.1.value", valid_601137
  var valid_601138 = query.getOrDefault("Attributes.0.value")
  valid_601138 = validateParameter(valid_601138, JString, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "Attributes.0.value", valid_601138
  var valid_601139 = query.getOrDefault("Action")
  valid_601139 = validateParameter(valid_601139, JString, required = true, default = newJString(
      "CreatePlatformApplication"))
  if valid_601139 != nil:
    section.add "Action", valid_601139
  var valid_601140 = query.getOrDefault("Attributes.1.key")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "Attributes.1.key", valid_601140
  var valid_601141 = query.getOrDefault("Platform")
  valid_601141 = validateParameter(valid_601141, JString, required = true,
                                 default = nil)
  if valid_601141 != nil:
    section.add "Platform", valid_601141
  var valid_601142 = query.getOrDefault("Attributes.2.value")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "Attributes.2.value", valid_601142
  var valid_601143 = query.getOrDefault("Attributes.0.key")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "Attributes.0.key", valid_601143
  var valid_601144 = query.getOrDefault("Version")
  valid_601144 = validateParameter(valid_601144, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601144 != nil:
    section.add "Version", valid_601144
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601145 = header.getOrDefault("X-Amz-Date")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "X-Amz-Date", valid_601145
  var valid_601146 = header.getOrDefault("X-Amz-Security-Token")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-Security-Token", valid_601146
  var valid_601147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = nil)
  if valid_601147 != nil:
    section.add "X-Amz-Content-Sha256", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Algorithm")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Algorithm", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-Signature")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-Signature", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-SignedHeaders", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-Credential")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-Credential", valid_601151
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601152: Call_GetCreatePlatformApplication_601132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For GCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For GCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For more information about obtaining the PlatformPrincipal and PlatformCredential for each of the supported push notification services, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-apns.html">Getting Started with Apple Push Notification Service</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-adm.html">Getting Started with Amazon Device Messaging</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-baidu.html">Getting Started with Baidu Cloud Push</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-gcm.html">Getting Started with Google Cloud Messaging for Android</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-mpns.html">Getting Started with MPNS</a>, or <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-wns.html">Getting Started with WNS</a>. </p>
  ## 
  let valid = call_601152.validator(path, query, header, formData, body)
  let scheme = call_601152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601152.url(scheme.get, call_601152.host, call_601152.base,
                         call_601152.route, valid.getOrDefault("path"))
  result = hook(call_601152, url, valid)

proc call*(call_601153: Call_GetCreatePlatformApplication_601132; Name: string;
          Platform: string; Attributes2Key: string = "";
          Attributes1Value: string = ""; Attributes0Value: string = "";
          Action: string = "CreatePlatformApplication"; Attributes1Key: string = "";
          Attributes2Value: string = ""; Attributes0Key: string = "";
          Version: string = "2010-03-31"): Recallable =
  ## getCreatePlatformApplication
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For GCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For GCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For more information about obtaining the PlatformPrincipal and PlatformCredential for each of the supported push notification services, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-apns.html">Getting Started with Apple Push Notification Service</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-adm.html">Getting Started with Amazon Device Messaging</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-baidu.html">Getting Started with Baidu Cloud Push</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-gcm.html">Getting Started with Google Cloud Messaging for Android</a>, <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-mpns.html">Getting Started with MPNS</a>, or <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-wns.html">Getting Started with WNS</a>. </p>
  ##   Attributes2Key: string
  ##   Name: string (required)
  ##       : Application names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, hyphens, and periods, and must be between 1 and 256 characters long.
  ##   Attributes1Value: string
  ##   Attributes0Value: string
  ##   Action: string (required)
  ##   Attributes1Key: string
  ##   Platform: string (required)
  ##           : The following platforms are supported: ADM (Amazon Device Messaging), APNS (Apple Push Notification Service), APNS_SANDBOX, and GCM (Google Cloud Messaging).
  ##   Attributes2Value: string
  ##   Attributes0Key: string
  ##   Version: string (required)
  var query_601154 = newJObject()
  add(query_601154, "Attributes.2.key", newJString(Attributes2Key))
  add(query_601154, "Name", newJString(Name))
  add(query_601154, "Attributes.1.value", newJString(Attributes1Value))
  add(query_601154, "Attributes.0.value", newJString(Attributes0Value))
  add(query_601154, "Action", newJString(Action))
  add(query_601154, "Attributes.1.key", newJString(Attributes1Key))
  add(query_601154, "Platform", newJString(Platform))
  add(query_601154, "Attributes.2.value", newJString(Attributes2Value))
  add(query_601154, "Attributes.0.key", newJString(Attributes0Key))
  add(query_601154, "Version", newJString(Version))
  result = call_601153.call(nil, query_601154, nil, nil, nil)

var getCreatePlatformApplication* = Call_GetCreatePlatformApplication_601132(
    name: "getCreatePlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformApplication",
    validator: validate_GetCreatePlatformApplication_601133, base: "/",
    url: url_GetCreatePlatformApplication_601134,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformEndpoint_601203 = ref object of OpenApiRestCall_600426
proc url_PostCreatePlatformEndpoint_601205(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreatePlatformEndpoint_601204(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as GCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601206 = query.getOrDefault("Action")
  valid_601206 = validateParameter(valid_601206, JString, required = true,
                                 default = newJString("CreatePlatformEndpoint"))
  if valid_601206 != nil:
    section.add "Action", valid_601206
  var valid_601207 = query.getOrDefault("Version")
  valid_601207 = validateParameter(valid_601207, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601207 != nil:
    section.add "Version", valid_601207
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601208 = header.getOrDefault("X-Amz-Date")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "X-Amz-Date", valid_601208
  var valid_601209 = header.getOrDefault("X-Amz-Security-Token")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-Security-Token", valid_601209
  var valid_601210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "X-Amz-Content-Sha256", valid_601210
  var valid_601211 = header.getOrDefault("X-Amz-Algorithm")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "X-Amz-Algorithm", valid_601211
  var valid_601212 = header.getOrDefault("X-Amz-Signature")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Signature", valid_601212
  var valid_601213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601213 = validateParameter(valid_601213, JString, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "X-Amz-SignedHeaders", valid_601213
  var valid_601214 = header.getOrDefault("X-Amz-Credential")
  valid_601214 = validateParameter(valid_601214, JString, required = false,
                                 default = nil)
  if valid_601214 != nil:
    section.add "X-Amz-Credential", valid_601214
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes.0.value: JString
  ##   Attributes.0.key: JString
  ##   Attributes.1.key: JString
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn returned from CreatePlatformApplication is used to create a an endpoint.
  ##   CustomUserData: JString
  ##                 : Arbitrary user data to associate with the endpoint. Amazon SNS does not use this data. The data must be in UTF-8 format and less than 2KB.
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   Attributes.1.value: JString
  ##   Token: JString (required)
  ##        : Unique identifier created by the notification service for an app on a device. The specific name for Token will vary, depending on which notification service is being used. For example, when using APNS as the notification service, you need the device token. Alternatively, when using GCM or ADM, the device token equivalent is called the registration ID.
  section = newJObject()
  var valid_601215 = formData.getOrDefault("Attributes.0.value")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "Attributes.0.value", valid_601215
  var valid_601216 = formData.getOrDefault("Attributes.0.key")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "Attributes.0.key", valid_601216
  var valid_601217 = formData.getOrDefault("Attributes.1.key")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "Attributes.1.key", valid_601217
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_601218 = formData.getOrDefault("PlatformApplicationArn")
  valid_601218 = validateParameter(valid_601218, JString, required = true,
                                 default = nil)
  if valid_601218 != nil:
    section.add "PlatformApplicationArn", valid_601218
  var valid_601219 = formData.getOrDefault("CustomUserData")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "CustomUserData", valid_601219
  var valid_601220 = formData.getOrDefault("Attributes.2.value")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "Attributes.2.value", valid_601220
  var valid_601221 = formData.getOrDefault("Attributes.2.key")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "Attributes.2.key", valid_601221
  var valid_601222 = formData.getOrDefault("Attributes.1.value")
  valid_601222 = validateParameter(valid_601222, JString, required = false,
                                 default = nil)
  if valid_601222 != nil:
    section.add "Attributes.1.value", valid_601222
  var valid_601223 = formData.getOrDefault("Token")
  valid_601223 = validateParameter(valid_601223, JString, required = true,
                                 default = nil)
  if valid_601223 != nil:
    section.add "Token", valid_601223
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601224: Call_PostCreatePlatformEndpoint_601203; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as GCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  let valid = call_601224.validator(path, query, header, formData, body)
  let scheme = call_601224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601224.url(scheme.get, call_601224.host, call_601224.base,
                         call_601224.route, valid.getOrDefault("path"))
  result = hook(call_601224, url, valid)

proc call*(call_601225: Call_PostCreatePlatformEndpoint_601203;
          PlatformApplicationArn: string; Token: string;
          Attributes0Value: string = ""; Attributes0Key: string = "";
          Attributes1Key: string = ""; Action: string = "CreatePlatformEndpoint";
          CustomUserData: string = ""; Attributes2Value: string = "";
          Attributes2Key: string = ""; Version: string = "2010-03-31";
          Attributes1Value: string = ""): Recallable =
  ## postCreatePlatformEndpoint
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as GCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ##   Attributes0Value: string
  ##   Attributes0Key: string
  ##   Attributes1Key: string
  ##   Action: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn returned from CreatePlatformApplication is used to create a an endpoint.
  ##   CustomUserData: string
  ##                 : Arbitrary user data to associate with the endpoint. Amazon SNS does not use this data. The data must be in UTF-8 format and less than 2KB.
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   Version: string (required)
  ##   Attributes1Value: string
  ##   Token: string (required)
  ##        : Unique identifier created by the notification service for an app on a device. The specific name for Token will vary, depending on which notification service is being used. For example, when using APNS as the notification service, you need the device token. Alternatively, when using GCM or ADM, the device token equivalent is called the registration ID.
  var query_601226 = newJObject()
  var formData_601227 = newJObject()
  add(formData_601227, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_601227, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_601227, "Attributes.1.key", newJString(Attributes1Key))
  add(query_601226, "Action", newJString(Action))
  add(formData_601227, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(formData_601227, "CustomUserData", newJString(CustomUserData))
  add(formData_601227, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_601227, "Attributes.2.key", newJString(Attributes2Key))
  add(query_601226, "Version", newJString(Version))
  add(formData_601227, "Attributes.1.value", newJString(Attributes1Value))
  add(formData_601227, "Token", newJString(Token))
  result = call_601225.call(nil, query_601226, nil, formData_601227, nil)

var postCreatePlatformEndpoint* = Call_PostCreatePlatformEndpoint_601203(
    name: "postCreatePlatformEndpoint", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformEndpoint",
    validator: validate_PostCreatePlatformEndpoint_601204, base: "/",
    url: url_PostCreatePlatformEndpoint_601205,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformEndpoint_601179 = ref object of OpenApiRestCall_600426
proc url_GetCreatePlatformEndpoint_601181(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreatePlatformEndpoint_601180(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as GCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   CustomUserData: JString
  ##                 : Arbitrary user data to associate with the endpoint. Amazon SNS does not use this data. The data must be in UTF-8 format and less than 2KB.
  ##   Attributes.2.key: JString
  ##   Token: JString (required)
  ##        : Unique identifier created by the notification service for an app on a device. The specific name for Token will vary, depending on which notification service is being used. For example, when using APNS as the notification service, you need the device token. Alternatively, when using GCM or ADM, the device token equivalent is called the registration ID.
  ##   Attributes.1.value: JString
  ##   Attributes.0.value: JString
  ##   Action: JString (required)
  ##   Attributes.1.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.0.key: JString
  ##   Version: JString (required)
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn returned from CreatePlatformApplication is used to create a an endpoint.
  section = newJObject()
  var valid_601182 = query.getOrDefault("CustomUserData")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "CustomUserData", valid_601182
  var valid_601183 = query.getOrDefault("Attributes.2.key")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "Attributes.2.key", valid_601183
  assert query != nil, "query argument is necessary due to required `Token` field"
  var valid_601184 = query.getOrDefault("Token")
  valid_601184 = validateParameter(valid_601184, JString, required = true,
                                 default = nil)
  if valid_601184 != nil:
    section.add "Token", valid_601184
  var valid_601185 = query.getOrDefault("Attributes.1.value")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "Attributes.1.value", valid_601185
  var valid_601186 = query.getOrDefault("Attributes.0.value")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "Attributes.0.value", valid_601186
  var valid_601187 = query.getOrDefault("Action")
  valid_601187 = validateParameter(valid_601187, JString, required = true,
                                 default = newJString("CreatePlatformEndpoint"))
  if valid_601187 != nil:
    section.add "Action", valid_601187
  var valid_601188 = query.getOrDefault("Attributes.1.key")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "Attributes.1.key", valid_601188
  var valid_601189 = query.getOrDefault("Attributes.2.value")
  valid_601189 = validateParameter(valid_601189, JString, required = false,
                                 default = nil)
  if valid_601189 != nil:
    section.add "Attributes.2.value", valid_601189
  var valid_601190 = query.getOrDefault("Attributes.0.key")
  valid_601190 = validateParameter(valid_601190, JString, required = false,
                                 default = nil)
  if valid_601190 != nil:
    section.add "Attributes.0.key", valid_601190
  var valid_601191 = query.getOrDefault("Version")
  valid_601191 = validateParameter(valid_601191, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601191 != nil:
    section.add "Version", valid_601191
  var valid_601192 = query.getOrDefault("PlatformApplicationArn")
  valid_601192 = validateParameter(valid_601192, JString, required = true,
                                 default = nil)
  if valid_601192 != nil:
    section.add "PlatformApplicationArn", valid_601192
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601193 = header.getOrDefault("X-Amz-Date")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "X-Amz-Date", valid_601193
  var valid_601194 = header.getOrDefault("X-Amz-Security-Token")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "X-Amz-Security-Token", valid_601194
  var valid_601195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "X-Amz-Content-Sha256", valid_601195
  var valid_601196 = header.getOrDefault("X-Amz-Algorithm")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-Algorithm", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Signature")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Signature", valid_601197
  var valid_601198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "X-Amz-SignedHeaders", valid_601198
  var valid_601199 = header.getOrDefault("X-Amz-Credential")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "X-Amz-Credential", valid_601199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601200: Call_GetCreatePlatformEndpoint_601179; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as GCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  let valid = call_601200.validator(path, query, header, formData, body)
  let scheme = call_601200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601200.url(scheme.get, call_601200.host, call_601200.base,
                         call_601200.route, valid.getOrDefault("path"))
  result = hook(call_601200, url, valid)

proc call*(call_601201: Call_GetCreatePlatformEndpoint_601179; Token: string;
          PlatformApplicationArn: string; CustomUserData: string = "";
          Attributes2Key: string = ""; Attributes1Value: string = "";
          Attributes0Value: string = ""; Action: string = "CreatePlatformEndpoint";
          Attributes1Key: string = ""; Attributes2Value: string = "";
          Attributes0Key: string = ""; Version: string = "2010-03-31"): Recallable =
  ## getCreatePlatformEndpoint
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as GCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ##   CustomUserData: string
  ##                 : Arbitrary user data to associate with the endpoint. Amazon SNS does not use this data. The data must be in UTF-8 format and less than 2KB.
  ##   Attributes2Key: string
  ##   Token: string (required)
  ##        : Unique identifier created by the notification service for an app on a device. The specific name for Token will vary, depending on which notification service is being used. For example, when using APNS as the notification service, you need the device token. Alternatively, when using GCM or ADM, the device token equivalent is called the registration ID.
  ##   Attributes1Value: string
  ##   Attributes0Value: string
  ##   Action: string (required)
  ##   Attributes1Key: string
  ##   Attributes2Value: string
  ##   Attributes0Key: string
  ##   Version: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn returned from CreatePlatformApplication is used to create a an endpoint.
  var query_601202 = newJObject()
  add(query_601202, "CustomUserData", newJString(CustomUserData))
  add(query_601202, "Attributes.2.key", newJString(Attributes2Key))
  add(query_601202, "Token", newJString(Token))
  add(query_601202, "Attributes.1.value", newJString(Attributes1Value))
  add(query_601202, "Attributes.0.value", newJString(Attributes0Value))
  add(query_601202, "Action", newJString(Action))
  add(query_601202, "Attributes.1.key", newJString(Attributes1Key))
  add(query_601202, "Attributes.2.value", newJString(Attributes2Value))
  add(query_601202, "Attributes.0.key", newJString(Attributes0Key))
  add(query_601202, "Version", newJString(Version))
  add(query_601202, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_601201.call(nil, query_601202, nil, nil, nil)

var getCreatePlatformEndpoint* = Call_GetCreatePlatformEndpoint_601179(
    name: "getCreatePlatformEndpoint", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformEndpoint",
    validator: validate_GetCreatePlatformEndpoint_601180, base: "/",
    url: url_GetCreatePlatformEndpoint_601181,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateTopic_601251 = ref object of OpenApiRestCall_600426
proc url_PostCreateTopic_601253(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateTopic_601252(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601254 = query.getOrDefault("Action")
  valid_601254 = validateParameter(valid_601254, JString, required = true,
                                 default = newJString("CreateTopic"))
  if valid_601254 != nil:
    section.add "Action", valid_601254
  var valid_601255 = query.getOrDefault("Version")
  valid_601255 = validateParameter(valid_601255, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601255 != nil:
    section.add "Version", valid_601255
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601256 = header.getOrDefault("X-Amz-Date")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "X-Amz-Date", valid_601256
  var valid_601257 = header.getOrDefault("X-Amz-Security-Token")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-Security-Token", valid_601257
  var valid_601258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601258 = validateParameter(valid_601258, JString, required = false,
                                 default = nil)
  if valid_601258 != nil:
    section.add "X-Amz-Content-Sha256", valid_601258
  var valid_601259 = header.getOrDefault("X-Amz-Algorithm")
  valid_601259 = validateParameter(valid_601259, JString, required = false,
                                 default = nil)
  if valid_601259 != nil:
    section.add "X-Amz-Algorithm", valid_601259
  var valid_601260 = header.getOrDefault("X-Amz-Signature")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "X-Amz-Signature", valid_601260
  var valid_601261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "X-Amz-SignedHeaders", valid_601261
  var valid_601262 = header.getOrDefault("X-Amz-Credential")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "X-Amz-Credential", valid_601262
  result.add "header", section
  ## parameters in `formData` object:
  ##   Name: JString (required)
  ##       : <p>The name of the topic you want to create.</p> <p>Constraints: Topic names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, and hyphens, and must be between 1 and 256 characters long.</p>
  ##   Attributes.0.value: JString
  ##   Attributes.0.key: JString
  ##   Tags: JArray
  ##       : The list of tags to add to a new topic.
  ##   Attributes.1.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   Attributes.1.value: JString
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Name` field"
  var valid_601263 = formData.getOrDefault("Name")
  valid_601263 = validateParameter(valid_601263, JString, required = true,
                                 default = nil)
  if valid_601263 != nil:
    section.add "Name", valid_601263
  var valid_601264 = formData.getOrDefault("Attributes.0.value")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "Attributes.0.value", valid_601264
  var valid_601265 = formData.getOrDefault("Attributes.0.key")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "Attributes.0.key", valid_601265
  var valid_601266 = formData.getOrDefault("Tags")
  valid_601266 = validateParameter(valid_601266, JArray, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "Tags", valid_601266
  var valid_601267 = formData.getOrDefault("Attributes.1.key")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "Attributes.1.key", valid_601267
  var valid_601268 = formData.getOrDefault("Attributes.2.value")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "Attributes.2.value", valid_601268
  var valid_601269 = formData.getOrDefault("Attributes.2.key")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "Attributes.2.key", valid_601269
  var valid_601270 = formData.getOrDefault("Attributes.1.value")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "Attributes.1.value", valid_601270
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601271: Call_PostCreateTopic_601251; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  let valid = call_601271.validator(path, query, header, formData, body)
  let scheme = call_601271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601271.url(scheme.get, call_601271.host, call_601271.base,
                         call_601271.route, valid.getOrDefault("path"))
  result = hook(call_601271, url, valid)

proc call*(call_601272: Call_PostCreateTopic_601251; Name: string;
          Attributes0Value: string = ""; Attributes0Key: string = "";
          Tags: JsonNode = nil; Attributes1Key: string = "";
          Action: string = "CreateTopic"; Attributes2Value: string = "";
          Attributes2Key: string = ""; Version: string = "2010-03-31";
          Attributes1Value: string = ""): Recallable =
  ## postCreateTopic
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ##   Name: string (required)
  ##       : <p>The name of the topic you want to create.</p> <p>Constraints: Topic names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, and hyphens, and must be between 1 and 256 characters long.</p>
  ##   Attributes0Value: string
  ##   Attributes0Key: string
  ##   Tags: JArray
  ##       : The list of tags to add to a new topic.
  ##   Attributes1Key: string
  ##   Action: string (required)
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_601273 = newJObject()
  var formData_601274 = newJObject()
  add(formData_601274, "Name", newJString(Name))
  add(formData_601274, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_601274, "Attributes.0.key", newJString(Attributes0Key))
  if Tags != nil:
    formData_601274.add "Tags", Tags
  add(formData_601274, "Attributes.1.key", newJString(Attributes1Key))
  add(query_601273, "Action", newJString(Action))
  add(formData_601274, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_601274, "Attributes.2.key", newJString(Attributes2Key))
  add(query_601273, "Version", newJString(Version))
  add(formData_601274, "Attributes.1.value", newJString(Attributes1Value))
  result = call_601272.call(nil, query_601273, nil, formData_601274, nil)

var postCreateTopic* = Call_PostCreateTopic_601251(name: "postCreateTopic",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=CreateTopic", validator: validate_PostCreateTopic_601252,
    base: "/", url: url_PostCreateTopic_601253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateTopic_601228 = ref object of OpenApiRestCall_600426
proc url_GetCreateTopic_601230(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateTopic_601229(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes.2.key: JString
  ##   Name: JString (required)
  ##       : <p>The name of the topic you want to create.</p> <p>Constraints: Topic names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, and hyphens, and must be between 1 and 256 characters long.</p>
  ##   Attributes.1.value: JString
  ##   Tags: JArray
  ##       : The list of tags to add to a new topic.
  ##   Attributes.0.value: JString
  ##   Action: JString (required)
  ##   Attributes.1.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.0.key: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_601231 = query.getOrDefault("Attributes.2.key")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "Attributes.2.key", valid_601231
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_601232 = query.getOrDefault("Name")
  valid_601232 = validateParameter(valid_601232, JString, required = true,
                                 default = nil)
  if valid_601232 != nil:
    section.add "Name", valid_601232
  var valid_601233 = query.getOrDefault("Attributes.1.value")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "Attributes.1.value", valid_601233
  var valid_601234 = query.getOrDefault("Tags")
  valid_601234 = validateParameter(valid_601234, JArray, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "Tags", valid_601234
  var valid_601235 = query.getOrDefault("Attributes.0.value")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "Attributes.0.value", valid_601235
  var valid_601236 = query.getOrDefault("Action")
  valid_601236 = validateParameter(valid_601236, JString, required = true,
                                 default = newJString("CreateTopic"))
  if valid_601236 != nil:
    section.add "Action", valid_601236
  var valid_601237 = query.getOrDefault("Attributes.1.key")
  valid_601237 = validateParameter(valid_601237, JString, required = false,
                                 default = nil)
  if valid_601237 != nil:
    section.add "Attributes.1.key", valid_601237
  var valid_601238 = query.getOrDefault("Attributes.2.value")
  valid_601238 = validateParameter(valid_601238, JString, required = false,
                                 default = nil)
  if valid_601238 != nil:
    section.add "Attributes.2.value", valid_601238
  var valid_601239 = query.getOrDefault("Attributes.0.key")
  valid_601239 = validateParameter(valid_601239, JString, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "Attributes.0.key", valid_601239
  var valid_601240 = query.getOrDefault("Version")
  valid_601240 = validateParameter(valid_601240, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601240 != nil:
    section.add "Version", valid_601240
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601241 = header.getOrDefault("X-Amz-Date")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "X-Amz-Date", valid_601241
  var valid_601242 = header.getOrDefault("X-Amz-Security-Token")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amz-Security-Token", valid_601242
  var valid_601243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601243 = validateParameter(valid_601243, JString, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "X-Amz-Content-Sha256", valid_601243
  var valid_601244 = header.getOrDefault("X-Amz-Algorithm")
  valid_601244 = validateParameter(valid_601244, JString, required = false,
                                 default = nil)
  if valid_601244 != nil:
    section.add "X-Amz-Algorithm", valid_601244
  var valid_601245 = header.getOrDefault("X-Amz-Signature")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "X-Amz-Signature", valid_601245
  var valid_601246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "X-Amz-SignedHeaders", valid_601246
  var valid_601247 = header.getOrDefault("X-Amz-Credential")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-Credential", valid_601247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601248: Call_GetCreateTopic_601228; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  let valid = call_601248.validator(path, query, header, formData, body)
  let scheme = call_601248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601248.url(scheme.get, call_601248.host, call_601248.base,
                         call_601248.route, valid.getOrDefault("path"))
  result = hook(call_601248, url, valid)

proc call*(call_601249: Call_GetCreateTopic_601228; Name: string;
          Attributes2Key: string = ""; Attributes1Value: string = "";
          Tags: JsonNode = nil; Attributes0Value: string = "";
          Action: string = "CreateTopic"; Attributes1Key: string = "";
          Attributes2Value: string = ""; Attributes0Key: string = "";
          Version: string = "2010-03-31"): Recallable =
  ## getCreateTopic
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ##   Attributes2Key: string
  ##   Name: string (required)
  ##       : <p>The name of the topic you want to create.</p> <p>Constraints: Topic names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, and hyphens, and must be between 1 and 256 characters long.</p>
  ##   Attributes1Value: string
  ##   Tags: JArray
  ##       : The list of tags to add to a new topic.
  ##   Attributes0Value: string
  ##   Action: string (required)
  ##   Attributes1Key: string
  ##   Attributes2Value: string
  ##   Attributes0Key: string
  ##   Version: string (required)
  var query_601250 = newJObject()
  add(query_601250, "Attributes.2.key", newJString(Attributes2Key))
  add(query_601250, "Name", newJString(Name))
  add(query_601250, "Attributes.1.value", newJString(Attributes1Value))
  if Tags != nil:
    query_601250.add "Tags", Tags
  add(query_601250, "Attributes.0.value", newJString(Attributes0Value))
  add(query_601250, "Action", newJString(Action))
  add(query_601250, "Attributes.1.key", newJString(Attributes1Key))
  add(query_601250, "Attributes.2.value", newJString(Attributes2Value))
  add(query_601250, "Attributes.0.key", newJString(Attributes0Key))
  add(query_601250, "Version", newJString(Version))
  result = call_601249.call(nil, query_601250, nil, nil, nil)

var getCreateTopic* = Call_GetCreateTopic_601228(name: "getCreateTopic",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=CreateTopic", validator: validate_GetCreateTopic_601229,
    base: "/", url: url_GetCreateTopic_601230, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEndpoint_601291 = ref object of OpenApiRestCall_600426
proc url_PostDeleteEndpoint_601293(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteEndpoint_601292(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601294 = query.getOrDefault("Action")
  valid_601294 = validateParameter(valid_601294, JString, required = true,
                                 default = newJString("DeleteEndpoint"))
  if valid_601294 != nil:
    section.add "Action", valid_601294
  var valid_601295 = query.getOrDefault("Version")
  valid_601295 = validateParameter(valid_601295, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601295 != nil:
    section.add "Version", valid_601295
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601296 = header.getOrDefault("X-Amz-Date")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "X-Amz-Date", valid_601296
  var valid_601297 = header.getOrDefault("X-Amz-Security-Token")
  valid_601297 = validateParameter(valid_601297, JString, required = false,
                                 default = nil)
  if valid_601297 != nil:
    section.add "X-Amz-Security-Token", valid_601297
  var valid_601298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601298 = validateParameter(valid_601298, JString, required = false,
                                 default = nil)
  if valid_601298 != nil:
    section.add "X-Amz-Content-Sha256", valid_601298
  var valid_601299 = header.getOrDefault("X-Amz-Algorithm")
  valid_601299 = validateParameter(valid_601299, JString, required = false,
                                 default = nil)
  if valid_601299 != nil:
    section.add "X-Amz-Algorithm", valid_601299
  var valid_601300 = header.getOrDefault("X-Amz-Signature")
  valid_601300 = validateParameter(valid_601300, JString, required = false,
                                 default = nil)
  if valid_601300 != nil:
    section.add "X-Amz-Signature", valid_601300
  var valid_601301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601301 = validateParameter(valid_601301, JString, required = false,
                                 default = nil)
  if valid_601301 != nil:
    section.add "X-Amz-SignedHeaders", valid_601301
  var valid_601302 = header.getOrDefault("X-Amz-Credential")
  valid_601302 = validateParameter(valid_601302, JString, required = false,
                                 default = nil)
  if valid_601302 != nil:
    section.add "X-Amz-Credential", valid_601302
  result.add "header", section
  ## parameters in `formData` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn of endpoint to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_601303 = formData.getOrDefault("EndpointArn")
  valid_601303 = validateParameter(valid_601303, JString, required = true,
                                 default = nil)
  if valid_601303 != nil:
    section.add "EndpointArn", valid_601303
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601304: Call_PostDeleteEndpoint_601291; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ## 
  let valid = call_601304.validator(path, query, header, formData, body)
  let scheme = call_601304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601304.url(scheme.get, call_601304.host, call_601304.base,
                         call_601304.route, valid.getOrDefault("path"))
  result = hook(call_601304, url, valid)

proc call*(call_601305: Call_PostDeleteEndpoint_601291; EndpointArn: string;
          Action: string = "DeleteEndpoint"; Version: string = "2010-03-31"): Recallable =
  ## postDeleteEndpoint
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ##   Action: string (required)
  ##   EndpointArn: string (required)
  ##              : EndpointArn of endpoint to delete.
  ##   Version: string (required)
  var query_601306 = newJObject()
  var formData_601307 = newJObject()
  add(query_601306, "Action", newJString(Action))
  add(formData_601307, "EndpointArn", newJString(EndpointArn))
  add(query_601306, "Version", newJString(Version))
  result = call_601305.call(nil, query_601306, nil, formData_601307, nil)

var postDeleteEndpoint* = Call_PostDeleteEndpoint_601291(
    name: "postDeleteEndpoint", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=DeleteEndpoint",
    validator: validate_PostDeleteEndpoint_601292, base: "/",
    url: url_PostDeleteEndpoint_601293, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEndpoint_601275 = ref object of OpenApiRestCall_600426
proc url_GetDeleteEndpoint_601277(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteEndpoint_601276(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn of endpoint to delete.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `EndpointArn` field"
  var valid_601278 = query.getOrDefault("EndpointArn")
  valid_601278 = validateParameter(valid_601278, JString, required = true,
                                 default = nil)
  if valid_601278 != nil:
    section.add "EndpointArn", valid_601278
  var valid_601279 = query.getOrDefault("Action")
  valid_601279 = validateParameter(valid_601279, JString, required = true,
                                 default = newJString("DeleteEndpoint"))
  if valid_601279 != nil:
    section.add "Action", valid_601279
  var valid_601280 = query.getOrDefault("Version")
  valid_601280 = validateParameter(valid_601280, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601280 != nil:
    section.add "Version", valid_601280
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601281 = header.getOrDefault("X-Amz-Date")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "X-Amz-Date", valid_601281
  var valid_601282 = header.getOrDefault("X-Amz-Security-Token")
  valid_601282 = validateParameter(valid_601282, JString, required = false,
                                 default = nil)
  if valid_601282 != nil:
    section.add "X-Amz-Security-Token", valid_601282
  var valid_601283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601283 = validateParameter(valid_601283, JString, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "X-Amz-Content-Sha256", valid_601283
  var valid_601284 = header.getOrDefault("X-Amz-Algorithm")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "X-Amz-Algorithm", valid_601284
  var valid_601285 = header.getOrDefault("X-Amz-Signature")
  valid_601285 = validateParameter(valid_601285, JString, required = false,
                                 default = nil)
  if valid_601285 != nil:
    section.add "X-Amz-Signature", valid_601285
  var valid_601286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601286 = validateParameter(valid_601286, JString, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "X-Amz-SignedHeaders", valid_601286
  var valid_601287 = header.getOrDefault("X-Amz-Credential")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "X-Amz-Credential", valid_601287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601288: Call_GetDeleteEndpoint_601275; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ## 
  let valid = call_601288.validator(path, query, header, formData, body)
  let scheme = call_601288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601288.url(scheme.get, call_601288.host, call_601288.base,
                         call_601288.route, valid.getOrDefault("path"))
  result = hook(call_601288, url, valid)

proc call*(call_601289: Call_GetDeleteEndpoint_601275; EndpointArn: string;
          Action: string = "DeleteEndpoint"; Version: string = "2010-03-31"): Recallable =
  ## getDeleteEndpoint
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ##   EndpointArn: string (required)
  ##              : EndpointArn of endpoint to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601290 = newJObject()
  add(query_601290, "EndpointArn", newJString(EndpointArn))
  add(query_601290, "Action", newJString(Action))
  add(query_601290, "Version", newJString(Version))
  result = call_601289.call(nil, query_601290, nil, nil, nil)

var getDeleteEndpoint* = Call_GetDeleteEndpoint_601275(name: "getDeleteEndpoint",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=DeleteEndpoint", validator: validate_GetDeleteEndpoint_601276,
    base: "/", url: url_GetDeleteEndpoint_601277,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeletePlatformApplication_601324 = ref object of OpenApiRestCall_600426
proc url_PostDeletePlatformApplication_601326(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeletePlatformApplication_601325(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601327 = query.getOrDefault("Action")
  valid_601327 = validateParameter(valid_601327, JString, required = true, default = newJString(
      "DeletePlatformApplication"))
  if valid_601327 != nil:
    section.add "Action", valid_601327
  var valid_601328 = query.getOrDefault("Version")
  valid_601328 = validateParameter(valid_601328, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601328 != nil:
    section.add "Version", valid_601328
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601329 = header.getOrDefault("X-Amz-Date")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "X-Amz-Date", valid_601329
  var valid_601330 = header.getOrDefault("X-Amz-Security-Token")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "X-Amz-Security-Token", valid_601330
  var valid_601331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "X-Amz-Content-Sha256", valid_601331
  var valid_601332 = header.getOrDefault("X-Amz-Algorithm")
  valid_601332 = validateParameter(valid_601332, JString, required = false,
                                 default = nil)
  if valid_601332 != nil:
    section.add "X-Amz-Algorithm", valid_601332
  var valid_601333 = header.getOrDefault("X-Amz-Signature")
  valid_601333 = validateParameter(valid_601333, JString, required = false,
                                 default = nil)
  if valid_601333 != nil:
    section.add "X-Amz-Signature", valid_601333
  var valid_601334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601334 = validateParameter(valid_601334, JString, required = false,
                                 default = nil)
  if valid_601334 != nil:
    section.add "X-Amz-SignedHeaders", valid_601334
  var valid_601335 = header.getOrDefault("X-Amz-Credential")
  valid_601335 = validateParameter(valid_601335, JString, required = false,
                                 default = nil)
  if valid_601335 != nil:
    section.add "X-Amz-Credential", valid_601335
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_601336 = formData.getOrDefault("PlatformApplicationArn")
  valid_601336 = validateParameter(valid_601336, JString, required = true,
                                 default = nil)
  if valid_601336 != nil:
    section.add "PlatformApplicationArn", valid_601336
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601337: Call_PostDeletePlatformApplication_601324; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_601337.validator(path, query, header, formData, body)
  let scheme = call_601337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601337.url(scheme.get, call_601337.host, call_601337.base,
                         call_601337.route, valid.getOrDefault("path"))
  result = hook(call_601337, url, valid)

proc call*(call_601338: Call_PostDeletePlatformApplication_601324;
          PlatformApplicationArn: string;
          Action: string = "DeletePlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## postDeletePlatformApplication
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  ##   Version: string (required)
  var query_601339 = newJObject()
  var formData_601340 = newJObject()
  add(query_601339, "Action", newJString(Action))
  add(formData_601340, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(query_601339, "Version", newJString(Version))
  result = call_601338.call(nil, query_601339, nil, formData_601340, nil)

var postDeletePlatformApplication* = Call_PostDeletePlatformApplication_601324(
    name: "postDeletePlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=DeletePlatformApplication",
    validator: validate_PostDeletePlatformApplication_601325, base: "/",
    url: url_PostDeletePlatformApplication_601326,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeletePlatformApplication_601308 = ref object of OpenApiRestCall_600426
proc url_GetDeletePlatformApplication_601310(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeletePlatformApplication_601309(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601311 = query.getOrDefault("Action")
  valid_601311 = validateParameter(valid_601311, JString, required = true, default = newJString(
      "DeletePlatformApplication"))
  if valid_601311 != nil:
    section.add "Action", valid_601311
  var valid_601312 = query.getOrDefault("Version")
  valid_601312 = validateParameter(valid_601312, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601312 != nil:
    section.add "Version", valid_601312
  var valid_601313 = query.getOrDefault("PlatformApplicationArn")
  valid_601313 = validateParameter(valid_601313, JString, required = true,
                                 default = nil)
  if valid_601313 != nil:
    section.add "PlatformApplicationArn", valid_601313
  result.add "query", section
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

proc call*(call_601321: Call_GetDeletePlatformApplication_601308; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_601321.validator(path, query, header, formData, body)
  let scheme = call_601321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601321.url(scheme.get, call_601321.host, call_601321.base,
                         call_601321.route, valid.getOrDefault("path"))
  result = hook(call_601321, url, valid)

proc call*(call_601322: Call_GetDeletePlatformApplication_601308;
          PlatformApplicationArn: string;
          Action: string = "DeletePlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## getDeletePlatformApplication
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  var query_601323 = newJObject()
  add(query_601323, "Action", newJString(Action))
  add(query_601323, "Version", newJString(Version))
  add(query_601323, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_601322.call(nil, query_601323, nil, nil, nil)

var getDeletePlatformApplication* = Call_GetDeletePlatformApplication_601308(
    name: "getDeletePlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=DeletePlatformApplication",
    validator: validate_GetDeletePlatformApplication_601309, base: "/",
    url: url_GetDeletePlatformApplication_601310,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteTopic_601357 = ref object of OpenApiRestCall_600426
proc url_PostDeleteTopic_601359(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteTopic_601358(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601360 = query.getOrDefault("Action")
  valid_601360 = validateParameter(valid_601360, JString, required = true,
                                 default = newJString("DeleteTopic"))
  if valid_601360 != nil:
    section.add "Action", valid_601360
  var valid_601361 = query.getOrDefault("Version")
  valid_601361 = validateParameter(valid_601361, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601361 != nil:
    section.add "Version", valid_601361
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601362 = header.getOrDefault("X-Amz-Date")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "X-Amz-Date", valid_601362
  var valid_601363 = header.getOrDefault("X-Amz-Security-Token")
  valid_601363 = validateParameter(valid_601363, JString, required = false,
                                 default = nil)
  if valid_601363 != nil:
    section.add "X-Amz-Security-Token", valid_601363
  var valid_601364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601364 = validateParameter(valid_601364, JString, required = false,
                                 default = nil)
  if valid_601364 != nil:
    section.add "X-Amz-Content-Sha256", valid_601364
  var valid_601365 = header.getOrDefault("X-Amz-Algorithm")
  valid_601365 = validateParameter(valid_601365, JString, required = false,
                                 default = nil)
  if valid_601365 != nil:
    section.add "X-Amz-Algorithm", valid_601365
  var valid_601366 = header.getOrDefault("X-Amz-Signature")
  valid_601366 = validateParameter(valid_601366, JString, required = false,
                                 default = nil)
  if valid_601366 != nil:
    section.add "X-Amz-Signature", valid_601366
  var valid_601367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601367 = validateParameter(valid_601367, JString, required = false,
                                 default = nil)
  if valid_601367 != nil:
    section.add "X-Amz-SignedHeaders", valid_601367
  var valid_601368 = header.getOrDefault("X-Amz-Credential")
  valid_601368 = validateParameter(valid_601368, JString, required = false,
                                 default = nil)
  if valid_601368 != nil:
    section.add "X-Amz-Credential", valid_601368
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic you want to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_601369 = formData.getOrDefault("TopicArn")
  valid_601369 = validateParameter(valid_601369, JString, required = true,
                                 default = nil)
  if valid_601369 != nil:
    section.add "TopicArn", valid_601369
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601370: Call_PostDeleteTopic_601357; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ## 
  let valid = call_601370.validator(path, query, header, formData, body)
  let scheme = call_601370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601370.url(scheme.get, call_601370.host, call_601370.base,
                         call_601370.route, valid.getOrDefault("path"))
  result = hook(call_601370, url, valid)

proc call*(call_601371: Call_PostDeleteTopic_601357; TopicArn: string;
          Action: string = "DeleteTopic"; Version: string = "2010-03-31"): Recallable =
  ## postDeleteTopic
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601372 = newJObject()
  var formData_601373 = newJObject()
  add(formData_601373, "TopicArn", newJString(TopicArn))
  add(query_601372, "Action", newJString(Action))
  add(query_601372, "Version", newJString(Version))
  result = call_601371.call(nil, query_601372, nil, formData_601373, nil)

var postDeleteTopic* = Call_PostDeleteTopic_601357(name: "postDeleteTopic",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=DeleteTopic", validator: validate_PostDeleteTopic_601358,
    base: "/", url: url_PostDeleteTopic_601359, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteTopic_601341 = ref object of OpenApiRestCall_600426
proc url_GetDeleteTopic_601343(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteTopic_601342(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic you want to delete.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601344 = query.getOrDefault("Action")
  valid_601344 = validateParameter(valid_601344, JString, required = true,
                                 default = newJString("DeleteTopic"))
  if valid_601344 != nil:
    section.add "Action", valid_601344
  var valid_601345 = query.getOrDefault("TopicArn")
  valid_601345 = validateParameter(valid_601345, JString, required = true,
                                 default = nil)
  if valid_601345 != nil:
    section.add "TopicArn", valid_601345
  var valid_601346 = query.getOrDefault("Version")
  valid_601346 = validateParameter(valid_601346, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601346 != nil:
    section.add "Version", valid_601346
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601347 = header.getOrDefault("X-Amz-Date")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "X-Amz-Date", valid_601347
  var valid_601348 = header.getOrDefault("X-Amz-Security-Token")
  valid_601348 = validateParameter(valid_601348, JString, required = false,
                                 default = nil)
  if valid_601348 != nil:
    section.add "X-Amz-Security-Token", valid_601348
  var valid_601349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601349 = validateParameter(valid_601349, JString, required = false,
                                 default = nil)
  if valid_601349 != nil:
    section.add "X-Amz-Content-Sha256", valid_601349
  var valid_601350 = header.getOrDefault("X-Amz-Algorithm")
  valid_601350 = validateParameter(valid_601350, JString, required = false,
                                 default = nil)
  if valid_601350 != nil:
    section.add "X-Amz-Algorithm", valid_601350
  var valid_601351 = header.getOrDefault("X-Amz-Signature")
  valid_601351 = validateParameter(valid_601351, JString, required = false,
                                 default = nil)
  if valid_601351 != nil:
    section.add "X-Amz-Signature", valid_601351
  var valid_601352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601352 = validateParameter(valid_601352, JString, required = false,
                                 default = nil)
  if valid_601352 != nil:
    section.add "X-Amz-SignedHeaders", valid_601352
  var valid_601353 = header.getOrDefault("X-Amz-Credential")
  valid_601353 = validateParameter(valid_601353, JString, required = false,
                                 default = nil)
  if valid_601353 != nil:
    section.add "X-Amz-Credential", valid_601353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601354: Call_GetDeleteTopic_601341; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ## 
  let valid = call_601354.validator(path, query, header, formData, body)
  let scheme = call_601354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601354.url(scheme.get, call_601354.host, call_601354.base,
                         call_601354.route, valid.getOrDefault("path"))
  result = hook(call_601354, url, valid)

proc call*(call_601355: Call_GetDeleteTopic_601341; TopicArn: string;
          Action: string = "DeleteTopic"; Version: string = "2010-03-31"): Recallable =
  ## getDeleteTopic
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ##   Action: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to delete.
  ##   Version: string (required)
  var query_601356 = newJObject()
  add(query_601356, "Action", newJString(Action))
  add(query_601356, "TopicArn", newJString(TopicArn))
  add(query_601356, "Version", newJString(Version))
  result = call_601355.call(nil, query_601356, nil, nil, nil)

var getDeleteTopic* = Call_GetDeleteTopic_601341(name: "getDeleteTopic",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=DeleteTopic", validator: validate_GetDeleteTopic_601342,
    base: "/", url: url_GetDeleteTopic_601343, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetEndpointAttributes_601390 = ref object of OpenApiRestCall_600426
proc url_PostGetEndpointAttributes_601392(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostGetEndpointAttributes_601391(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601393 = query.getOrDefault("Action")
  valid_601393 = validateParameter(valid_601393, JString, required = true,
                                 default = newJString("GetEndpointAttributes"))
  if valid_601393 != nil:
    section.add "Action", valid_601393
  var valid_601394 = query.getOrDefault("Version")
  valid_601394 = validateParameter(valid_601394, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601394 != nil:
    section.add "Version", valid_601394
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601395 = header.getOrDefault("X-Amz-Date")
  valid_601395 = validateParameter(valid_601395, JString, required = false,
                                 default = nil)
  if valid_601395 != nil:
    section.add "X-Amz-Date", valid_601395
  var valid_601396 = header.getOrDefault("X-Amz-Security-Token")
  valid_601396 = validateParameter(valid_601396, JString, required = false,
                                 default = nil)
  if valid_601396 != nil:
    section.add "X-Amz-Security-Token", valid_601396
  var valid_601397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601397 = validateParameter(valid_601397, JString, required = false,
                                 default = nil)
  if valid_601397 != nil:
    section.add "X-Amz-Content-Sha256", valid_601397
  var valid_601398 = header.getOrDefault("X-Amz-Algorithm")
  valid_601398 = validateParameter(valid_601398, JString, required = false,
                                 default = nil)
  if valid_601398 != nil:
    section.add "X-Amz-Algorithm", valid_601398
  var valid_601399 = header.getOrDefault("X-Amz-Signature")
  valid_601399 = validateParameter(valid_601399, JString, required = false,
                                 default = nil)
  if valid_601399 != nil:
    section.add "X-Amz-Signature", valid_601399
  var valid_601400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601400 = validateParameter(valid_601400, JString, required = false,
                                 default = nil)
  if valid_601400 != nil:
    section.add "X-Amz-SignedHeaders", valid_601400
  var valid_601401 = header.getOrDefault("X-Amz-Credential")
  valid_601401 = validateParameter(valid_601401, JString, required = false,
                                 default = nil)
  if valid_601401 != nil:
    section.add "X-Amz-Credential", valid_601401
  result.add "header", section
  ## parameters in `formData` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_601402 = formData.getOrDefault("EndpointArn")
  valid_601402 = validateParameter(valid_601402, JString, required = true,
                                 default = nil)
  if valid_601402 != nil:
    section.add "EndpointArn", valid_601402
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601403: Call_PostGetEndpointAttributes_601390; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_601403.validator(path, query, header, formData, body)
  let scheme = call_601403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601403.url(scheme.get, call_601403.host, call_601403.base,
                         call_601403.route, valid.getOrDefault("path"))
  result = hook(call_601403, url, valid)

proc call*(call_601404: Call_PostGetEndpointAttributes_601390; EndpointArn: string;
          Action: string = "GetEndpointAttributes"; Version: string = "2010-03-31"): Recallable =
  ## postGetEndpointAttributes
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   EndpointArn: string (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  ##   Version: string (required)
  var query_601405 = newJObject()
  var formData_601406 = newJObject()
  add(query_601405, "Action", newJString(Action))
  add(formData_601406, "EndpointArn", newJString(EndpointArn))
  add(query_601405, "Version", newJString(Version))
  result = call_601404.call(nil, query_601405, nil, formData_601406, nil)

var postGetEndpointAttributes* = Call_PostGetEndpointAttributes_601390(
    name: "postGetEndpointAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetEndpointAttributes",
    validator: validate_PostGetEndpointAttributes_601391, base: "/",
    url: url_PostGetEndpointAttributes_601392,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetEndpointAttributes_601374 = ref object of OpenApiRestCall_600426
proc url_GetGetEndpointAttributes_601376(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGetEndpointAttributes_601375(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `EndpointArn` field"
  var valid_601377 = query.getOrDefault("EndpointArn")
  valid_601377 = validateParameter(valid_601377, JString, required = true,
                                 default = nil)
  if valid_601377 != nil:
    section.add "EndpointArn", valid_601377
  var valid_601378 = query.getOrDefault("Action")
  valid_601378 = validateParameter(valid_601378, JString, required = true,
                                 default = newJString("GetEndpointAttributes"))
  if valid_601378 != nil:
    section.add "Action", valid_601378
  var valid_601379 = query.getOrDefault("Version")
  valid_601379 = validateParameter(valid_601379, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601379 != nil:
    section.add "Version", valid_601379
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601380 = header.getOrDefault("X-Amz-Date")
  valid_601380 = validateParameter(valid_601380, JString, required = false,
                                 default = nil)
  if valid_601380 != nil:
    section.add "X-Amz-Date", valid_601380
  var valid_601381 = header.getOrDefault("X-Amz-Security-Token")
  valid_601381 = validateParameter(valid_601381, JString, required = false,
                                 default = nil)
  if valid_601381 != nil:
    section.add "X-Amz-Security-Token", valid_601381
  var valid_601382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601382 = validateParameter(valid_601382, JString, required = false,
                                 default = nil)
  if valid_601382 != nil:
    section.add "X-Amz-Content-Sha256", valid_601382
  var valid_601383 = header.getOrDefault("X-Amz-Algorithm")
  valid_601383 = validateParameter(valid_601383, JString, required = false,
                                 default = nil)
  if valid_601383 != nil:
    section.add "X-Amz-Algorithm", valid_601383
  var valid_601384 = header.getOrDefault("X-Amz-Signature")
  valid_601384 = validateParameter(valid_601384, JString, required = false,
                                 default = nil)
  if valid_601384 != nil:
    section.add "X-Amz-Signature", valid_601384
  var valid_601385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601385 = validateParameter(valid_601385, JString, required = false,
                                 default = nil)
  if valid_601385 != nil:
    section.add "X-Amz-SignedHeaders", valid_601385
  var valid_601386 = header.getOrDefault("X-Amz-Credential")
  valid_601386 = validateParameter(valid_601386, JString, required = false,
                                 default = nil)
  if valid_601386 != nil:
    section.add "X-Amz-Credential", valid_601386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601387: Call_GetGetEndpointAttributes_601374; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_601387.validator(path, query, header, formData, body)
  let scheme = call_601387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601387.url(scheme.get, call_601387.host, call_601387.base,
                         call_601387.route, valid.getOrDefault("path"))
  result = hook(call_601387, url, valid)

proc call*(call_601388: Call_GetGetEndpointAttributes_601374; EndpointArn: string;
          Action: string = "GetEndpointAttributes"; Version: string = "2010-03-31"): Recallable =
  ## getGetEndpointAttributes
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   EndpointArn: string (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601389 = newJObject()
  add(query_601389, "EndpointArn", newJString(EndpointArn))
  add(query_601389, "Action", newJString(Action))
  add(query_601389, "Version", newJString(Version))
  result = call_601388.call(nil, query_601389, nil, nil, nil)

var getGetEndpointAttributes* = Call_GetGetEndpointAttributes_601374(
    name: "getGetEndpointAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetEndpointAttributes",
    validator: validate_GetGetEndpointAttributes_601375, base: "/",
    url: url_GetGetEndpointAttributes_601376, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetPlatformApplicationAttributes_601423 = ref object of OpenApiRestCall_600426
proc url_PostGetPlatformApplicationAttributes_601425(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostGetPlatformApplicationAttributes_601424(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601426 = query.getOrDefault("Action")
  valid_601426 = validateParameter(valid_601426, JString, required = true, default = newJString(
      "GetPlatformApplicationAttributes"))
  if valid_601426 != nil:
    section.add "Action", valid_601426
  var valid_601427 = query.getOrDefault("Version")
  valid_601427 = validateParameter(valid_601427, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601427 != nil:
    section.add "Version", valid_601427
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601428 = header.getOrDefault("X-Amz-Date")
  valid_601428 = validateParameter(valid_601428, JString, required = false,
                                 default = nil)
  if valid_601428 != nil:
    section.add "X-Amz-Date", valid_601428
  var valid_601429 = header.getOrDefault("X-Amz-Security-Token")
  valid_601429 = validateParameter(valid_601429, JString, required = false,
                                 default = nil)
  if valid_601429 != nil:
    section.add "X-Amz-Security-Token", valid_601429
  var valid_601430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601430 = validateParameter(valid_601430, JString, required = false,
                                 default = nil)
  if valid_601430 != nil:
    section.add "X-Amz-Content-Sha256", valid_601430
  var valid_601431 = header.getOrDefault("X-Amz-Algorithm")
  valid_601431 = validateParameter(valid_601431, JString, required = false,
                                 default = nil)
  if valid_601431 != nil:
    section.add "X-Amz-Algorithm", valid_601431
  var valid_601432 = header.getOrDefault("X-Amz-Signature")
  valid_601432 = validateParameter(valid_601432, JString, required = false,
                                 default = nil)
  if valid_601432 != nil:
    section.add "X-Amz-Signature", valid_601432
  var valid_601433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601433 = validateParameter(valid_601433, JString, required = false,
                                 default = nil)
  if valid_601433 != nil:
    section.add "X-Amz-SignedHeaders", valid_601433
  var valid_601434 = header.getOrDefault("X-Amz-Credential")
  valid_601434 = validateParameter(valid_601434, JString, required = false,
                                 default = nil)
  if valid_601434 != nil:
    section.add "X-Amz-Credential", valid_601434
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_601435 = formData.getOrDefault("PlatformApplicationArn")
  valid_601435 = validateParameter(valid_601435, JString, required = true,
                                 default = nil)
  if valid_601435 != nil:
    section.add "PlatformApplicationArn", valid_601435
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601436: Call_PostGetPlatformApplicationAttributes_601423;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_601436.validator(path, query, header, formData, body)
  let scheme = call_601436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601436.url(scheme.get, call_601436.host, call_601436.base,
                         call_601436.route, valid.getOrDefault("path"))
  result = hook(call_601436, url, valid)

proc call*(call_601437: Call_PostGetPlatformApplicationAttributes_601423;
          PlatformApplicationArn: string;
          Action: string = "GetPlatformApplicationAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetPlatformApplicationAttributes
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  ##   Version: string (required)
  var query_601438 = newJObject()
  var formData_601439 = newJObject()
  add(query_601438, "Action", newJString(Action))
  add(formData_601439, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(query_601438, "Version", newJString(Version))
  result = call_601437.call(nil, query_601438, nil, formData_601439, nil)

var postGetPlatformApplicationAttributes* = Call_PostGetPlatformApplicationAttributes_601423(
    name: "postGetPlatformApplicationAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetPlatformApplicationAttributes",
    validator: validate_PostGetPlatformApplicationAttributes_601424, base: "/",
    url: url_PostGetPlatformApplicationAttributes_601425,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetPlatformApplicationAttributes_601407 = ref object of OpenApiRestCall_600426
proc url_GetGetPlatformApplicationAttributes_601409(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGetPlatformApplicationAttributes_601408(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601410 = query.getOrDefault("Action")
  valid_601410 = validateParameter(valid_601410, JString, required = true, default = newJString(
      "GetPlatformApplicationAttributes"))
  if valid_601410 != nil:
    section.add "Action", valid_601410
  var valid_601411 = query.getOrDefault("Version")
  valid_601411 = validateParameter(valid_601411, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601411 != nil:
    section.add "Version", valid_601411
  var valid_601412 = query.getOrDefault("PlatformApplicationArn")
  valid_601412 = validateParameter(valid_601412, JString, required = true,
                                 default = nil)
  if valid_601412 != nil:
    section.add "PlatformApplicationArn", valid_601412
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601413 = header.getOrDefault("X-Amz-Date")
  valid_601413 = validateParameter(valid_601413, JString, required = false,
                                 default = nil)
  if valid_601413 != nil:
    section.add "X-Amz-Date", valid_601413
  var valid_601414 = header.getOrDefault("X-Amz-Security-Token")
  valid_601414 = validateParameter(valid_601414, JString, required = false,
                                 default = nil)
  if valid_601414 != nil:
    section.add "X-Amz-Security-Token", valid_601414
  var valid_601415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601415 = validateParameter(valid_601415, JString, required = false,
                                 default = nil)
  if valid_601415 != nil:
    section.add "X-Amz-Content-Sha256", valid_601415
  var valid_601416 = header.getOrDefault("X-Amz-Algorithm")
  valid_601416 = validateParameter(valid_601416, JString, required = false,
                                 default = nil)
  if valid_601416 != nil:
    section.add "X-Amz-Algorithm", valid_601416
  var valid_601417 = header.getOrDefault("X-Amz-Signature")
  valid_601417 = validateParameter(valid_601417, JString, required = false,
                                 default = nil)
  if valid_601417 != nil:
    section.add "X-Amz-Signature", valid_601417
  var valid_601418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601418 = validateParameter(valid_601418, JString, required = false,
                                 default = nil)
  if valid_601418 != nil:
    section.add "X-Amz-SignedHeaders", valid_601418
  var valid_601419 = header.getOrDefault("X-Amz-Credential")
  valid_601419 = validateParameter(valid_601419, JString, required = false,
                                 default = nil)
  if valid_601419 != nil:
    section.add "X-Amz-Credential", valid_601419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601420: Call_GetGetPlatformApplicationAttributes_601407;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_601420.validator(path, query, header, formData, body)
  let scheme = call_601420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601420.url(scheme.get, call_601420.host, call_601420.base,
                         call_601420.route, valid.getOrDefault("path"))
  result = hook(call_601420, url, valid)

proc call*(call_601421: Call_GetGetPlatformApplicationAttributes_601407;
          PlatformApplicationArn: string;
          Action: string = "GetPlatformApplicationAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getGetPlatformApplicationAttributes
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  var query_601422 = newJObject()
  add(query_601422, "Action", newJString(Action))
  add(query_601422, "Version", newJString(Version))
  add(query_601422, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_601421.call(nil, query_601422, nil, nil, nil)

var getGetPlatformApplicationAttributes* = Call_GetGetPlatformApplicationAttributes_601407(
    name: "getGetPlatformApplicationAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetPlatformApplicationAttributes",
    validator: validate_GetGetPlatformApplicationAttributes_601408, base: "/",
    url: url_GetGetPlatformApplicationAttributes_601409,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetSMSAttributes_601456 = ref object of OpenApiRestCall_600426
proc url_PostGetSMSAttributes_601458(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostGetSMSAttributes_601457(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601459 = query.getOrDefault("Action")
  valid_601459 = validateParameter(valid_601459, JString, required = true,
                                 default = newJString("GetSMSAttributes"))
  if valid_601459 != nil:
    section.add "Action", valid_601459
  var valid_601460 = query.getOrDefault("Version")
  valid_601460 = validateParameter(valid_601460, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601460 != nil:
    section.add "Version", valid_601460
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601461 = header.getOrDefault("X-Amz-Date")
  valid_601461 = validateParameter(valid_601461, JString, required = false,
                                 default = nil)
  if valid_601461 != nil:
    section.add "X-Amz-Date", valid_601461
  var valid_601462 = header.getOrDefault("X-Amz-Security-Token")
  valid_601462 = validateParameter(valid_601462, JString, required = false,
                                 default = nil)
  if valid_601462 != nil:
    section.add "X-Amz-Security-Token", valid_601462
  var valid_601463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601463 = validateParameter(valid_601463, JString, required = false,
                                 default = nil)
  if valid_601463 != nil:
    section.add "X-Amz-Content-Sha256", valid_601463
  var valid_601464 = header.getOrDefault("X-Amz-Algorithm")
  valid_601464 = validateParameter(valid_601464, JString, required = false,
                                 default = nil)
  if valid_601464 != nil:
    section.add "X-Amz-Algorithm", valid_601464
  var valid_601465 = header.getOrDefault("X-Amz-Signature")
  valid_601465 = validateParameter(valid_601465, JString, required = false,
                                 default = nil)
  if valid_601465 != nil:
    section.add "X-Amz-Signature", valid_601465
  var valid_601466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601466 = validateParameter(valid_601466, JString, required = false,
                                 default = nil)
  if valid_601466 != nil:
    section.add "X-Amz-SignedHeaders", valid_601466
  var valid_601467 = header.getOrDefault("X-Amz-Credential")
  valid_601467 = validateParameter(valid_601467, JString, required = false,
                                 default = nil)
  if valid_601467 != nil:
    section.add "X-Amz-Credential", valid_601467
  result.add "header", section
  ## parameters in `formData` object:
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  section = newJObject()
  var valid_601468 = formData.getOrDefault("attributes")
  valid_601468 = validateParameter(valid_601468, JArray, required = false,
                                 default = nil)
  if valid_601468 != nil:
    section.add "attributes", valid_601468
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601469: Call_PostGetSMSAttributes_601456; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  let valid = call_601469.validator(path, query, header, formData, body)
  let scheme = call_601469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601469.url(scheme.get, call_601469.host, call_601469.base,
                         call_601469.route, valid.getOrDefault("path"))
  result = hook(call_601469, url, valid)

proc call*(call_601470: Call_PostGetSMSAttributes_601456;
          attributes: JsonNode = nil; Action: string = "GetSMSAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetSMSAttributes
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601471 = newJObject()
  var formData_601472 = newJObject()
  if attributes != nil:
    formData_601472.add "attributes", attributes
  add(query_601471, "Action", newJString(Action))
  add(query_601471, "Version", newJString(Version))
  result = call_601470.call(nil, query_601471, nil, formData_601472, nil)

var postGetSMSAttributes* = Call_PostGetSMSAttributes_601456(
    name: "postGetSMSAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetSMSAttributes",
    validator: validate_PostGetSMSAttributes_601457, base: "/",
    url: url_PostGetSMSAttributes_601458, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetSMSAttributes_601440 = ref object of OpenApiRestCall_600426
proc url_GetGetSMSAttributes_601442(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGetSMSAttributes_601441(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_601443 = query.getOrDefault("attributes")
  valid_601443 = validateParameter(valid_601443, JArray, required = false,
                                 default = nil)
  if valid_601443 != nil:
    section.add "attributes", valid_601443
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601444 = query.getOrDefault("Action")
  valid_601444 = validateParameter(valid_601444, JString, required = true,
                                 default = newJString("GetSMSAttributes"))
  if valid_601444 != nil:
    section.add "Action", valid_601444
  var valid_601445 = query.getOrDefault("Version")
  valid_601445 = validateParameter(valid_601445, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601445 != nil:
    section.add "Version", valid_601445
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601446 = header.getOrDefault("X-Amz-Date")
  valid_601446 = validateParameter(valid_601446, JString, required = false,
                                 default = nil)
  if valid_601446 != nil:
    section.add "X-Amz-Date", valid_601446
  var valid_601447 = header.getOrDefault("X-Amz-Security-Token")
  valid_601447 = validateParameter(valid_601447, JString, required = false,
                                 default = nil)
  if valid_601447 != nil:
    section.add "X-Amz-Security-Token", valid_601447
  var valid_601448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601448 = validateParameter(valid_601448, JString, required = false,
                                 default = nil)
  if valid_601448 != nil:
    section.add "X-Amz-Content-Sha256", valid_601448
  var valid_601449 = header.getOrDefault("X-Amz-Algorithm")
  valid_601449 = validateParameter(valid_601449, JString, required = false,
                                 default = nil)
  if valid_601449 != nil:
    section.add "X-Amz-Algorithm", valid_601449
  var valid_601450 = header.getOrDefault("X-Amz-Signature")
  valid_601450 = validateParameter(valid_601450, JString, required = false,
                                 default = nil)
  if valid_601450 != nil:
    section.add "X-Amz-Signature", valid_601450
  var valid_601451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601451 = validateParameter(valid_601451, JString, required = false,
                                 default = nil)
  if valid_601451 != nil:
    section.add "X-Amz-SignedHeaders", valid_601451
  var valid_601452 = header.getOrDefault("X-Amz-Credential")
  valid_601452 = validateParameter(valid_601452, JString, required = false,
                                 default = nil)
  if valid_601452 != nil:
    section.add "X-Amz-Credential", valid_601452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601453: Call_GetGetSMSAttributes_601440; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  let valid = call_601453.validator(path, query, header, formData, body)
  let scheme = call_601453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601453.url(scheme.get, call_601453.host, call_601453.base,
                         call_601453.route, valid.getOrDefault("path"))
  result = hook(call_601453, url, valid)

proc call*(call_601454: Call_GetGetSMSAttributes_601440;
          attributes: JsonNode = nil; Action: string = "GetSMSAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getGetSMSAttributes
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601455 = newJObject()
  if attributes != nil:
    query_601455.add "attributes", attributes
  add(query_601455, "Action", newJString(Action))
  add(query_601455, "Version", newJString(Version))
  result = call_601454.call(nil, query_601455, nil, nil, nil)

var getGetSMSAttributes* = Call_GetGetSMSAttributes_601440(
    name: "getGetSMSAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetSMSAttributes",
    validator: validate_GetGetSMSAttributes_601441, base: "/",
    url: url_GetGetSMSAttributes_601442, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetSubscriptionAttributes_601489 = ref object of OpenApiRestCall_600426
proc url_PostGetSubscriptionAttributes_601491(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostGetSubscriptionAttributes_601490(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns all of the properties of a subscription.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601492 = query.getOrDefault("Action")
  valid_601492 = validateParameter(valid_601492, JString, required = true, default = newJString(
      "GetSubscriptionAttributes"))
  if valid_601492 != nil:
    section.add "Action", valid_601492
  var valid_601493 = query.getOrDefault("Version")
  valid_601493 = validateParameter(valid_601493, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601493 != nil:
    section.add "Version", valid_601493
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601494 = header.getOrDefault("X-Amz-Date")
  valid_601494 = validateParameter(valid_601494, JString, required = false,
                                 default = nil)
  if valid_601494 != nil:
    section.add "X-Amz-Date", valid_601494
  var valid_601495 = header.getOrDefault("X-Amz-Security-Token")
  valid_601495 = validateParameter(valid_601495, JString, required = false,
                                 default = nil)
  if valid_601495 != nil:
    section.add "X-Amz-Security-Token", valid_601495
  var valid_601496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601496 = validateParameter(valid_601496, JString, required = false,
                                 default = nil)
  if valid_601496 != nil:
    section.add "X-Amz-Content-Sha256", valid_601496
  var valid_601497 = header.getOrDefault("X-Amz-Algorithm")
  valid_601497 = validateParameter(valid_601497, JString, required = false,
                                 default = nil)
  if valid_601497 != nil:
    section.add "X-Amz-Algorithm", valid_601497
  var valid_601498 = header.getOrDefault("X-Amz-Signature")
  valid_601498 = validateParameter(valid_601498, JString, required = false,
                                 default = nil)
  if valid_601498 != nil:
    section.add "X-Amz-Signature", valid_601498
  var valid_601499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601499 = validateParameter(valid_601499, JString, required = false,
                                 default = nil)
  if valid_601499 != nil:
    section.add "X-Amz-SignedHeaders", valid_601499
  var valid_601500 = header.getOrDefault("X-Amz-Credential")
  valid_601500 = validateParameter(valid_601500, JString, required = false,
                                 default = nil)
  if valid_601500 != nil:
    section.add "X-Amz-Credential", valid_601500
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionArn` field"
  var valid_601501 = formData.getOrDefault("SubscriptionArn")
  valid_601501 = validateParameter(valid_601501, JString, required = true,
                                 default = nil)
  if valid_601501 != nil:
    section.add "SubscriptionArn", valid_601501
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601502: Call_PostGetSubscriptionAttributes_601489; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a subscription.
  ## 
  let valid = call_601502.validator(path, query, header, formData, body)
  let scheme = call_601502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601502.url(scheme.get, call_601502.host, call_601502.base,
                         call_601502.route, valid.getOrDefault("path"))
  result = hook(call_601502, url, valid)

proc call*(call_601503: Call_PostGetSubscriptionAttributes_601489;
          SubscriptionArn: string; Action: string = "GetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetSubscriptionAttributes
  ## Returns all of the properties of a subscription.
  ##   Action: string (required)
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  ##   Version: string (required)
  var query_601504 = newJObject()
  var formData_601505 = newJObject()
  add(query_601504, "Action", newJString(Action))
  add(formData_601505, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_601504, "Version", newJString(Version))
  result = call_601503.call(nil, query_601504, nil, formData_601505, nil)

var postGetSubscriptionAttributes* = Call_PostGetSubscriptionAttributes_601489(
    name: "postGetSubscriptionAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetSubscriptionAttributes",
    validator: validate_PostGetSubscriptionAttributes_601490, base: "/",
    url: url_PostGetSubscriptionAttributes_601491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetSubscriptionAttributes_601473 = ref object of OpenApiRestCall_600426
proc url_GetGetSubscriptionAttributes_601475(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGetSubscriptionAttributes_601474(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns all of the properties of a subscription.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SubscriptionArn` field"
  var valid_601476 = query.getOrDefault("SubscriptionArn")
  valid_601476 = validateParameter(valid_601476, JString, required = true,
                                 default = nil)
  if valid_601476 != nil:
    section.add "SubscriptionArn", valid_601476
  var valid_601477 = query.getOrDefault("Action")
  valid_601477 = validateParameter(valid_601477, JString, required = true, default = newJString(
      "GetSubscriptionAttributes"))
  if valid_601477 != nil:
    section.add "Action", valid_601477
  var valid_601478 = query.getOrDefault("Version")
  valid_601478 = validateParameter(valid_601478, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601478 != nil:
    section.add "Version", valid_601478
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601479 = header.getOrDefault("X-Amz-Date")
  valid_601479 = validateParameter(valid_601479, JString, required = false,
                                 default = nil)
  if valid_601479 != nil:
    section.add "X-Amz-Date", valid_601479
  var valid_601480 = header.getOrDefault("X-Amz-Security-Token")
  valid_601480 = validateParameter(valid_601480, JString, required = false,
                                 default = nil)
  if valid_601480 != nil:
    section.add "X-Amz-Security-Token", valid_601480
  var valid_601481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601481 = validateParameter(valid_601481, JString, required = false,
                                 default = nil)
  if valid_601481 != nil:
    section.add "X-Amz-Content-Sha256", valid_601481
  var valid_601482 = header.getOrDefault("X-Amz-Algorithm")
  valid_601482 = validateParameter(valid_601482, JString, required = false,
                                 default = nil)
  if valid_601482 != nil:
    section.add "X-Amz-Algorithm", valid_601482
  var valid_601483 = header.getOrDefault("X-Amz-Signature")
  valid_601483 = validateParameter(valid_601483, JString, required = false,
                                 default = nil)
  if valid_601483 != nil:
    section.add "X-Amz-Signature", valid_601483
  var valid_601484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601484 = validateParameter(valid_601484, JString, required = false,
                                 default = nil)
  if valid_601484 != nil:
    section.add "X-Amz-SignedHeaders", valid_601484
  var valid_601485 = header.getOrDefault("X-Amz-Credential")
  valid_601485 = validateParameter(valid_601485, JString, required = false,
                                 default = nil)
  if valid_601485 != nil:
    section.add "X-Amz-Credential", valid_601485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601486: Call_GetGetSubscriptionAttributes_601473; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a subscription.
  ## 
  let valid = call_601486.validator(path, query, header, formData, body)
  let scheme = call_601486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601486.url(scheme.get, call_601486.host, call_601486.base,
                         call_601486.route, valid.getOrDefault("path"))
  result = hook(call_601486, url, valid)

proc call*(call_601487: Call_GetGetSubscriptionAttributes_601473;
          SubscriptionArn: string; Action: string = "GetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getGetSubscriptionAttributes
  ## Returns all of the properties of a subscription.
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601488 = newJObject()
  add(query_601488, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_601488, "Action", newJString(Action))
  add(query_601488, "Version", newJString(Version))
  result = call_601487.call(nil, query_601488, nil, nil, nil)

var getGetSubscriptionAttributes* = Call_GetGetSubscriptionAttributes_601473(
    name: "getGetSubscriptionAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetSubscriptionAttributes",
    validator: validate_GetGetSubscriptionAttributes_601474, base: "/",
    url: url_GetGetSubscriptionAttributes_601475,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetTopicAttributes_601522 = ref object of OpenApiRestCall_600426
proc url_PostGetTopicAttributes_601524(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostGetTopicAttributes_601523(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601525 = query.getOrDefault("Action")
  valid_601525 = validateParameter(valid_601525, JString, required = true,
                                 default = newJString("GetTopicAttributes"))
  if valid_601525 != nil:
    section.add "Action", valid_601525
  var valid_601526 = query.getOrDefault("Version")
  valid_601526 = validateParameter(valid_601526, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601526 != nil:
    section.add "Version", valid_601526
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601527 = header.getOrDefault("X-Amz-Date")
  valid_601527 = validateParameter(valid_601527, JString, required = false,
                                 default = nil)
  if valid_601527 != nil:
    section.add "X-Amz-Date", valid_601527
  var valid_601528 = header.getOrDefault("X-Amz-Security-Token")
  valid_601528 = validateParameter(valid_601528, JString, required = false,
                                 default = nil)
  if valid_601528 != nil:
    section.add "X-Amz-Security-Token", valid_601528
  var valid_601529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601529 = validateParameter(valid_601529, JString, required = false,
                                 default = nil)
  if valid_601529 != nil:
    section.add "X-Amz-Content-Sha256", valid_601529
  var valid_601530 = header.getOrDefault("X-Amz-Algorithm")
  valid_601530 = validateParameter(valid_601530, JString, required = false,
                                 default = nil)
  if valid_601530 != nil:
    section.add "X-Amz-Algorithm", valid_601530
  var valid_601531 = header.getOrDefault("X-Amz-Signature")
  valid_601531 = validateParameter(valid_601531, JString, required = false,
                                 default = nil)
  if valid_601531 != nil:
    section.add "X-Amz-Signature", valid_601531
  var valid_601532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601532 = validateParameter(valid_601532, JString, required = false,
                                 default = nil)
  if valid_601532 != nil:
    section.add "X-Amz-SignedHeaders", valid_601532
  var valid_601533 = header.getOrDefault("X-Amz-Credential")
  valid_601533 = validateParameter(valid_601533, JString, required = false,
                                 default = nil)
  if valid_601533 != nil:
    section.add "X-Amz-Credential", valid_601533
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose properties you want to get.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_601534 = formData.getOrDefault("TopicArn")
  valid_601534 = validateParameter(valid_601534, JString, required = true,
                                 default = nil)
  if valid_601534 != nil:
    section.add "TopicArn", valid_601534
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601535: Call_PostGetTopicAttributes_601522; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ## 
  let valid = call_601535.validator(path, query, header, formData, body)
  let scheme = call_601535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601535.url(scheme.get, call_601535.host, call_601535.base,
                         call_601535.route, valid.getOrDefault("path"))
  result = hook(call_601535, url, valid)

proc call*(call_601536: Call_PostGetTopicAttributes_601522; TopicArn: string;
          Action: string = "GetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## postGetTopicAttributes
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose properties you want to get.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601537 = newJObject()
  var formData_601538 = newJObject()
  add(formData_601538, "TopicArn", newJString(TopicArn))
  add(query_601537, "Action", newJString(Action))
  add(query_601537, "Version", newJString(Version))
  result = call_601536.call(nil, query_601537, nil, formData_601538, nil)

var postGetTopicAttributes* = Call_PostGetTopicAttributes_601522(
    name: "postGetTopicAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetTopicAttributes",
    validator: validate_PostGetTopicAttributes_601523, base: "/",
    url: url_PostGetTopicAttributes_601524, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetTopicAttributes_601506 = ref object of OpenApiRestCall_600426
proc url_GetGetTopicAttributes_601508(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGetTopicAttributes_601507(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose properties you want to get.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601509 = query.getOrDefault("Action")
  valid_601509 = validateParameter(valid_601509, JString, required = true,
                                 default = newJString("GetTopicAttributes"))
  if valid_601509 != nil:
    section.add "Action", valid_601509
  var valid_601510 = query.getOrDefault("TopicArn")
  valid_601510 = validateParameter(valid_601510, JString, required = true,
                                 default = nil)
  if valid_601510 != nil:
    section.add "TopicArn", valid_601510
  var valid_601511 = query.getOrDefault("Version")
  valid_601511 = validateParameter(valid_601511, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601511 != nil:
    section.add "Version", valid_601511
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601512 = header.getOrDefault("X-Amz-Date")
  valid_601512 = validateParameter(valid_601512, JString, required = false,
                                 default = nil)
  if valid_601512 != nil:
    section.add "X-Amz-Date", valid_601512
  var valid_601513 = header.getOrDefault("X-Amz-Security-Token")
  valid_601513 = validateParameter(valid_601513, JString, required = false,
                                 default = nil)
  if valid_601513 != nil:
    section.add "X-Amz-Security-Token", valid_601513
  var valid_601514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601514 = validateParameter(valid_601514, JString, required = false,
                                 default = nil)
  if valid_601514 != nil:
    section.add "X-Amz-Content-Sha256", valid_601514
  var valid_601515 = header.getOrDefault("X-Amz-Algorithm")
  valid_601515 = validateParameter(valid_601515, JString, required = false,
                                 default = nil)
  if valid_601515 != nil:
    section.add "X-Amz-Algorithm", valid_601515
  var valid_601516 = header.getOrDefault("X-Amz-Signature")
  valid_601516 = validateParameter(valid_601516, JString, required = false,
                                 default = nil)
  if valid_601516 != nil:
    section.add "X-Amz-Signature", valid_601516
  var valid_601517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601517 = validateParameter(valid_601517, JString, required = false,
                                 default = nil)
  if valid_601517 != nil:
    section.add "X-Amz-SignedHeaders", valid_601517
  var valid_601518 = header.getOrDefault("X-Amz-Credential")
  valid_601518 = validateParameter(valid_601518, JString, required = false,
                                 default = nil)
  if valid_601518 != nil:
    section.add "X-Amz-Credential", valid_601518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601519: Call_GetGetTopicAttributes_601506; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ## 
  let valid = call_601519.validator(path, query, header, formData, body)
  let scheme = call_601519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601519.url(scheme.get, call_601519.host, call_601519.base,
                         call_601519.route, valid.getOrDefault("path"))
  result = hook(call_601519, url, valid)

proc call*(call_601520: Call_GetGetTopicAttributes_601506; TopicArn: string;
          Action: string = "GetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## getGetTopicAttributes
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ##   Action: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose properties you want to get.
  ##   Version: string (required)
  var query_601521 = newJObject()
  add(query_601521, "Action", newJString(Action))
  add(query_601521, "TopicArn", newJString(TopicArn))
  add(query_601521, "Version", newJString(Version))
  result = call_601520.call(nil, query_601521, nil, nil, nil)

var getGetTopicAttributes* = Call_GetGetTopicAttributes_601506(
    name: "getGetTopicAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetTopicAttributes",
    validator: validate_GetGetTopicAttributes_601507, base: "/",
    url: url_GetGetTopicAttributes_601508, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListEndpointsByPlatformApplication_601556 = ref object of OpenApiRestCall_600426
proc url_PostListEndpointsByPlatformApplication_601558(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListEndpointsByPlatformApplication_601557(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as GCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601559 = query.getOrDefault("Action")
  valid_601559 = validateParameter(valid_601559, JString, required = true, default = newJString(
      "ListEndpointsByPlatformApplication"))
  if valid_601559 != nil:
    section.add "Action", valid_601559
  var valid_601560 = query.getOrDefault("Version")
  valid_601560 = validateParameter(valid_601560, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601560 != nil:
    section.add "Version", valid_601560
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601561 = header.getOrDefault("X-Amz-Date")
  valid_601561 = validateParameter(valid_601561, JString, required = false,
                                 default = nil)
  if valid_601561 != nil:
    section.add "X-Amz-Date", valid_601561
  var valid_601562 = header.getOrDefault("X-Amz-Security-Token")
  valid_601562 = validateParameter(valid_601562, JString, required = false,
                                 default = nil)
  if valid_601562 != nil:
    section.add "X-Amz-Security-Token", valid_601562
  var valid_601563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601563 = validateParameter(valid_601563, JString, required = false,
                                 default = nil)
  if valid_601563 != nil:
    section.add "X-Amz-Content-Sha256", valid_601563
  var valid_601564 = header.getOrDefault("X-Amz-Algorithm")
  valid_601564 = validateParameter(valid_601564, JString, required = false,
                                 default = nil)
  if valid_601564 != nil:
    section.add "X-Amz-Algorithm", valid_601564
  var valid_601565 = header.getOrDefault("X-Amz-Signature")
  valid_601565 = validateParameter(valid_601565, JString, required = false,
                                 default = nil)
  if valid_601565 != nil:
    section.add "X-Amz-Signature", valid_601565
  var valid_601566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601566 = validateParameter(valid_601566, JString, required = false,
                                 default = nil)
  if valid_601566 != nil:
    section.add "X-Amz-SignedHeaders", valid_601566
  var valid_601567 = header.getOrDefault("X-Amz-Credential")
  valid_601567 = validateParameter(valid_601567, JString, required = false,
                                 default = nil)
  if valid_601567 != nil:
    section.add "X-Amz-Credential", valid_601567
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListEndpointsByPlatformApplication action to retrieve additional records that are available after the first page results.
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  section = newJObject()
  var valid_601568 = formData.getOrDefault("NextToken")
  valid_601568 = validateParameter(valid_601568, JString, required = false,
                                 default = nil)
  if valid_601568 != nil:
    section.add "NextToken", valid_601568
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_601569 = formData.getOrDefault("PlatformApplicationArn")
  valid_601569 = validateParameter(valid_601569, JString, required = true,
                                 default = nil)
  if valid_601569 != nil:
    section.add "PlatformApplicationArn", valid_601569
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601570: Call_PostListEndpointsByPlatformApplication_601556;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as GCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_601570.validator(path, query, header, formData, body)
  let scheme = call_601570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601570.url(scheme.get, call_601570.host, call_601570.base,
                         call_601570.route, valid.getOrDefault("path"))
  result = hook(call_601570, url, valid)

proc call*(call_601571: Call_PostListEndpointsByPlatformApplication_601556;
          PlatformApplicationArn: string; NextToken: string = "";
          Action: string = "ListEndpointsByPlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## postListEndpointsByPlatformApplication
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as GCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListEndpointsByPlatformApplication action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  ##   Version: string (required)
  var query_601572 = newJObject()
  var formData_601573 = newJObject()
  add(formData_601573, "NextToken", newJString(NextToken))
  add(query_601572, "Action", newJString(Action))
  add(formData_601573, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(query_601572, "Version", newJString(Version))
  result = call_601571.call(nil, query_601572, nil, formData_601573, nil)

var postListEndpointsByPlatformApplication* = Call_PostListEndpointsByPlatformApplication_601556(
    name: "postListEndpointsByPlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com",
    route: "/#Action=ListEndpointsByPlatformApplication",
    validator: validate_PostListEndpointsByPlatformApplication_601557, base: "/",
    url: url_PostListEndpointsByPlatformApplication_601558,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListEndpointsByPlatformApplication_601539 = ref object of OpenApiRestCall_600426
proc url_GetListEndpointsByPlatformApplication_601541(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListEndpointsByPlatformApplication_601540(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as GCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListEndpointsByPlatformApplication action to retrieve additional records that are available after the first page results.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  section = newJObject()
  var valid_601542 = query.getOrDefault("NextToken")
  valid_601542 = validateParameter(valid_601542, JString, required = false,
                                 default = nil)
  if valid_601542 != nil:
    section.add "NextToken", valid_601542
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601543 = query.getOrDefault("Action")
  valid_601543 = validateParameter(valid_601543, JString, required = true, default = newJString(
      "ListEndpointsByPlatformApplication"))
  if valid_601543 != nil:
    section.add "Action", valid_601543
  var valid_601544 = query.getOrDefault("Version")
  valid_601544 = validateParameter(valid_601544, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601544 != nil:
    section.add "Version", valid_601544
  var valid_601545 = query.getOrDefault("PlatformApplicationArn")
  valid_601545 = validateParameter(valid_601545, JString, required = true,
                                 default = nil)
  if valid_601545 != nil:
    section.add "PlatformApplicationArn", valid_601545
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601546 = header.getOrDefault("X-Amz-Date")
  valid_601546 = validateParameter(valid_601546, JString, required = false,
                                 default = nil)
  if valid_601546 != nil:
    section.add "X-Amz-Date", valid_601546
  var valid_601547 = header.getOrDefault("X-Amz-Security-Token")
  valid_601547 = validateParameter(valid_601547, JString, required = false,
                                 default = nil)
  if valid_601547 != nil:
    section.add "X-Amz-Security-Token", valid_601547
  var valid_601548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601548 = validateParameter(valid_601548, JString, required = false,
                                 default = nil)
  if valid_601548 != nil:
    section.add "X-Amz-Content-Sha256", valid_601548
  var valid_601549 = header.getOrDefault("X-Amz-Algorithm")
  valid_601549 = validateParameter(valid_601549, JString, required = false,
                                 default = nil)
  if valid_601549 != nil:
    section.add "X-Amz-Algorithm", valid_601549
  var valid_601550 = header.getOrDefault("X-Amz-Signature")
  valid_601550 = validateParameter(valid_601550, JString, required = false,
                                 default = nil)
  if valid_601550 != nil:
    section.add "X-Amz-Signature", valid_601550
  var valid_601551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601551 = validateParameter(valid_601551, JString, required = false,
                                 default = nil)
  if valid_601551 != nil:
    section.add "X-Amz-SignedHeaders", valid_601551
  var valid_601552 = header.getOrDefault("X-Amz-Credential")
  valid_601552 = validateParameter(valid_601552, JString, required = false,
                                 default = nil)
  if valid_601552 != nil:
    section.add "X-Amz-Credential", valid_601552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601553: Call_GetListEndpointsByPlatformApplication_601539;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as GCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_601553.validator(path, query, header, formData, body)
  let scheme = call_601553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601553.url(scheme.get, call_601553.host, call_601553.base,
                         call_601553.route, valid.getOrDefault("path"))
  result = hook(call_601553, url, valid)

proc call*(call_601554: Call_GetListEndpointsByPlatformApplication_601539;
          PlatformApplicationArn: string; NextToken: string = "";
          Action: string = "ListEndpointsByPlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## getListEndpointsByPlatformApplication
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as GCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListEndpointsByPlatformApplication action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  var query_601555 = newJObject()
  add(query_601555, "NextToken", newJString(NextToken))
  add(query_601555, "Action", newJString(Action))
  add(query_601555, "Version", newJString(Version))
  add(query_601555, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_601554.call(nil, query_601555, nil, nil, nil)

var getListEndpointsByPlatformApplication* = Call_GetListEndpointsByPlatformApplication_601539(
    name: "getListEndpointsByPlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com",
    route: "/#Action=ListEndpointsByPlatformApplication",
    validator: validate_GetListEndpointsByPlatformApplication_601540, base: "/",
    url: url_GetListEndpointsByPlatformApplication_601541,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPhoneNumbersOptedOut_601590 = ref object of OpenApiRestCall_600426
proc url_PostListPhoneNumbersOptedOut_601592(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListPhoneNumbersOptedOut_601591(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601593 = query.getOrDefault("Action")
  valid_601593 = validateParameter(valid_601593, JString, required = true, default = newJString(
      "ListPhoneNumbersOptedOut"))
  if valid_601593 != nil:
    section.add "Action", valid_601593
  var valid_601594 = query.getOrDefault("Version")
  valid_601594 = validateParameter(valid_601594, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601594 != nil:
    section.add "Version", valid_601594
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601595 = header.getOrDefault("X-Amz-Date")
  valid_601595 = validateParameter(valid_601595, JString, required = false,
                                 default = nil)
  if valid_601595 != nil:
    section.add "X-Amz-Date", valid_601595
  var valid_601596 = header.getOrDefault("X-Amz-Security-Token")
  valid_601596 = validateParameter(valid_601596, JString, required = false,
                                 default = nil)
  if valid_601596 != nil:
    section.add "X-Amz-Security-Token", valid_601596
  var valid_601597 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601597 = validateParameter(valid_601597, JString, required = false,
                                 default = nil)
  if valid_601597 != nil:
    section.add "X-Amz-Content-Sha256", valid_601597
  var valid_601598 = header.getOrDefault("X-Amz-Algorithm")
  valid_601598 = validateParameter(valid_601598, JString, required = false,
                                 default = nil)
  if valid_601598 != nil:
    section.add "X-Amz-Algorithm", valid_601598
  var valid_601599 = header.getOrDefault("X-Amz-Signature")
  valid_601599 = validateParameter(valid_601599, JString, required = false,
                                 default = nil)
  if valid_601599 != nil:
    section.add "X-Amz-Signature", valid_601599
  var valid_601600 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601600 = validateParameter(valid_601600, JString, required = false,
                                 default = nil)
  if valid_601600 != nil:
    section.add "X-Amz-SignedHeaders", valid_601600
  var valid_601601 = header.getOrDefault("X-Amz-Credential")
  valid_601601 = validateParameter(valid_601601, JString, required = false,
                                 default = nil)
  if valid_601601 != nil:
    section.add "X-Amz-Credential", valid_601601
  result.add "header", section
  ## parameters in `formData` object:
  ##   nextToken: JString
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  section = newJObject()
  var valid_601602 = formData.getOrDefault("nextToken")
  valid_601602 = validateParameter(valid_601602, JString, required = false,
                                 default = nil)
  if valid_601602 != nil:
    section.add "nextToken", valid_601602
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601603: Call_PostListPhoneNumbersOptedOut_601590; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ## 
  let valid = call_601603.validator(path, query, header, formData, body)
  let scheme = call_601603.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601603.url(scheme.get, call_601603.host, call_601603.base,
                         call_601603.route, valid.getOrDefault("path"))
  result = hook(call_601603, url, valid)

proc call*(call_601604: Call_PostListPhoneNumbersOptedOut_601590;
          Action: string = "ListPhoneNumbersOptedOut"; nextToken: string = "";
          Version: string = "2010-03-31"): Recallable =
  ## postListPhoneNumbersOptedOut
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ##   Action: string (required)
  ##   nextToken: string
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  ##   Version: string (required)
  var query_601605 = newJObject()
  var formData_601606 = newJObject()
  add(query_601605, "Action", newJString(Action))
  add(formData_601606, "nextToken", newJString(nextToken))
  add(query_601605, "Version", newJString(Version))
  result = call_601604.call(nil, query_601605, nil, formData_601606, nil)

var postListPhoneNumbersOptedOut* = Call_PostListPhoneNumbersOptedOut_601590(
    name: "postListPhoneNumbersOptedOut", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListPhoneNumbersOptedOut",
    validator: validate_PostListPhoneNumbersOptedOut_601591, base: "/",
    url: url_PostListPhoneNumbersOptedOut_601592,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPhoneNumbersOptedOut_601574 = ref object of OpenApiRestCall_600426
proc url_GetListPhoneNumbersOptedOut_601576(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListPhoneNumbersOptedOut_601575(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_601577 = query.getOrDefault("nextToken")
  valid_601577 = validateParameter(valid_601577, JString, required = false,
                                 default = nil)
  if valid_601577 != nil:
    section.add "nextToken", valid_601577
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601578 = query.getOrDefault("Action")
  valid_601578 = validateParameter(valid_601578, JString, required = true, default = newJString(
      "ListPhoneNumbersOptedOut"))
  if valid_601578 != nil:
    section.add "Action", valid_601578
  var valid_601579 = query.getOrDefault("Version")
  valid_601579 = validateParameter(valid_601579, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601579 != nil:
    section.add "Version", valid_601579
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601580 = header.getOrDefault("X-Amz-Date")
  valid_601580 = validateParameter(valid_601580, JString, required = false,
                                 default = nil)
  if valid_601580 != nil:
    section.add "X-Amz-Date", valid_601580
  var valid_601581 = header.getOrDefault("X-Amz-Security-Token")
  valid_601581 = validateParameter(valid_601581, JString, required = false,
                                 default = nil)
  if valid_601581 != nil:
    section.add "X-Amz-Security-Token", valid_601581
  var valid_601582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601582 = validateParameter(valid_601582, JString, required = false,
                                 default = nil)
  if valid_601582 != nil:
    section.add "X-Amz-Content-Sha256", valid_601582
  var valid_601583 = header.getOrDefault("X-Amz-Algorithm")
  valid_601583 = validateParameter(valid_601583, JString, required = false,
                                 default = nil)
  if valid_601583 != nil:
    section.add "X-Amz-Algorithm", valid_601583
  var valid_601584 = header.getOrDefault("X-Amz-Signature")
  valid_601584 = validateParameter(valid_601584, JString, required = false,
                                 default = nil)
  if valid_601584 != nil:
    section.add "X-Amz-Signature", valid_601584
  var valid_601585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601585 = validateParameter(valid_601585, JString, required = false,
                                 default = nil)
  if valid_601585 != nil:
    section.add "X-Amz-SignedHeaders", valid_601585
  var valid_601586 = header.getOrDefault("X-Amz-Credential")
  valid_601586 = validateParameter(valid_601586, JString, required = false,
                                 default = nil)
  if valid_601586 != nil:
    section.add "X-Amz-Credential", valid_601586
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601587: Call_GetListPhoneNumbersOptedOut_601574; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ## 
  let valid = call_601587.validator(path, query, header, formData, body)
  let scheme = call_601587.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601587.url(scheme.get, call_601587.host, call_601587.base,
                         call_601587.route, valid.getOrDefault("path"))
  result = hook(call_601587, url, valid)

proc call*(call_601588: Call_GetListPhoneNumbersOptedOut_601574;
          nextToken: string = ""; Action: string = "ListPhoneNumbersOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## getListPhoneNumbersOptedOut
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ##   nextToken: string
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601589 = newJObject()
  add(query_601589, "nextToken", newJString(nextToken))
  add(query_601589, "Action", newJString(Action))
  add(query_601589, "Version", newJString(Version))
  result = call_601588.call(nil, query_601589, nil, nil, nil)

var getListPhoneNumbersOptedOut* = Call_GetListPhoneNumbersOptedOut_601574(
    name: "getListPhoneNumbersOptedOut", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListPhoneNumbersOptedOut",
    validator: validate_GetListPhoneNumbersOptedOut_601575, base: "/",
    url: url_GetListPhoneNumbersOptedOut_601576,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPlatformApplications_601623 = ref object of OpenApiRestCall_600426
proc url_PostListPlatformApplications_601625(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListPlatformApplications_601624(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and GCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601626 = query.getOrDefault("Action")
  valid_601626 = validateParameter(valid_601626, JString, required = true, default = newJString(
      "ListPlatformApplications"))
  if valid_601626 != nil:
    section.add "Action", valid_601626
  var valid_601627 = query.getOrDefault("Version")
  valid_601627 = validateParameter(valid_601627, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601627 != nil:
    section.add "Version", valid_601627
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601628 = header.getOrDefault("X-Amz-Date")
  valid_601628 = validateParameter(valid_601628, JString, required = false,
                                 default = nil)
  if valid_601628 != nil:
    section.add "X-Amz-Date", valid_601628
  var valid_601629 = header.getOrDefault("X-Amz-Security-Token")
  valid_601629 = validateParameter(valid_601629, JString, required = false,
                                 default = nil)
  if valid_601629 != nil:
    section.add "X-Amz-Security-Token", valid_601629
  var valid_601630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601630 = validateParameter(valid_601630, JString, required = false,
                                 default = nil)
  if valid_601630 != nil:
    section.add "X-Amz-Content-Sha256", valid_601630
  var valid_601631 = header.getOrDefault("X-Amz-Algorithm")
  valid_601631 = validateParameter(valid_601631, JString, required = false,
                                 default = nil)
  if valid_601631 != nil:
    section.add "X-Amz-Algorithm", valid_601631
  var valid_601632 = header.getOrDefault("X-Amz-Signature")
  valid_601632 = validateParameter(valid_601632, JString, required = false,
                                 default = nil)
  if valid_601632 != nil:
    section.add "X-Amz-Signature", valid_601632
  var valid_601633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601633 = validateParameter(valid_601633, JString, required = false,
                                 default = nil)
  if valid_601633 != nil:
    section.add "X-Amz-SignedHeaders", valid_601633
  var valid_601634 = header.getOrDefault("X-Amz-Credential")
  valid_601634 = validateParameter(valid_601634, JString, required = false,
                                 default = nil)
  if valid_601634 != nil:
    section.add "X-Amz-Credential", valid_601634
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  section = newJObject()
  var valid_601635 = formData.getOrDefault("NextToken")
  valid_601635 = validateParameter(valid_601635, JString, required = false,
                                 default = nil)
  if valid_601635 != nil:
    section.add "NextToken", valid_601635
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601636: Call_PostListPlatformApplications_601623; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and GCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  let valid = call_601636.validator(path, query, header, formData, body)
  let scheme = call_601636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601636.url(scheme.get, call_601636.host, call_601636.base,
                         call_601636.route, valid.getOrDefault("path"))
  result = hook(call_601636, url, valid)

proc call*(call_601637: Call_PostListPlatformApplications_601623;
          NextToken: string = ""; Action: string = "ListPlatformApplications";
          Version: string = "2010-03-31"): Recallable =
  ## postListPlatformApplications
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and GCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601638 = newJObject()
  var formData_601639 = newJObject()
  add(formData_601639, "NextToken", newJString(NextToken))
  add(query_601638, "Action", newJString(Action))
  add(query_601638, "Version", newJString(Version))
  result = call_601637.call(nil, query_601638, nil, formData_601639, nil)

var postListPlatformApplications* = Call_PostListPlatformApplications_601623(
    name: "postListPlatformApplications", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListPlatformApplications",
    validator: validate_PostListPlatformApplications_601624, base: "/",
    url: url_PostListPlatformApplications_601625,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPlatformApplications_601607 = ref object of OpenApiRestCall_600426
proc url_GetListPlatformApplications_601609(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListPlatformApplications_601608(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and GCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_601610 = query.getOrDefault("NextToken")
  valid_601610 = validateParameter(valid_601610, JString, required = false,
                                 default = nil)
  if valid_601610 != nil:
    section.add "NextToken", valid_601610
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601611 = query.getOrDefault("Action")
  valid_601611 = validateParameter(valid_601611, JString, required = true, default = newJString(
      "ListPlatformApplications"))
  if valid_601611 != nil:
    section.add "Action", valid_601611
  var valid_601612 = query.getOrDefault("Version")
  valid_601612 = validateParameter(valid_601612, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601612 != nil:
    section.add "Version", valid_601612
  result.add "query", section
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
  if body != nil:
    result.add "body", body

proc call*(call_601620: Call_GetListPlatformApplications_601607; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and GCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  let valid = call_601620.validator(path, query, header, formData, body)
  let scheme = call_601620.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601620.url(scheme.get, call_601620.host, call_601620.base,
                         call_601620.route, valid.getOrDefault("path"))
  result = hook(call_601620, url, valid)

proc call*(call_601621: Call_GetListPlatformApplications_601607;
          NextToken: string = ""; Action: string = "ListPlatformApplications";
          Version: string = "2010-03-31"): Recallable =
  ## getListPlatformApplications
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and GCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601622 = newJObject()
  add(query_601622, "NextToken", newJString(NextToken))
  add(query_601622, "Action", newJString(Action))
  add(query_601622, "Version", newJString(Version))
  result = call_601621.call(nil, query_601622, nil, nil, nil)

var getListPlatformApplications* = Call_GetListPlatformApplications_601607(
    name: "getListPlatformApplications", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListPlatformApplications",
    validator: validate_GetListPlatformApplications_601608, base: "/",
    url: url_GetListPlatformApplications_601609,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListSubscriptions_601656 = ref object of OpenApiRestCall_600426
proc url_PostListSubscriptions_601658(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListSubscriptions_601657(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601659 = query.getOrDefault("Action")
  valid_601659 = validateParameter(valid_601659, JString, required = true,
                                 default = newJString("ListSubscriptions"))
  if valid_601659 != nil:
    section.add "Action", valid_601659
  var valid_601660 = query.getOrDefault("Version")
  valid_601660 = validateParameter(valid_601660, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601660 != nil:
    section.add "Version", valid_601660
  result.add "query", section
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
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  section = newJObject()
  var valid_601668 = formData.getOrDefault("NextToken")
  valid_601668 = validateParameter(valid_601668, JString, required = false,
                                 default = nil)
  if valid_601668 != nil:
    section.add "NextToken", valid_601668
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601669: Call_PostListSubscriptions_601656; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_601669.validator(path, query, header, formData, body)
  let scheme = call_601669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601669.url(scheme.get, call_601669.host, call_601669.base,
                         call_601669.route, valid.getOrDefault("path"))
  result = hook(call_601669, url, valid)

proc call*(call_601670: Call_PostListSubscriptions_601656; NextToken: string = "";
          Action: string = "ListSubscriptions"; Version: string = "2010-03-31"): Recallable =
  ## postListSubscriptions
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601671 = newJObject()
  var formData_601672 = newJObject()
  add(formData_601672, "NextToken", newJString(NextToken))
  add(query_601671, "Action", newJString(Action))
  add(query_601671, "Version", newJString(Version))
  result = call_601670.call(nil, query_601671, nil, formData_601672, nil)

var postListSubscriptions* = Call_PostListSubscriptions_601656(
    name: "postListSubscriptions", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptions",
    validator: validate_PostListSubscriptions_601657, base: "/",
    url: url_PostListSubscriptions_601658, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListSubscriptions_601640 = ref object of OpenApiRestCall_600426
proc url_GetListSubscriptions_601642(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListSubscriptions_601641(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_601643 = query.getOrDefault("NextToken")
  valid_601643 = validateParameter(valid_601643, JString, required = false,
                                 default = nil)
  if valid_601643 != nil:
    section.add "NextToken", valid_601643
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601644 = query.getOrDefault("Action")
  valid_601644 = validateParameter(valid_601644, JString, required = true,
                                 default = newJString("ListSubscriptions"))
  if valid_601644 != nil:
    section.add "Action", valid_601644
  var valid_601645 = query.getOrDefault("Version")
  valid_601645 = validateParameter(valid_601645, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601645 != nil:
    section.add "Version", valid_601645
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601646 = header.getOrDefault("X-Amz-Date")
  valid_601646 = validateParameter(valid_601646, JString, required = false,
                                 default = nil)
  if valid_601646 != nil:
    section.add "X-Amz-Date", valid_601646
  var valid_601647 = header.getOrDefault("X-Amz-Security-Token")
  valid_601647 = validateParameter(valid_601647, JString, required = false,
                                 default = nil)
  if valid_601647 != nil:
    section.add "X-Amz-Security-Token", valid_601647
  var valid_601648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601648 = validateParameter(valid_601648, JString, required = false,
                                 default = nil)
  if valid_601648 != nil:
    section.add "X-Amz-Content-Sha256", valid_601648
  var valid_601649 = header.getOrDefault("X-Amz-Algorithm")
  valid_601649 = validateParameter(valid_601649, JString, required = false,
                                 default = nil)
  if valid_601649 != nil:
    section.add "X-Amz-Algorithm", valid_601649
  var valid_601650 = header.getOrDefault("X-Amz-Signature")
  valid_601650 = validateParameter(valid_601650, JString, required = false,
                                 default = nil)
  if valid_601650 != nil:
    section.add "X-Amz-Signature", valid_601650
  var valid_601651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601651 = validateParameter(valid_601651, JString, required = false,
                                 default = nil)
  if valid_601651 != nil:
    section.add "X-Amz-SignedHeaders", valid_601651
  var valid_601652 = header.getOrDefault("X-Amz-Credential")
  valid_601652 = validateParameter(valid_601652, JString, required = false,
                                 default = nil)
  if valid_601652 != nil:
    section.add "X-Amz-Credential", valid_601652
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601653: Call_GetListSubscriptions_601640; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_601653.validator(path, query, header, formData, body)
  let scheme = call_601653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601653.url(scheme.get, call_601653.host, call_601653.base,
                         call_601653.route, valid.getOrDefault("path"))
  result = hook(call_601653, url, valid)

proc call*(call_601654: Call_GetListSubscriptions_601640; NextToken: string = "";
          Action: string = "ListSubscriptions"; Version: string = "2010-03-31"): Recallable =
  ## getListSubscriptions
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601655 = newJObject()
  add(query_601655, "NextToken", newJString(NextToken))
  add(query_601655, "Action", newJString(Action))
  add(query_601655, "Version", newJString(Version))
  result = call_601654.call(nil, query_601655, nil, nil, nil)

var getListSubscriptions* = Call_GetListSubscriptions_601640(
    name: "getListSubscriptions", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptions",
    validator: validate_GetListSubscriptions_601641, base: "/",
    url: url_GetListSubscriptions_601642, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListSubscriptionsByTopic_601690 = ref object of OpenApiRestCall_600426
proc url_PostListSubscriptionsByTopic_601692(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListSubscriptionsByTopic_601691(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601693 = query.getOrDefault("Action")
  valid_601693 = validateParameter(valid_601693, JString, required = true, default = newJString(
      "ListSubscriptionsByTopic"))
  if valid_601693 != nil:
    section.add "Action", valid_601693
  var valid_601694 = query.getOrDefault("Version")
  valid_601694 = validateParameter(valid_601694, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601694 != nil:
    section.add "Version", valid_601694
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601695 = header.getOrDefault("X-Amz-Date")
  valid_601695 = validateParameter(valid_601695, JString, required = false,
                                 default = nil)
  if valid_601695 != nil:
    section.add "X-Amz-Date", valid_601695
  var valid_601696 = header.getOrDefault("X-Amz-Security-Token")
  valid_601696 = validateParameter(valid_601696, JString, required = false,
                                 default = nil)
  if valid_601696 != nil:
    section.add "X-Amz-Security-Token", valid_601696
  var valid_601697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601697 = validateParameter(valid_601697, JString, required = false,
                                 default = nil)
  if valid_601697 != nil:
    section.add "X-Amz-Content-Sha256", valid_601697
  var valid_601698 = header.getOrDefault("X-Amz-Algorithm")
  valid_601698 = validateParameter(valid_601698, JString, required = false,
                                 default = nil)
  if valid_601698 != nil:
    section.add "X-Amz-Algorithm", valid_601698
  var valid_601699 = header.getOrDefault("X-Amz-Signature")
  valid_601699 = validateParameter(valid_601699, JString, required = false,
                                 default = nil)
  if valid_601699 != nil:
    section.add "X-Amz-Signature", valid_601699
  var valid_601700 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601700 = validateParameter(valid_601700, JString, required = false,
                                 default = nil)
  if valid_601700 != nil:
    section.add "X-Amz-SignedHeaders", valid_601700
  var valid_601701 = header.getOrDefault("X-Amz-Credential")
  valid_601701 = validateParameter(valid_601701, JString, required = false,
                                 default = nil)
  if valid_601701 != nil:
    section.add "X-Amz-Credential", valid_601701
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListSubscriptionsByTopic</code> request.
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic for which you wish to find subscriptions.
  section = newJObject()
  var valid_601702 = formData.getOrDefault("NextToken")
  valid_601702 = validateParameter(valid_601702, JString, required = false,
                                 default = nil)
  if valid_601702 != nil:
    section.add "NextToken", valid_601702
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_601703 = formData.getOrDefault("TopicArn")
  valid_601703 = validateParameter(valid_601703, JString, required = true,
                                 default = nil)
  if valid_601703 != nil:
    section.add "TopicArn", valid_601703
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601704: Call_PostListSubscriptionsByTopic_601690; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_601704.validator(path, query, header, formData, body)
  let scheme = call_601704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601704.url(scheme.get, call_601704.host, call_601704.base,
                         call_601704.route, valid.getOrDefault("path"))
  result = hook(call_601704, url, valid)

proc call*(call_601705: Call_PostListSubscriptionsByTopic_601690; TopicArn: string;
          NextToken: string = ""; Action: string = "ListSubscriptionsByTopic";
          Version: string = "2010-03-31"): Recallable =
  ## postListSubscriptionsByTopic
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptionsByTopic</code> request.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic for which you wish to find subscriptions.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601706 = newJObject()
  var formData_601707 = newJObject()
  add(formData_601707, "NextToken", newJString(NextToken))
  add(formData_601707, "TopicArn", newJString(TopicArn))
  add(query_601706, "Action", newJString(Action))
  add(query_601706, "Version", newJString(Version))
  result = call_601705.call(nil, query_601706, nil, formData_601707, nil)

var postListSubscriptionsByTopic* = Call_PostListSubscriptionsByTopic_601690(
    name: "postListSubscriptionsByTopic", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptionsByTopic",
    validator: validate_PostListSubscriptionsByTopic_601691, base: "/",
    url: url_PostListSubscriptionsByTopic_601692,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListSubscriptionsByTopic_601673 = ref object of OpenApiRestCall_600426
proc url_GetListSubscriptionsByTopic_601675(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListSubscriptionsByTopic_601674(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListSubscriptionsByTopic</code> request.
  ##   Action: JString (required)
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic for which you wish to find subscriptions.
  ##   Version: JString (required)
  section = newJObject()
  var valid_601676 = query.getOrDefault("NextToken")
  valid_601676 = validateParameter(valid_601676, JString, required = false,
                                 default = nil)
  if valid_601676 != nil:
    section.add "NextToken", valid_601676
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601677 = query.getOrDefault("Action")
  valid_601677 = validateParameter(valid_601677, JString, required = true, default = newJString(
      "ListSubscriptionsByTopic"))
  if valid_601677 != nil:
    section.add "Action", valid_601677
  var valid_601678 = query.getOrDefault("TopicArn")
  valid_601678 = validateParameter(valid_601678, JString, required = true,
                                 default = nil)
  if valid_601678 != nil:
    section.add "TopicArn", valid_601678
  var valid_601679 = query.getOrDefault("Version")
  valid_601679 = validateParameter(valid_601679, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601679 != nil:
    section.add "Version", valid_601679
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601680 = header.getOrDefault("X-Amz-Date")
  valid_601680 = validateParameter(valid_601680, JString, required = false,
                                 default = nil)
  if valid_601680 != nil:
    section.add "X-Amz-Date", valid_601680
  var valid_601681 = header.getOrDefault("X-Amz-Security-Token")
  valid_601681 = validateParameter(valid_601681, JString, required = false,
                                 default = nil)
  if valid_601681 != nil:
    section.add "X-Amz-Security-Token", valid_601681
  var valid_601682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601682 = validateParameter(valid_601682, JString, required = false,
                                 default = nil)
  if valid_601682 != nil:
    section.add "X-Amz-Content-Sha256", valid_601682
  var valid_601683 = header.getOrDefault("X-Amz-Algorithm")
  valid_601683 = validateParameter(valid_601683, JString, required = false,
                                 default = nil)
  if valid_601683 != nil:
    section.add "X-Amz-Algorithm", valid_601683
  var valid_601684 = header.getOrDefault("X-Amz-Signature")
  valid_601684 = validateParameter(valid_601684, JString, required = false,
                                 default = nil)
  if valid_601684 != nil:
    section.add "X-Amz-Signature", valid_601684
  var valid_601685 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601685 = validateParameter(valid_601685, JString, required = false,
                                 default = nil)
  if valid_601685 != nil:
    section.add "X-Amz-SignedHeaders", valid_601685
  var valid_601686 = header.getOrDefault("X-Amz-Credential")
  valid_601686 = validateParameter(valid_601686, JString, required = false,
                                 default = nil)
  if valid_601686 != nil:
    section.add "X-Amz-Credential", valid_601686
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601687: Call_GetListSubscriptionsByTopic_601673; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_601687.validator(path, query, header, formData, body)
  let scheme = call_601687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601687.url(scheme.get, call_601687.host, call_601687.base,
                         call_601687.route, valid.getOrDefault("path"))
  result = hook(call_601687, url, valid)

proc call*(call_601688: Call_GetListSubscriptionsByTopic_601673; TopicArn: string;
          NextToken: string = ""; Action: string = "ListSubscriptionsByTopic";
          Version: string = "2010-03-31"): Recallable =
  ## getListSubscriptionsByTopic
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptionsByTopic</code> request.
  ##   Action: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic for which you wish to find subscriptions.
  ##   Version: string (required)
  var query_601689 = newJObject()
  add(query_601689, "NextToken", newJString(NextToken))
  add(query_601689, "Action", newJString(Action))
  add(query_601689, "TopicArn", newJString(TopicArn))
  add(query_601689, "Version", newJString(Version))
  result = call_601688.call(nil, query_601689, nil, nil, nil)

var getListSubscriptionsByTopic* = Call_GetListSubscriptionsByTopic_601673(
    name: "getListSubscriptionsByTopic", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptionsByTopic",
    validator: validate_GetListSubscriptionsByTopic_601674, base: "/",
    url: url_GetListSubscriptionsByTopic_601675,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_601724 = ref object of OpenApiRestCall_600426
proc url_PostListTagsForResource_601726(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListTagsForResource_601725(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601727 = query.getOrDefault("Action")
  valid_601727 = validateParameter(valid_601727, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_601727 != nil:
    section.add "Action", valid_601727
  var valid_601728 = query.getOrDefault("Version")
  valid_601728 = validateParameter(valid_601728, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601728 != nil:
    section.add "Version", valid_601728
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601729 = header.getOrDefault("X-Amz-Date")
  valid_601729 = validateParameter(valid_601729, JString, required = false,
                                 default = nil)
  if valid_601729 != nil:
    section.add "X-Amz-Date", valid_601729
  var valid_601730 = header.getOrDefault("X-Amz-Security-Token")
  valid_601730 = validateParameter(valid_601730, JString, required = false,
                                 default = nil)
  if valid_601730 != nil:
    section.add "X-Amz-Security-Token", valid_601730
  var valid_601731 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601731 = validateParameter(valid_601731, JString, required = false,
                                 default = nil)
  if valid_601731 != nil:
    section.add "X-Amz-Content-Sha256", valid_601731
  var valid_601732 = header.getOrDefault("X-Amz-Algorithm")
  valid_601732 = validateParameter(valid_601732, JString, required = false,
                                 default = nil)
  if valid_601732 != nil:
    section.add "X-Amz-Algorithm", valid_601732
  var valid_601733 = header.getOrDefault("X-Amz-Signature")
  valid_601733 = validateParameter(valid_601733, JString, required = false,
                                 default = nil)
  if valid_601733 != nil:
    section.add "X-Amz-Signature", valid_601733
  var valid_601734 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601734 = validateParameter(valid_601734, JString, required = false,
                                 default = nil)
  if valid_601734 != nil:
    section.add "X-Amz-SignedHeaders", valid_601734
  var valid_601735 = header.getOrDefault("X-Amz-Credential")
  valid_601735 = validateParameter(valid_601735, JString, required = false,
                                 default = nil)
  if valid_601735 != nil:
    section.add "X-Amz-Credential", valid_601735
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic for which to list tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_601736 = formData.getOrDefault("ResourceArn")
  valid_601736 = validateParameter(valid_601736, JString, required = true,
                                 default = nil)
  if valid_601736 != nil:
    section.add "ResourceArn", valid_601736
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601737: Call_PostListTagsForResource_601724; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ## 
  let valid = call_601737.validator(path, query, header, formData, body)
  let scheme = call_601737.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601737.url(scheme.get, call_601737.host, call_601737.base,
                         call_601737.route, valid.getOrDefault("path"))
  result = hook(call_601737, url, valid)

proc call*(call_601738: Call_PostListTagsForResource_601724; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-03-31"): Recallable =
  ## postListTagsForResource
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ##   Action: string (required)
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic for which to list tags.
  ##   Version: string (required)
  var query_601739 = newJObject()
  var formData_601740 = newJObject()
  add(query_601739, "Action", newJString(Action))
  add(formData_601740, "ResourceArn", newJString(ResourceArn))
  add(query_601739, "Version", newJString(Version))
  result = call_601738.call(nil, query_601739, nil, formData_601740, nil)

var postListTagsForResource* = Call_PostListTagsForResource_601724(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_601725, base: "/",
    url: url_PostListTagsForResource_601726, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_601708 = ref object of OpenApiRestCall_600426
proc url_GetListTagsForResource_601710(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListTagsForResource_601709(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic for which to list tags.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceArn` field"
  var valid_601711 = query.getOrDefault("ResourceArn")
  valid_601711 = validateParameter(valid_601711, JString, required = true,
                                 default = nil)
  if valid_601711 != nil:
    section.add "ResourceArn", valid_601711
  var valid_601712 = query.getOrDefault("Action")
  valid_601712 = validateParameter(valid_601712, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_601712 != nil:
    section.add "Action", valid_601712
  var valid_601713 = query.getOrDefault("Version")
  valid_601713 = validateParameter(valid_601713, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601713 != nil:
    section.add "Version", valid_601713
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601714 = header.getOrDefault("X-Amz-Date")
  valid_601714 = validateParameter(valid_601714, JString, required = false,
                                 default = nil)
  if valid_601714 != nil:
    section.add "X-Amz-Date", valid_601714
  var valid_601715 = header.getOrDefault("X-Amz-Security-Token")
  valid_601715 = validateParameter(valid_601715, JString, required = false,
                                 default = nil)
  if valid_601715 != nil:
    section.add "X-Amz-Security-Token", valid_601715
  var valid_601716 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601716 = validateParameter(valid_601716, JString, required = false,
                                 default = nil)
  if valid_601716 != nil:
    section.add "X-Amz-Content-Sha256", valid_601716
  var valid_601717 = header.getOrDefault("X-Amz-Algorithm")
  valid_601717 = validateParameter(valid_601717, JString, required = false,
                                 default = nil)
  if valid_601717 != nil:
    section.add "X-Amz-Algorithm", valid_601717
  var valid_601718 = header.getOrDefault("X-Amz-Signature")
  valid_601718 = validateParameter(valid_601718, JString, required = false,
                                 default = nil)
  if valid_601718 != nil:
    section.add "X-Amz-Signature", valid_601718
  var valid_601719 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601719 = validateParameter(valid_601719, JString, required = false,
                                 default = nil)
  if valid_601719 != nil:
    section.add "X-Amz-SignedHeaders", valid_601719
  var valid_601720 = header.getOrDefault("X-Amz-Credential")
  valid_601720 = validateParameter(valid_601720, JString, required = false,
                                 default = nil)
  if valid_601720 != nil:
    section.add "X-Amz-Credential", valid_601720
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601721: Call_GetListTagsForResource_601708; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ## 
  let valid = call_601721.validator(path, query, header, formData, body)
  let scheme = call_601721.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601721.url(scheme.get, call_601721.host, call_601721.base,
                         call_601721.route, valid.getOrDefault("path"))
  result = hook(call_601721, url, valid)

proc call*(call_601722: Call_GetListTagsForResource_601708; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-03-31"): Recallable =
  ## getListTagsForResource
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic for which to list tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601723 = newJObject()
  add(query_601723, "ResourceArn", newJString(ResourceArn))
  add(query_601723, "Action", newJString(Action))
  add(query_601723, "Version", newJString(Version))
  result = call_601722.call(nil, query_601723, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_601708(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_601709, base: "/",
    url: url_GetListTagsForResource_601710, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTopics_601757 = ref object of OpenApiRestCall_600426
proc url_PostListTopics_601759(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListTopics_601758(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601760 = query.getOrDefault("Action")
  valid_601760 = validateParameter(valid_601760, JString, required = true,
                                 default = newJString("ListTopics"))
  if valid_601760 != nil:
    section.add "Action", valid_601760
  var valid_601761 = query.getOrDefault("Version")
  valid_601761 = validateParameter(valid_601761, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601761 != nil:
    section.add "Version", valid_601761
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601762 = header.getOrDefault("X-Amz-Date")
  valid_601762 = validateParameter(valid_601762, JString, required = false,
                                 default = nil)
  if valid_601762 != nil:
    section.add "X-Amz-Date", valid_601762
  var valid_601763 = header.getOrDefault("X-Amz-Security-Token")
  valid_601763 = validateParameter(valid_601763, JString, required = false,
                                 default = nil)
  if valid_601763 != nil:
    section.add "X-Amz-Security-Token", valid_601763
  var valid_601764 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601764 = validateParameter(valid_601764, JString, required = false,
                                 default = nil)
  if valid_601764 != nil:
    section.add "X-Amz-Content-Sha256", valid_601764
  var valid_601765 = header.getOrDefault("X-Amz-Algorithm")
  valid_601765 = validateParameter(valid_601765, JString, required = false,
                                 default = nil)
  if valid_601765 != nil:
    section.add "X-Amz-Algorithm", valid_601765
  var valid_601766 = header.getOrDefault("X-Amz-Signature")
  valid_601766 = validateParameter(valid_601766, JString, required = false,
                                 default = nil)
  if valid_601766 != nil:
    section.add "X-Amz-Signature", valid_601766
  var valid_601767 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601767 = validateParameter(valid_601767, JString, required = false,
                                 default = nil)
  if valid_601767 != nil:
    section.add "X-Amz-SignedHeaders", valid_601767
  var valid_601768 = header.getOrDefault("X-Amz-Credential")
  valid_601768 = validateParameter(valid_601768, JString, required = false,
                                 default = nil)
  if valid_601768 != nil:
    section.add "X-Amz-Credential", valid_601768
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListTopics</code> request.
  section = newJObject()
  var valid_601769 = formData.getOrDefault("NextToken")
  valid_601769 = validateParameter(valid_601769, JString, required = false,
                                 default = nil)
  if valid_601769 != nil:
    section.add "NextToken", valid_601769
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601770: Call_PostListTopics_601757; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_601770.validator(path, query, header, formData, body)
  let scheme = call_601770.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601770.url(scheme.get, call_601770.host, call_601770.base,
                         call_601770.route, valid.getOrDefault("path"))
  result = hook(call_601770, url, valid)

proc call*(call_601771: Call_PostListTopics_601757; NextToken: string = "";
          Action: string = "ListTopics"; Version: string = "2010-03-31"): Recallable =
  ## postListTopics
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListTopics</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601772 = newJObject()
  var formData_601773 = newJObject()
  add(formData_601773, "NextToken", newJString(NextToken))
  add(query_601772, "Action", newJString(Action))
  add(query_601772, "Version", newJString(Version))
  result = call_601771.call(nil, query_601772, nil, formData_601773, nil)

var postListTopics* = Call_PostListTopics_601757(name: "postListTopics",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=ListTopics", validator: validate_PostListTopics_601758,
    base: "/", url: url_PostListTopics_601759, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTopics_601741 = ref object of OpenApiRestCall_600426
proc url_GetListTopics_601743(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListTopics_601742(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListTopics</code> request.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_601744 = query.getOrDefault("NextToken")
  valid_601744 = validateParameter(valid_601744, JString, required = false,
                                 default = nil)
  if valid_601744 != nil:
    section.add "NextToken", valid_601744
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601745 = query.getOrDefault("Action")
  valid_601745 = validateParameter(valid_601745, JString, required = true,
                                 default = newJString("ListTopics"))
  if valid_601745 != nil:
    section.add "Action", valid_601745
  var valid_601746 = query.getOrDefault("Version")
  valid_601746 = validateParameter(valid_601746, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601746 != nil:
    section.add "Version", valid_601746
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601747 = header.getOrDefault("X-Amz-Date")
  valid_601747 = validateParameter(valid_601747, JString, required = false,
                                 default = nil)
  if valid_601747 != nil:
    section.add "X-Amz-Date", valid_601747
  var valid_601748 = header.getOrDefault("X-Amz-Security-Token")
  valid_601748 = validateParameter(valid_601748, JString, required = false,
                                 default = nil)
  if valid_601748 != nil:
    section.add "X-Amz-Security-Token", valid_601748
  var valid_601749 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601749 = validateParameter(valid_601749, JString, required = false,
                                 default = nil)
  if valid_601749 != nil:
    section.add "X-Amz-Content-Sha256", valid_601749
  var valid_601750 = header.getOrDefault("X-Amz-Algorithm")
  valid_601750 = validateParameter(valid_601750, JString, required = false,
                                 default = nil)
  if valid_601750 != nil:
    section.add "X-Amz-Algorithm", valid_601750
  var valid_601751 = header.getOrDefault("X-Amz-Signature")
  valid_601751 = validateParameter(valid_601751, JString, required = false,
                                 default = nil)
  if valid_601751 != nil:
    section.add "X-Amz-Signature", valid_601751
  var valid_601752 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601752 = validateParameter(valid_601752, JString, required = false,
                                 default = nil)
  if valid_601752 != nil:
    section.add "X-Amz-SignedHeaders", valid_601752
  var valid_601753 = header.getOrDefault("X-Amz-Credential")
  valid_601753 = validateParameter(valid_601753, JString, required = false,
                                 default = nil)
  if valid_601753 != nil:
    section.add "X-Amz-Credential", valid_601753
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601754: Call_GetListTopics_601741; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_601754.validator(path, query, header, formData, body)
  let scheme = call_601754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601754.url(scheme.get, call_601754.host, call_601754.base,
                         call_601754.route, valid.getOrDefault("path"))
  result = hook(call_601754, url, valid)

proc call*(call_601755: Call_GetListTopics_601741; NextToken: string = "";
          Action: string = "ListTopics"; Version: string = "2010-03-31"): Recallable =
  ## getListTopics
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListTopics</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601756 = newJObject()
  add(query_601756, "NextToken", newJString(NextToken))
  add(query_601756, "Action", newJString(Action))
  add(query_601756, "Version", newJString(Version))
  result = call_601755.call(nil, query_601756, nil, nil, nil)

var getListTopics* = Call_GetListTopics_601741(name: "getListTopics",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=ListTopics", validator: validate_GetListTopics_601742,
    base: "/", url: url_GetListTopics_601743, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostOptInPhoneNumber_601790 = ref object of OpenApiRestCall_600426
proc url_PostOptInPhoneNumber_601792(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostOptInPhoneNumber_601791(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601793 = query.getOrDefault("Action")
  valid_601793 = validateParameter(valid_601793, JString, required = true,
                                 default = newJString("OptInPhoneNumber"))
  if valid_601793 != nil:
    section.add "Action", valid_601793
  var valid_601794 = query.getOrDefault("Version")
  valid_601794 = validateParameter(valid_601794, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601794 != nil:
    section.add "Version", valid_601794
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601795 = header.getOrDefault("X-Amz-Date")
  valid_601795 = validateParameter(valid_601795, JString, required = false,
                                 default = nil)
  if valid_601795 != nil:
    section.add "X-Amz-Date", valid_601795
  var valid_601796 = header.getOrDefault("X-Amz-Security-Token")
  valid_601796 = validateParameter(valid_601796, JString, required = false,
                                 default = nil)
  if valid_601796 != nil:
    section.add "X-Amz-Security-Token", valid_601796
  var valid_601797 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601797 = validateParameter(valid_601797, JString, required = false,
                                 default = nil)
  if valid_601797 != nil:
    section.add "X-Amz-Content-Sha256", valid_601797
  var valid_601798 = header.getOrDefault("X-Amz-Algorithm")
  valid_601798 = validateParameter(valid_601798, JString, required = false,
                                 default = nil)
  if valid_601798 != nil:
    section.add "X-Amz-Algorithm", valid_601798
  var valid_601799 = header.getOrDefault("X-Amz-Signature")
  valid_601799 = validateParameter(valid_601799, JString, required = false,
                                 default = nil)
  if valid_601799 != nil:
    section.add "X-Amz-Signature", valid_601799
  var valid_601800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601800 = validateParameter(valid_601800, JString, required = false,
                                 default = nil)
  if valid_601800 != nil:
    section.add "X-Amz-SignedHeaders", valid_601800
  var valid_601801 = header.getOrDefault("X-Amz-Credential")
  valid_601801 = validateParameter(valid_601801, JString, required = false,
                                 default = nil)
  if valid_601801 != nil:
    section.add "X-Amz-Credential", valid_601801
  result.add "header", section
  ## parameters in `formData` object:
  ##   phoneNumber: JString (required)
  ##              : The phone number to opt in.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `phoneNumber` field"
  var valid_601802 = formData.getOrDefault("phoneNumber")
  valid_601802 = validateParameter(valid_601802, JString, required = true,
                                 default = nil)
  if valid_601802 != nil:
    section.add "phoneNumber", valid_601802
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601803: Call_PostOptInPhoneNumber_601790; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ## 
  let valid = call_601803.validator(path, query, header, formData, body)
  let scheme = call_601803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601803.url(scheme.get, call_601803.host, call_601803.base,
                         call_601803.route, valid.getOrDefault("path"))
  result = hook(call_601803, url, valid)

proc call*(call_601804: Call_PostOptInPhoneNumber_601790; phoneNumber: string;
          Action: string = "OptInPhoneNumber"; Version: string = "2010-03-31"): Recallable =
  ## postOptInPhoneNumber
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ##   Action: string (required)
  ##   phoneNumber: string (required)
  ##              : The phone number to opt in.
  ##   Version: string (required)
  var query_601805 = newJObject()
  var formData_601806 = newJObject()
  add(query_601805, "Action", newJString(Action))
  add(formData_601806, "phoneNumber", newJString(phoneNumber))
  add(query_601805, "Version", newJString(Version))
  result = call_601804.call(nil, query_601805, nil, formData_601806, nil)

var postOptInPhoneNumber* = Call_PostOptInPhoneNumber_601790(
    name: "postOptInPhoneNumber", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=OptInPhoneNumber",
    validator: validate_PostOptInPhoneNumber_601791, base: "/",
    url: url_PostOptInPhoneNumber_601792, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOptInPhoneNumber_601774 = ref object of OpenApiRestCall_600426
proc url_GetOptInPhoneNumber_601776(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetOptInPhoneNumber_601775(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   phoneNumber: JString (required)
  ##              : The phone number to opt in.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `phoneNumber` field"
  var valid_601777 = query.getOrDefault("phoneNumber")
  valid_601777 = validateParameter(valid_601777, JString, required = true,
                                 default = nil)
  if valid_601777 != nil:
    section.add "phoneNumber", valid_601777
  var valid_601778 = query.getOrDefault("Action")
  valid_601778 = validateParameter(valid_601778, JString, required = true,
                                 default = newJString("OptInPhoneNumber"))
  if valid_601778 != nil:
    section.add "Action", valid_601778
  var valid_601779 = query.getOrDefault("Version")
  valid_601779 = validateParameter(valid_601779, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601779 != nil:
    section.add "Version", valid_601779
  result.add "query", section
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
  if body != nil:
    result.add "body", body

proc call*(call_601787: Call_GetOptInPhoneNumber_601774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ## 
  let valid = call_601787.validator(path, query, header, formData, body)
  let scheme = call_601787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601787.url(scheme.get, call_601787.host, call_601787.base,
                         call_601787.route, valid.getOrDefault("path"))
  result = hook(call_601787, url, valid)

proc call*(call_601788: Call_GetOptInPhoneNumber_601774; phoneNumber: string;
          Action: string = "OptInPhoneNumber"; Version: string = "2010-03-31"): Recallable =
  ## getOptInPhoneNumber
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number to opt in.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601789 = newJObject()
  add(query_601789, "phoneNumber", newJString(phoneNumber))
  add(query_601789, "Action", newJString(Action))
  add(query_601789, "Version", newJString(Version))
  result = call_601788.call(nil, query_601789, nil, nil, nil)

var getOptInPhoneNumber* = Call_GetOptInPhoneNumber_601774(
    name: "getOptInPhoneNumber", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=OptInPhoneNumber",
    validator: validate_GetOptInPhoneNumber_601775, base: "/",
    url: url_GetOptInPhoneNumber_601776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPublish_601834 = ref object of OpenApiRestCall_600426
proc url_PostPublish_601836(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostPublish_601835(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601837 = query.getOrDefault("Action")
  valid_601837 = validateParameter(valid_601837, JString, required = true,
                                 default = newJString("Publish"))
  if valid_601837 != nil:
    section.add "Action", valid_601837
  var valid_601838 = query.getOrDefault("Version")
  valid_601838 = validateParameter(valid_601838, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601838 != nil:
    section.add "Version", valid_601838
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601839 = header.getOrDefault("X-Amz-Date")
  valid_601839 = validateParameter(valid_601839, JString, required = false,
                                 default = nil)
  if valid_601839 != nil:
    section.add "X-Amz-Date", valid_601839
  var valid_601840 = header.getOrDefault("X-Amz-Security-Token")
  valid_601840 = validateParameter(valid_601840, JString, required = false,
                                 default = nil)
  if valid_601840 != nil:
    section.add "X-Amz-Security-Token", valid_601840
  var valid_601841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "X-Amz-Content-Sha256", valid_601841
  var valid_601842 = header.getOrDefault("X-Amz-Algorithm")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "X-Amz-Algorithm", valid_601842
  var valid_601843 = header.getOrDefault("X-Amz-Signature")
  valid_601843 = validateParameter(valid_601843, JString, required = false,
                                 default = nil)
  if valid_601843 != nil:
    section.add "X-Amz-Signature", valid_601843
  var valid_601844 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601844 = validateParameter(valid_601844, JString, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "X-Amz-SignedHeaders", valid_601844
  var valid_601845 = header.getOrDefault("X-Amz-Credential")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "X-Amz-Credential", valid_601845
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString
  ##           : <p>The topic you want to publish to.</p> <p>If you don't specify a value for the <code>TopicArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TargetArn</code> parameters.</p>
  ##   Subject: JString
  ##          : <p>Optional parameter to be used as the "Subject" line when the message is delivered to email endpoints. This field will also be included, if present, in the standard JSON messages delivered to other endpoints.</p> <p>Constraints: Subjects must be ASCII text that begins with a letter, number, or punctuation mark; must not include line breaks or control characters; and must be less than 100 characters long.</p>
  ##   MessageAttributes.1.key: JString
  ##   TargetArn: JString
  ##            : If you don't specify a value for the <code>TargetArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TopicArn</code> parameters.
  ##   PhoneNumber: JString
  ##              : <p>The phone number to which you want to deliver an SMS message. Use E.164 format.</p> <p>If you don't specify a value for the <code>PhoneNumber</code> parameter, you must specify a value for the <code>TargetArn</code> or <code>TopicArn</code> parameters.</p>
  ##   MessageAttributes.0.value: JString
  ##   MessageAttributes.1.value: JString
  ##   MessageAttributes.0.key: JString
  ##   Message: JString (required)
  ##          : <p>The message you want to send.</p> <important> <p>The <code>Message</code> parameter is always a string. If you set <code>MessageStructure</code> to <code>json</code>, you must string-encode the <code>Message</code> parameter.</p> </important> <p>If you are publishing to a topic and you want to send the same message to all transport protocols, include the text of the message as a String value. If you want to send different messages for each transport protocol, set the value of the <code>MessageStructure</code> parameter to <code>json</code> and use a JSON object for the <code>Message</code> parameter. </p> <p/> <p>Constraints:</p> <ul> <li> <p>With the exception of SMS, messages must be UTF-8 encoded strings and at most 256 KB in size (262,144 bytes, not 262,144 characters).</p> </li> <li> <p>For SMS, each message can contain up to 140 characters. This character limit depends on the encoding schema. For example, an SMS message can contain 160 GSM characters, 140 ASCII characters, or 70 UCS-2 characters.</p> <p>If you publish a message that exceeds this size limit, Amazon SNS sends the message as multiple messages, each fitting within the size limit. Messages aren't truncated mid-word but are cut off at whole-word boundaries.</p> <p>The total size limit for a single SMS <code>Publish</code> action is 1,600 characters.</p> </li> </ul> <p>JSON-specific constraints:</p> <ul> <li> <p>Keys in the JSON object that correspond to supported transport protocols must have simple JSON string values.</p> </li> <li> <p>The values will be parsed (unescaped) before they are used in outgoing messages.</p> </li> <li> <p>Outbound notifications are JSON encoded (meaning that the characters will be reescaped for sending).</p> </li> <li> <p>Values have a minimum length of 0 (the empty string, "", is allowed).</p> </li> <li> <p>Values have a maximum length bounded by the overall message size (so, including multiple protocols may limit message sizes).</p> </li> <li> <p>Non-string values will cause the key to be ignored.</p> </li> <li> <p>Keys that do not correspond to supported transport protocols are ignored.</p> </li> <li> <p>Duplicate keys are not allowed.</p> </li> <li> <p>Failure to parse or validate any key or value in the message will cause the <code>Publish</code> call to return an error (no partial delivery).</p> </li> </ul>
  ##   MessageStructure: JString
  ##                   : <p>Set <code>MessageStructure</code> to <code>json</code> if you want to send a different message for each protocol. For example, using one publish action, you can send a short message to your SMS subscribers and a longer message to your email subscribers. If you set <code>MessageStructure</code> to <code>json</code>, the value of the <code>Message</code> parameter must: </p> <ul> <li> <p>be a syntactically valid JSON object; and</p> </li> <li> <p>contain at least a top-level JSON key of "default" with a value that is a string.</p> </li> </ul> <p>You can define other top-level keys that define the message you want to send to a specific transport protocol (e.g., "http").</p> <p>For information about sending different messages for each protocol using the AWS Management Console, go to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/gsg/Publish.html#sns-message-formatting-by-protocol">Create Different Messages for Each Protocol</a> in the <i>Amazon Simple Notification Service Getting Started Guide</i>. </p> <p>Valid value: <code>json</code> </p>
  ##   MessageAttributes.2.key: JString
  ##   MessageAttributes.2.value: JString
  section = newJObject()
  var valid_601846 = formData.getOrDefault("TopicArn")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "TopicArn", valid_601846
  var valid_601847 = formData.getOrDefault("Subject")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "Subject", valid_601847
  var valid_601848 = formData.getOrDefault("MessageAttributes.1.key")
  valid_601848 = validateParameter(valid_601848, JString, required = false,
                                 default = nil)
  if valid_601848 != nil:
    section.add "MessageAttributes.1.key", valid_601848
  var valid_601849 = formData.getOrDefault("TargetArn")
  valid_601849 = validateParameter(valid_601849, JString, required = false,
                                 default = nil)
  if valid_601849 != nil:
    section.add "TargetArn", valid_601849
  var valid_601850 = formData.getOrDefault("PhoneNumber")
  valid_601850 = validateParameter(valid_601850, JString, required = false,
                                 default = nil)
  if valid_601850 != nil:
    section.add "PhoneNumber", valid_601850
  var valid_601851 = formData.getOrDefault("MessageAttributes.0.value")
  valid_601851 = validateParameter(valid_601851, JString, required = false,
                                 default = nil)
  if valid_601851 != nil:
    section.add "MessageAttributes.0.value", valid_601851
  var valid_601852 = formData.getOrDefault("MessageAttributes.1.value")
  valid_601852 = validateParameter(valid_601852, JString, required = false,
                                 default = nil)
  if valid_601852 != nil:
    section.add "MessageAttributes.1.value", valid_601852
  var valid_601853 = formData.getOrDefault("MessageAttributes.0.key")
  valid_601853 = validateParameter(valid_601853, JString, required = false,
                                 default = nil)
  if valid_601853 != nil:
    section.add "MessageAttributes.0.key", valid_601853
  assert formData != nil,
        "formData argument is necessary due to required `Message` field"
  var valid_601854 = formData.getOrDefault("Message")
  valid_601854 = validateParameter(valid_601854, JString, required = true,
                                 default = nil)
  if valid_601854 != nil:
    section.add "Message", valid_601854
  var valid_601855 = formData.getOrDefault("MessageStructure")
  valid_601855 = validateParameter(valid_601855, JString, required = false,
                                 default = nil)
  if valid_601855 != nil:
    section.add "MessageStructure", valid_601855
  var valid_601856 = formData.getOrDefault("MessageAttributes.2.key")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "MessageAttributes.2.key", valid_601856
  var valid_601857 = formData.getOrDefault("MessageAttributes.2.value")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "MessageAttributes.2.value", valid_601857
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601858: Call_PostPublish_601834; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  let valid = call_601858.validator(path, query, header, formData, body)
  let scheme = call_601858.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601858.url(scheme.get, call_601858.host, call_601858.base,
                         call_601858.route, valid.getOrDefault("path"))
  result = hook(call_601858, url, valid)

proc call*(call_601859: Call_PostPublish_601834; Message: string;
          TopicArn: string = ""; Subject: string = "";
          MessageAttributes1Key: string = ""; TargetArn: string = "";
          PhoneNumber: string = ""; MessageAttributes0Value: string = "";
          MessageAttributes1Value: string = ""; MessageAttributes0Key: string = "";
          Action: string = "Publish"; MessageStructure: string = "";
          MessageAttributes2Key: string = ""; Version: string = "2010-03-31";
          MessageAttributes2Value: string = ""): Recallable =
  ## postPublish
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ##   TopicArn: string
  ##           : <p>The topic you want to publish to.</p> <p>If you don't specify a value for the <code>TopicArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TargetArn</code> parameters.</p>
  ##   Subject: string
  ##          : <p>Optional parameter to be used as the "Subject" line when the message is delivered to email endpoints. This field will also be included, if present, in the standard JSON messages delivered to other endpoints.</p> <p>Constraints: Subjects must be ASCII text that begins with a letter, number, or punctuation mark; must not include line breaks or control characters; and must be less than 100 characters long.</p>
  ##   MessageAttributes1Key: string
  ##   TargetArn: string
  ##            : If you don't specify a value for the <code>TargetArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TopicArn</code> parameters.
  ##   PhoneNumber: string
  ##              : <p>The phone number to which you want to deliver an SMS message. Use E.164 format.</p> <p>If you don't specify a value for the <code>PhoneNumber</code> parameter, you must specify a value for the <code>TargetArn</code> or <code>TopicArn</code> parameters.</p>
  ##   MessageAttributes0Value: string
  ##   MessageAttributes1Value: string
  ##   MessageAttributes0Key: string
  ##   Message: string (required)
  ##          : <p>The message you want to send.</p> <important> <p>The <code>Message</code> parameter is always a string. If you set <code>MessageStructure</code> to <code>json</code>, you must string-encode the <code>Message</code> parameter.</p> </important> <p>If you are publishing to a topic and you want to send the same message to all transport protocols, include the text of the message as a String value. If you want to send different messages for each transport protocol, set the value of the <code>MessageStructure</code> parameter to <code>json</code> and use a JSON object for the <code>Message</code> parameter. </p> <p/> <p>Constraints:</p> <ul> <li> <p>With the exception of SMS, messages must be UTF-8 encoded strings and at most 256 KB in size (262,144 bytes, not 262,144 characters).</p> </li> <li> <p>For SMS, each message can contain up to 140 characters. This character limit depends on the encoding schema. For example, an SMS message can contain 160 GSM characters, 140 ASCII characters, or 70 UCS-2 characters.</p> <p>If you publish a message that exceeds this size limit, Amazon SNS sends the message as multiple messages, each fitting within the size limit. Messages aren't truncated mid-word but are cut off at whole-word boundaries.</p> <p>The total size limit for a single SMS <code>Publish</code> action is 1,600 characters.</p> </li> </ul> <p>JSON-specific constraints:</p> <ul> <li> <p>Keys in the JSON object that correspond to supported transport protocols must have simple JSON string values.</p> </li> <li> <p>The values will be parsed (unescaped) before they are used in outgoing messages.</p> </li> <li> <p>Outbound notifications are JSON encoded (meaning that the characters will be reescaped for sending).</p> </li> <li> <p>Values have a minimum length of 0 (the empty string, "", is allowed).</p> </li> <li> <p>Values have a maximum length bounded by the overall message size (so, including multiple protocols may limit message sizes).</p> </li> <li> <p>Non-string values will cause the key to be ignored.</p> </li> <li> <p>Keys that do not correspond to supported transport protocols are ignored.</p> </li> <li> <p>Duplicate keys are not allowed.</p> </li> <li> <p>Failure to parse or validate any key or value in the message will cause the <code>Publish</code> call to return an error (no partial delivery).</p> </li> </ul>
  ##   Action: string (required)
  ##   MessageStructure: string
  ##                   : <p>Set <code>MessageStructure</code> to <code>json</code> if you want to send a different message for each protocol. For example, using one publish action, you can send a short message to your SMS subscribers and a longer message to your email subscribers. If you set <code>MessageStructure</code> to <code>json</code>, the value of the <code>Message</code> parameter must: </p> <ul> <li> <p>be a syntactically valid JSON object; and</p> </li> <li> <p>contain at least a top-level JSON key of "default" with a value that is a string.</p> </li> </ul> <p>You can define other top-level keys that define the message you want to send to a specific transport protocol (e.g., "http").</p> <p>For information about sending different messages for each protocol using the AWS Management Console, go to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/gsg/Publish.html#sns-message-formatting-by-protocol">Create Different Messages for Each Protocol</a> in the <i>Amazon Simple Notification Service Getting Started Guide</i>. </p> <p>Valid value: <code>json</code> </p>
  ##   MessageAttributes2Key: string
  ##   Version: string (required)
  ##   MessageAttributes2Value: string
  var query_601860 = newJObject()
  var formData_601861 = newJObject()
  add(formData_601861, "TopicArn", newJString(TopicArn))
  add(formData_601861, "Subject", newJString(Subject))
  add(formData_601861, "MessageAttributes.1.key",
      newJString(MessageAttributes1Key))
  add(formData_601861, "TargetArn", newJString(TargetArn))
  add(formData_601861, "PhoneNumber", newJString(PhoneNumber))
  add(formData_601861, "MessageAttributes.0.value",
      newJString(MessageAttributes0Value))
  add(formData_601861, "MessageAttributes.1.value",
      newJString(MessageAttributes1Value))
  add(formData_601861, "MessageAttributes.0.key",
      newJString(MessageAttributes0Key))
  add(formData_601861, "Message", newJString(Message))
  add(query_601860, "Action", newJString(Action))
  add(formData_601861, "MessageStructure", newJString(MessageStructure))
  add(formData_601861, "MessageAttributes.2.key",
      newJString(MessageAttributes2Key))
  add(query_601860, "Version", newJString(Version))
  add(formData_601861, "MessageAttributes.2.value",
      newJString(MessageAttributes2Value))
  result = call_601859.call(nil, query_601860, nil, formData_601861, nil)

var postPublish* = Call_PostPublish_601834(name: "postPublish",
                                        meth: HttpMethod.HttpPost,
                                        host: "sns.amazonaws.com",
                                        route: "/#Action=Publish",
                                        validator: validate_PostPublish_601835,
                                        base: "/", url: url_PostPublish_601836,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublish_601807 = ref object of OpenApiRestCall_600426
proc url_GetPublish_601809(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPublish_601808(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MessageAttributes.0.value: JString
  ##   MessageAttributes.0.key: JString
  ##   MessageAttributes.1.value: JString
  ##   Message: JString (required)
  ##          : <p>The message you want to send.</p> <important> <p>The <code>Message</code> parameter is always a string. If you set <code>MessageStructure</code> to <code>json</code>, you must string-encode the <code>Message</code> parameter.</p> </important> <p>If you are publishing to a topic and you want to send the same message to all transport protocols, include the text of the message as a String value. If you want to send different messages for each transport protocol, set the value of the <code>MessageStructure</code> parameter to <code>json</code> and use a JSON object for the <code>Message</code> parameter. </p> <p/> <p>Constraints:</p> <ul> <li> <p>With the exception of SMS, messages must be UTF-8 encoded strings and at most 256 KB in size (262,144 bytes, not 262,144 characters).</p> </li> <li> <p>For SMS, each message can contain up to 140 characters. This character limit depends on the encoding schema. For example, an SMS message can contain 160 GSM characters, 140 ASCII characters, or 70 UCS-2 characters.</p> <p>If you publish a message that exceeds this size limit, Amazon SNS sends the message as multiple messages, each fitting within the size limit. Messages aren't truncated mid-word but are cut off at whole-word boundaries.</p> <p>The total size limit for a single SMS <code>Publish</code> action is 1,600 characters.</p> </li> </ul> <p>JSON-specific constraints:</p> <ul> <li> <p>Keys in the JSON object that correspond to supported transport protocols must have simple JSON string values.</p> </li> <li> <p>The values will be parsed (unescaped) before they are used in outgoing messages.</p> </li> <li> <p>Outbound notifications are JSON encoded (meaning that the characters will be reescaped for sending).</p> </li> <li> <p>Values have a minimum length of 0 (the empty string, "", is allowed).</p> </li> <li> <p>Values have a maximum length bounded by the overall message size (so, including multiple protocols may limit message sizes).</p> </li> <li> <p>Non-string values will cause the key to be ignored.</p> </li> <li> <p>Keys that do not correspond to supported transport protocols are ignored.</p> </li> <li> <p>Duplicate keys are not allowed.</p> </li> <li> <p>Failure to parse or validate any key or value in the message will cause the <code>Publish</code> call to return an error (no partial delivery).</p> </li> </ul>
  ##   Subject: JString
  ##          : <p>Optional parameter to be used as the "Subject" line when the message is delivered to email endpoints. This field will also be included, if present, in the standard JSON messages delivered to other endpoints.</p> <p>Constraints: Subjects must be ASCII text that begins with a letter, number, or punctuation mark; must not include line breaks or control characters; and must be less than 100 characters long.</p>
  ##   Action: JString (required)
  ##   MessageAttributes.2.value: JString
  ##   MessageStructure: JString
  ##                   : <p>Set <code>MessageStructure</code> to <code>json</code> if you want to send a different message for each protocol. For example, using one publish action, you can send a short message to your SMS subscribers and a longer message to your email subscribers. If you set <code>MessageStructure</code> to <code>json</code>, the value of the <code>Message</code> parameter must: </p> <ul> <li> <p>be a syntactically valid JSON object; and</p> </li> <li> <p>contain at least a top-level JSON key of "default" with a value that is a string.</p> </li> </ul> <p>You can define other top-level keys that define the message you want to send to a specific transport protocol (e.g., "http").</p> <p>For information about sending different messages for each protocol using the AWS Management Console, go to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/gsg/Publish.html#sns-message-formatting-by-protocol">Create Different Messages for Each Protocol</a> in the <i>Amazon Simple Notification Service Getting Started Guide</i>. </p> <p>Valid value: <code>json</code> </p>
  ##   TopicArn: JString
  ##           : <p>The topic you want to publish to.</p> <p>If you don't specify a value for the <code>TopicArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TargetArn</code> parameters.</p>
  ##   PhoneNumber: JString
  ##              : <p>The phone number to which you want to deliver an SMS message. Use E.164 format.</p> <p>If you don't specify a value for the <code>PhoneNumber</code> parameter, you must specify a value for the <code>TargetArn</code> or <code>TopicArn</code> parameters.</p>
  ##   MessageAttributes.1.key: JString
  ##   MessageAttributes.2.key: JString
  ##   TargetArn: JString
  ##            : If you don't specify a value for the <code>TargetArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TopicArn</code> parameters.
  ##   Version: JString (required)
  section = newJObject()
  var valid_601810 = query.getOrDefault("MessageAttributes.0.value")
  valid_601810 = validateParameter(valid_601810, JString, required = false,
                                 default = nil)
  if valid_601810 != nil:
    section.add "MessageAttributes.0.value", valid_601810
  var valid_601811 = query.getOrDefault("MessageAttributes.0.key")
  valid_601811 = validateParameter(valid_601811, JString, required = false,
                                 default = nil)
  if valid_601811 != nil:
    section.add "MessageAttributes.0.key", valid_601811
  var valid_601812 = query.getOrDefault("MessageAttributes.1.value")
  valid_601812 = validateParameter(valid_601812, JString, required = false,
                                 default = nil)
  if valid_601812 != nil:
    section.add "MessageAttributes.1.value", valid_601812
  assert query != nil, "query argument is necessary due to required `Message` field"
  var valid_601813 = query.getOrDefault("Message")
  valid_601813 = validateParameter(valid_601813, JString, required = true,
                                 default = nil)
  if valid_601813 != nil:
    section.add "Message", valid_601813
  var valid_601814 = query.getOrDefault("Subject")
  valid_601814 = validateParameter(valid_601814, JString, required = false,
                                 default = nil)
  if valid_601814 != nil:
    section.add "Subject", valid_601814
  var valid_601815 = query.getOrDefault("Action")
  valid_601815 = validateParameter(valid_601815, JString, required = true,
                                 default = newJString("Publish"))
  if valid_601815 != nil:
    section.add "Action", valid_601815
  var valid_601816 = query.getOrDefault("MessageAttributes.2.value")
  valid_601816 = validateParameter(valid_601816, JString, required = false,
                                 default = nil)
  if valid_601816 != nil:
    section.add "MessageAttributes.2.value", valid_601816
  var valid_601817 = query.getOrDefault("MessageStructure")
  valid_601817 = validateParameter(valid_601817, JString, required = false,
                                 default = nil)
  if valid_601817 != nil:
    section.add "MessageStructure", valid_601817
  var valid_601818 = query.getOrDefault("TopicArn")
  valid_601818 = validateParameter(valid_601818, JString, required = false,
                                 default = nil)
  if valid_601818 != nil:
    section.add "TopicArn", valid_601818
  var valid_601819 = query.getOrDefault("PhoneNumber")
  valid_601819 = validateParameter(valid_601819, JString, required = false,
                                 default = nil)
  if valid_601819 != nil:
    section.add "PhoneNumber", valid_601819
  var valid_601820 = query.getOrDefault("MessageAttributes.1.key")
  valid_601820 = validateParameter(valid_601820, JString, required = false,
                                 default = nil)
  if valid_601820 != nil:
    section.add "MessageAttributes.1.key", valid_601820
  var valid_601821 = query.getOrDefault("MessageAttributes.2.key")
  valid_601821 = validateParameter(valid_601821, JString, required = false,
                                 default = nil)
  if valid_601821 != nil:
    section.add "MessageAttributes.2.key", valid_601821
  var valid_601822 = query.getOrDefault("TargetArn")
  valid_601822 = validateParameter(valid_601822, JString, required = false,
                                 default = nil)
  if valid_601822 != nil:
    section.add "TargetArn", valid_601822
  var valid_601823 = query.getOrDefault("Version")
  valid_601823 = validateParameter(valid_601823, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601823 != nil:
    section.add "Version", valid_601823
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601824 = header.getOrDefault("X-Amz-Date")
  valid_601824 = validateParameter(valid_601824, JString, required = false,
                                 default = nil)
  if valid_601824 != nil:
    section.add "X-Amz-Date", valid_601824
  var valid_601825 = header.getOrDefault("X-Amz-Security-Token")
  valid_601825 = validateParameter(valid_601825, JString, required = false,
                                 default = nil)
  if valid_601825 != nil:
    section.add "X-Amz-Security-Token", valid_601825
  var valid_601826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601826 = validateParameter(valid_601826, JString, required = false,
                                 default = nil)
  if valid_601826 != nil:
    section.add "X-Amz-Content-Sha256", valid_601826
  var valid_601827 = header.getOrDefault("X-Amz-Algorithm")
  valid_601827 = validateParameter(valid_601827, JString, required = false,
                                 default = nil)
  if valid_601827 != nil:
    section.add "X-Amz-Algorithm", valid_601827
  var valid_601828 = header.getOrDefault("X-Amz-Signature")
  valid_601828 = validateParameter(valid_601828, JString, required = false,
                                 default = nil)
  if valid_601828 != nil:
    section.add "X-Amz-Signature", valid_601828
  var valid_601829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601829 = validateParameter(valid_601829, JString, required = false,
                                 default = nil)
  if valid_601829 != nil:
    section.add "X-Amz-SignedHeaders", valid_601829
  var valid_601830 = header.getOrDefault("X-Amz-Credential")
  valid_601830 = validateParameter(valid_601830, JString, required = false,
                                 default = nil)
  if valid_601830 != nil:
    section.add "X-Amz-Credential", valid_601830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601831: Call_GetPublish_601807; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  let valid = call_601831.validator(path, query, header, formData, body)
  let scheme = call_601831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601831.url(scheme.get, call_601831.host, call_601831.base,
                         call_601831.route, valid.getOrDefault("path"))
  result = hook(call_601831, url, valid)

proc call*(call_601832: Call_GetPublish_601807; Message: string;
          MessageAttributes0Value: string = ""; MessageAttributes0Key: string = "";
          MessageAttributes1Value: string = ""; Subject: string = "";
          Action: string = "Publish"; MessageAttributes2Value: string = "";
          MessageStructure: string = ""; TopicArn: string = "";
          PhoneNumber: string = ""; MessageAttributes1Key: string = "";
          MessageAttributes2Key: string = ""; TargetArn: string = "";
          Version: string = "2010-03-31"): Recallable =
  ## getPublish
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ##   MessageAttributes0Value: string
  ##   MessageAttributes0Key: string
  ##   MessageAttributes1Value: string
  ##   Message: string (required)
  ##          : <p>The message you want to send.</p> <important> <p>The <code>Message</code> parameter is always a string. If you set <code>MessageStructure</code> to <code>json</code>, you must string-encode the <code>Message</code> parameter.</p> </important> <p>If you are publishing to a topic and you want to send the same message to all transport protocols, include the text of the message as a String value. If you want to send different messages for each transport protocol, set the value of the <code>MessageStructure</code> parameter to <code>json</code> and use a JSON object for the <code>Message</code> parameter. </p> <p/> <p>Constraints:</p> <ul> <li> <p>With the exception of SMS, messages must be UTF-8 encoded strings and at most 256 KB in size (262,144 bytes, not 262,144 characters).</p> </li> <li> <p>For SMS, each message can contain up to 140 characters. This character limit depends on the encoding schema. For example, an SMS message can contain 160 GSM characters, 140 ASCII characters, or 70 UCS-2 characters.</p> <p>If you publish a message that exceeds this size limit, Amazon SNS sends the message as multiple messages, each fitting within the size limit. Messages aren't truncated mid-word but are cut off at whole-word boundaries.</p> <p>The total size limit for a single SMS <code>Publish</code> action is 1,600 characters.</p> </li> </ul> <p>JSON-specific constraints:</p> <ul> <li> <p>Keys in the JSON object that correspond to supported transport protocols must have simple JSON string values.</p> </li> <li> <p>The values will be parsed (unescaped) before they are used in outgoing messages.</p> </li> <li> <p>Outbound notifications are JSON encoded (meaning that the characters will be reescaped for sending).</p> </li> <li> <p>Values have a minimum length of 0 (the empty string, "", is allowed).</p> </li> <li> <p>Values have a maximum length bounded by the overall message size (so, including multiple protocols may limit message sizes).</p> </li> <li> <p>Non-string values will cause the key to be ignored.</p> </li> <li> <p>Keys that do not correspond to supported transport protocols are ignored.</p> </li> <li> <p>Duplicate keys are not allowed.</p> </li> <li> <p>Failure to parse or validate any key or value in the message will cause the <code>Publish</code> call to return an error (no partial delivery).</p> </li> </ul>
  ##   Subject: string
  ##          : <p>Optional parameter to be used as the "Subject" line when the message is delivered to email endpoints. This field will also be included, if present, in the standard JSON messages delivered to other endpoints.</p> <p>Constraints: Subjects must be ASCII text that begins with a letter, number, or punctuation mark; must not include line breaks or control characters; and must be less than 100 characters long.</p>
  ##   Action: string (required)
  ##   MessageAttributes2Value: string
  ##   MessageStructure: string
  ##                   : <p>Set <code>MessageStructure</code> to <code>json</code> if you want to send a different message for each protocol. For example, using one publish action, you can send a short message to your SMS subscribers and a longer message to your email subscribers. If you set <code>MessageStructure</code> to <code>json</code>, the value of the <code>Message</code> parameter must: </p> <ul> <li> <p>be a syntactically valid JSON object; and</p> </li> <li> <p>contain at least a top-level JSON key of "default" with a value that is a string.</p> </li> </ul> <p>You can define other top-level keys that define the message you want to send to a specific transport protocol (e.g., "http").</p> <p>For information about sending different messages for each protocol using the AWS Management Console, go to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/gsg/Publish.html#sns-message-formatting-by-protocol">Create Different Messages for Each Protocol</a> in the <i>Amazon Simple Notification Service Getting Started Guide</i>. </p> <p>Valid value: <code>json</code> </p>
  ##   TopicArn: string
  ##           : <p>The topic you want to publish to.</p> <p>If you don't specify a value for the <code>TopicArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TargetArn</code> parameters.</p>
  ##   PhoneNumber: string
  ##              : <p>The phone number to which you want to deliver an SMS message. Use E.164 format.</p> <p>If you don't specify a value for the <code>PhoneNumber</code> parameter, you must specify a value for the <code>TargetArn</code> or <code>TopicArn</code> parameters.</p>
  ##   MessageAttributes1Key: string
  ##   MessageAttributes2Key: string
  ##   TargetArn: string
  ##            : If you don't specify a value for the <code>TargetArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TopicArn</code> parameters.
  ##   Version: string (required)
  var query_601833 = newJObject()
  add(query_601833, "MessageAttributes.0.value",
      newJString(MessageAttributes0Value))
  add(query_601833, "MessageAttributes.0.key", newJString(MessageAttributes0Key))
  add(query_601833, "MessageAttributes.1.value",
      newJString(MessageAttributes1Value))
  add(query_601833, "Message", newJString(Message))
  add(query_601833, "Subject", newJString(Subject))
  add(query_601833, "Action", newJString(Action))
  add(query_601833, "MessageAttributes.2.value",
      newJString(MessageAttributes2Value))
  add(query_601833, "MessageStructure", newJString(MessageStructure))
  add(query_601833, "TopicArn", newJString(TopicArn))
  add(query_601833, "PhoneNumber", newJString(PhoneNumber))
  add(query_601833, "MessageAttributes.1.key", newJString(MessageAttributes1Key))
  add(query_601833, "MessageAttributes.2.key", newJString(MessageAttributes2Key))
  add(query_601833, "TargetArn", newJString(TargetArn))
  add(query_601833, "Version", newJString(Version))
  result = call_601832.call(nil, query_601833, nil, nil, nil)

var getPublish* = Call_GetPublish_601807(name: "getPublish",
                                      meth: HttpMethod.HttpGet,
                                      host: "sns.amazonaws.com",
                                      route: "/#Action=Publish",
                                      validator: validate_GetPublish_601808,
                                      base: "/", url: url_GetPublish_601809,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemovePermission_601879 = ref object of OpenApiRestCall_600426
proc url_PostRemovePermission_601881(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemovePermission_601880(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a statement from a topic's access control policy.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601882 = query.getOrDefault("Action")
  valid_601882 = validateParameter(valid_601882, JString, required = true,
                                 default = newJString("RemovePermission"))
  if valid_601882 != nil:
    section.add "Action", valid_601882
  var valid_601883 = query.getOrDefault("Version")
  valid_601883 = validateParameter(valid_601883, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601883 != nil:
    section.add "Version", valid_601883
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601884 = header.getOrDefault("X-Amz-Date")
  valid_601884 = validateParameter(valid_601884, JString, required = false,
                                 default = nil)
  if valid_601884 != nil:
    section.add "X-Amz-Date", valid_601884
  var valid_601885 = header.getOrDefault("X-Amz-Security-Token")
  valid_601885 = validateParameter(valid_601885, JString, required = false,
                                 default = nil)
  if valid_601885 != nil:
    section.add "X-Amz-Security-Token", valid_601885
  var valid_601886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601886 = validateParameter(valid_601886, JString, required = false,
                                 default = nil)
  if valid_601886 != nil:
    section.add "X-Amz-Content-Sha256", valid_601886
  var valid_601887 = header.getOrDefault("X-Amz-Algorithm")
  valid_601887 = validateParameter(valid_601887, JString, required = false,
                                 default = nil)
  if valid_601887 != nil:
    section.add "X-Amz-Algorithm", valid_601887
  var valid_601888 = header.getOrDefault("X-Amz-Signature")
  valid_601888 = validateParameter(valid_601888, JString, required = false,
                                 default = nil)
  if valid_601888 != nil:
    section.add "X-Amz-Signature", valid_601888
  var valid_601889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601889 = validateParameter(valid_601889, JString, required = false,
                                 default = nil)
  if valid_601889 != nil:
    section.add "X-Amz-SignedHeaders", valid_601889
  var valid_601890 = header.getOrDefault("X-Amz-Credential")
  valid_601890 = validateParameter(valid_601890, JString, required = false,
                                 default = nil)
  if valid_601890 != nil:
    section.add "X-Amz-Credential", valid_601890
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Label: JString (required)
  ##        : The unique label of the statement you want to remove.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_601891 = formData.getOrDefault("TopicArn")
  valid_601891 = validateParameter(valid_601891, JString, required = true,
                                 default = nil)
  if valid_601891 != nil:
    section.add "TopicArn", valid_601891
  var valid_601892 = formData.getOrDefault("Label")
  valid_601892 = validateParameter(valid_601892, JString, required = true,
                                 default = nil)
  if valid_601892 != nil:
    section.add "Label", valid_601892
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601893: Call_PostRemovePermission_601879; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a statement from a topic's access control policy.
  ## 
  let valid = call_601893.validator(path, query, header, formData, body)
  let scheme = call_601893.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601893.url(scheme.get, call_601893.host, call_601893.base,
                         call_601893.route, valid.getOrDefault("path"))
  result = hook(call_601893, url, valid)

proc call*(call_601894: Call_PostRemovePermission_601879; TopicArn: string;
          Label: string; Action: string = "RemovePermission";
          Version: string = "2010-03-31"): Recallable =
  ## postRemovePermission
  ## Removes a statement from a topic's access control policy.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Label: string (required)
  ##        : The unique label of the statement you want to remove.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601895 = newJObject()
  var formData_601896 = newJObject()
  add(formData_601896, "TopicArn", newJString(TopicArn))
  add(formData_601896, "Label", newJString(Label))
  add(query_601895, "Action", newJString(Action))
  add(query_601895, "Version", newJString(Version))
  result = call_601894.call(nil, query_601895, nil, formData_601896, nil)

var postRemovePermission* = Call_PostRemovePermission_601879(
    name: "postRemovePermission", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=RemovePermission",
    validator: validate_PostRemovePermission_601880, base: "/",
    url: url_PostRemovePermission_601881, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemovePermission_601862 = ref object of OpenApiRestCall_600426
proc url_GetRemovePermission_601864(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemovePermission_601863(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Removes a statement from a topic's access control policy.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Version: JString (required)
  ##   Label: JString (required)
  ##        : The unique label of the statement you want to remove.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601865 = query.getOrDefault("Action")
  valid_601865 = validateParameter(valid_601865, JString, required = true,
                                 default = newJString("RemovePermission"))
  if valid_601865 != nil:
    section.add "Action", valid_601865
  var valid_601866 = query.getOrDefault("TopicArn")
  valid_601866 = validateParameter(valid_601866, JString, required = true,
                                 default = nil)
  if valid_601866 != nil:
    section.add "TopicArn", valid_601866
  var valid_601867 = query.getOrDefault("Version")
  valid_601867 = validateParameter(valid_601867, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601867 != nil:
    section.add "Version", valid_601867
  var valid_601868 = query.getOrDefault("Label")
  valid_601868 = validateParameter(valid_601868, JString, required = true,
                                 default = nil)
  if valid_601868 != nil:
    section.add "Label", valid_601868
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601869 = header.getOrDefault("X-Amz-Date")
  valid_601869 = validateParameter(valid_601869, JString, required = false,
                                 default = nil)
  if valid_601869 != nil:
    section.add "X-Amz-Date", valid_601869
  var valid_601870 = header.getOrDefault("X-Amz-Security-Token")
  valid_601870 = validateParameter(valid_601870, JString, required = false,
                                 default = nil)
  if valid_601870 != nil:
    section.add "X-Amz-Security-Token", valid_601870
  var valid_601871 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601871 = validateParameter(valid_601871, JString, required = false,
                                 default = nil)
  if valid_601871 != nil:
    section.add "X-Amz-Content-Sha256", valid_601871
  var valid_601872 = header.getOrDefault("X-Amz-Algorithm")
  valid_601872 = validateParameter(valid_601872, JString, required = false,
                                 default = nil)
  if valid_601872 != nil:
    section.add "X-Amz-Algorithm", valid_601872
  var valid_601873 = header.getOrDefault("X-Amz-Signature")
  valid_601873 = validateParameter(valid_601873, JString, required = false,
                                 default = nil)
  if valid_601873 != nil:
    section.add "X-Amz-Signature", valid_601873
  var valid_601874 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601874 = validateParameter(valid_601874, JString, required = false,
                                 default = nil)
  if valid_601874 != nil:
    section.add "X-Amz-SignedHeaders", valid_601874
  var valid_601875 = header.getOrDefault("X-Amz-Credential")
  valid_601875 = validateParameter(valid_601875, JString, required = false,
                                 default = nil)
  if valid_601875 != nil:
    section.add "X-Amz-Credential", valid_601875
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601876: Call_GetRemovePermission_601862; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a statement from a topic's access control policy.
  ## 
  let valid = call_601876.validator(path, query, header, formData, body)
  let scheme = call_601876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601876.url(scheme.get, call_601876.host, call_601876.base,
                         call_601876.route, valid.getOrDefault("path"))
  result = hook(call_601876, url, valid)

proc call*(call_601877: Call_GetRemovePermission_601862; TopicArn: string;
          Label: string; Action: string = "RemovePermission";
          Version: string = "2010-03-31"): Recallable =
  ## getRemovePermission
  ## Removes a statement from a topic's access control policy.
  ##   Action: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Version: string (required)
  ##   Label: string (required)
  ##        : The unique label of the statement you want to remove.
  var query_601878 = newJObject()
  add(query_601878, "Action", newJString(Action))
  add(query_601878, "TopicArn", newJString(TopicArn))
  add(query_601878, "Version", newJString(Version))
  add(query_601878, "Label", newJString(Label))
  result = call_601877.call(nil, query_601878, nil, nil, nil)

var getRemovePermission* = Call_GetRemovePermission_601862(
    name: "getRemovePermission", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=RemovePermission",
    validator: validate_GetRemovePermission_601863, base: "/",
    url: url_GetRemovePermission_601864, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetEndpointAttributes_601919 = ref object of OpenApiRestCall_600426
proc url_PostSetEndpointAttributes_601921(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetEndpointAttributes_601920(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601922 = query.getOrDefault("Action")
  valid_601922 = validateParameter(valid_601922, JString, required = true,
                                 default = newJString("SetEndpointAttributes"))
  if valid_601922 != nil:
    section.add "Action", valid_601922
  var valid_601923 = query.getOrDefault("Version")
  valid_601923 = validateParameter(valid_601923, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601923 != nil:
    section.add "Version", valid_601923
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601924 = header.getOrDefault("X-Amz-Date")
  valid_601924 = validateParameter(valid_601924, JString, required = false,
                                 default = nil)
  if valid_601924 != nil:
    section.add "X-Amz-Date", valid_601924
  var valid_601925 = header.getOrDefault("X-Amz-Security-Token")
  valid_601925 = validateParameter(valid_601925, JString, required = false,
                                 default = nil)
  if valid_601925 != nil:
    section.add "X-Amz-Security-Token", valid_601925
  var valid_601926 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601926 = validateParameter(valid_601926, JString, required = false,
                                 default = nil)
  if valid_601926 != nil:
    section.add "X-Amz-Content-Sha256", valid_601926
  var valid_601927 = header.getOrDefault("X-Amz-Algorithm")
  valid_601927 = validateParameter(valid_601927, JString, required = false,
                                 default = nil)
  if valid_601927 != nil:
    section.add "X-Amz-Algorithm", valid_601927
  var valid_601928 = header.getOrDefault("X-Amz-Signature")
  valid_601928 = validateParameter(valid_601928, JString, required = false,
                                 default = nil)
  if valid_601928 != nil:
    section.add "X-Amz-Signature", valid_601928
  var valid_601929 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601929 = validateParameter(valid_601929, JString, required = false,
                                 default = nil)
  if valid_601929 != nil:
    section.add "X-Amz-SignedHeaders", valid_601929
  var valid_601930 = header.getOrDefault("X-Amz-Credential")
  valid_601930 = validateParameter(valid_601930, JString, required = false,
                                 default = nil)
  if valid_601930 != nil:
    section.add "X-Amz-Credential", valid_601930
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes.0.value: JString
  ##   Attributes.0.key: JString
  ##   Attributes.1.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   EndpointArn: JString (required)
  ##              : EndpointArn used for SetEndpointAttributes action.
  ##   Attributes.1.value: JString
  section = newJObject()
  var valid_601931 = formData.getOrDefault("Attributes.0.value")
  valid_601931 = validateParameter(valid_601931, JString, required = false,
                                 default = nil)
  if valid_601931 != nil:
    section.add "Attributes.0.value", valid_601931
  var valid_601932 = formData.getOrDefault("Attributes.0.key")
  valid_601932 = validateParameter(valid_601932, JString, required = false,
                                 default = nil)
  if valid_601932 != nil:
    section.add "Attributes.0.key", valid_601932
  var valid_601933 = formData.getOrDefault("Attributes.1.key")
  valid_601933 = validateParameter(valid_601933, JString, required = false,
                                 default = nil)
  if valid_601933 != nil:
    section.add "Attributes.1.key", valid_601933
  var valid_601934 = formData.getOrDefault("Attributes.2.value")
  valid_601934 = validateParameter(valid_601934, JString, required = false,
                                 default = nil)
  if valid_601934 != nil:
    section.add "Attributes.2.value", valid_601934
  var valid_601935 = formData.getOrDefault("Attributes.2.key")
  valid_601935 = validateParameter(valid_601935, JString, required = false,
                                 default = nil)
  if valid_601935 != nil:
    section.add "Attributes.2.key", valid_601935
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_601936 = formData.getOrDefault("EndpointArn")
  valid_601936 = validateParameter(valid_601936, JString, required = true,
                                 default = nil)
  if valid_601936 != nil:
    section.add "EndpointArn", valid_601936
  var valid_601937 = formData.getOrDefault("Attributes.1.value")
  valid_601937 = validateParameter(valid_601937, JString, required = false,
                                 default = nil)
  if valid_601937 != nil:
    section.add "Attributes.1.value", valid_601937
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601938: Call_PostSetEndpointAttributes_601919; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_601938.validator(path, query, header, formData, body)
  let scheme = call_601938.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601938.url(scheme.get, call_601938.host, call_601938.base,
                         call_601938.route, valid.getOrDefault("path"))
  result = hook(call_601938, url, valid)

proc call*(call_601939: Call_PostSetEndpointAttributes_601919; EndpointArn: string;
          Attributes0Value: string = ""; Attributes0Key: string = "";
          Attributes1Key: string = ""; Action: string = "SetEndpointAttributes";
          Attributes2Value: string = ""; Attributes2Key: string = "";
          Version: string = "2010-03-31"; Attributes1Value: string = ""): Recallable =
  ## postSetEndpointAttributes
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Attributes0Value: string
  ##   Attributes0Key: string
  ##   Attributes1Key: string
  ##   Action: string (required)
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   EndpointArn: string (required)
  ##              : EndpointArn used for SetEndpointAttributes action.
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_601940 = newJObject()
  var formData_601941 = newJObject()
  add(formData_601941, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_601941, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_601941, "Attributes.1.key", newJString(Attributes1Key))
  add(query_601940, "Action", newJString(Action))
  add(formData_601941, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_601941, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_601941, "EndpointArn", newJString(EndpointArn))
  add(query_601940, "Version", newJString(Version))
  add(formData_601941, "Attributes.1.value", newJString(Attributes1Value))
  result = call_601939.call(nil, query_601940, nil, formData_601941, nil)

var postSetEndpointAttributes* = Call_PostSetEndpointAttributes_601919(
    name: "postSetEndpointAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetEndpointAttributes",
    validator: validate_PostSetEndpointAttributes_601920, base: "/",
    url: url_PostSetEndpointAttributes_601921,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetEndpointAttributes_601897 = ref object of OpenApiRestCall_600426
proc url_GetSetEndpointAttributes_601899(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetEndpointAttributes_601898(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn used for SetEndpointAttributes action.
  ##   Attributes.2.key: JString
  ##   Attributes.1.value: JString
  ##   Attributes.0.value: JString
  ##   Action: JString (required)
  ##   Attributes.1.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.0.key: JString
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `EndpointArn` field"
  var valid_601900 = query.getOrDefault("EndpointArn")
  valid_601900 = validateParameter(valid_601900, JString, required = true,
                                 default = nil)
  if valid_601900 != nil:
    section.add "EndpointArn", valid_601900
  var valid_601901 = query.getOrDefault("Attributes.2.key")
  valid_601901 = validateParameter(valid_601901, JString, required = false,
                                 default = nil)
  if valid_601901 != nil:
    section.add "Attributes.2.key", valid_601901
  var valid_601902 = query.getOrDefault("Attributes.1.value")
  valid_601902 = validateParameter(valid_601902, JString, required = false,
                                 default = nil)
  if valid_601902 != nil:
    section.add "Attributes.1.value", valid_601902
  var valid_601903 = query.getOrDefault("Attributes.0.value")
  valid_601903 = validateParameter(valid_601903, JString, required = false,
                                 default = nil)
  if valid_601903 != nil:
    section.add "Attributes.0.value", valid_601903
  var valid_601904 = query.getOrDefault("Action")
  valid_601904 = validateParameter(valid_601904, JString, required = true,
                                 default = newJString("SetEndpointAttributes"))
  if valid_601904 != nil:
    section.add "Action", valid_601904
  var valid_601905 = query.getOrDefault("Attributes.1.key")
  valid_601905 = validateParameter(valid_601905, JString, required = false,
                                 default = nil)
  if valid_601905 != nil:
    section.add "Attributes.1.key", valid_601905
  var valid_601906 = query.getOrDefault("Attributes.2.value")
  valid_601906 = validateParameter(valid_601906, JString, required = false,
                                 default = nil)
  if valid_601906 != nil:
    section.add "Attributes.2.value", valid_601906
  var valid_601907 = query.getOrDefault("Attributes.0.key")
  valid_601907 = validateParameter(valid_601907, JString, required = false,
                                 default = nil)
  if valid_601907 != nil:
    section.add "Attributes.0.key", valid_601907
  var valid_601908 = query.getOrDefault("Version")
  valid_601908 = validateParameter(valid_601908, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601908 != nil:
    section.add "Version", valid_601908
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601909 = header.getOrDefault("X-Amz-Date")
  valid_601909 = validateParameter(valid_601909, JString, required = false,
                                 default = nil)
  if valid_601909 != nil:
    section.add "X-Amz-Date", valid_601909
  var valid_601910 = header.getOrDefault("X-Amz-Security-Token")
  valid_601910 = validateParameter(valid_601910, JString, required = false,
                                 default = nil)
  if valid_601910 != nil:
    section.add "X-Amz-Security-Token", valid_601910
  var valid_601911 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601911 = validateParameter(valid_601911, JString, required = false,
                                 default = nil)
  if valid_601911 != nil:
    section.add "X-Amz-Content-Sha256", valid_601911
  var valid_601912 = header.getOrDefault("X-Amz-Algorithm")
  valid_601912 = validateParameter(valid_601912, JString, required = false,
                                 default = nil)
  if valid_601912 != nil:
    section.add "X-Amz-Algorithm", valid_601912
  var valid_601913 = header.getOrDefault("X-Amz-Signature")
  valid_601913 = validateParameter(valid_601913, JString, required = false,
                                 default = nil)
  if valid_601913 != nil:
    section.add "X-Amz-Signature", valid_601913
  var valid_601914 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601914 = validateParameter(valid_601914, JString, required = false,
                                 default = nil)
  if valid_601914 != nil:
    section.add "X-Amz-SignedHeaders", valid_601914
  var valid_601915 = header.getOrDefault("X-Amz-Credential")
  valid_601915 = validateParameter(valid_601915, JString, required = false,
                                 default = nil)
  if valid_601915 != nil:
    section.add "X-Amz-Credential", valid_601915
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601916: Call_GetSetEndpointAttributes_601897; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_601916.validator(path, query, header, formData, body)
  let scheme = call_601916.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601916.url(scheme.get, call_601916.host, call_601916.base,
                         call_601916.route, valid.getOrDefault("path"))
  result = hook(call_601916, url, valid)

proc call*(call_601917: Call_GetSetEndpointAttributes_601897; EndpointArn: string;
          Attributes2Key: string = ""; Attributes1Value: string = "";
          Attributes0Value: string = ""; Action: string = "SetEndpointAttributes";
          Attributes1Key: string = ""; Attributes2Value: string = "";
          Attributes0Key: string = ""; Version: string = "2010-03-31"): Recallable =
  ## getSetEndpointAttributes
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as GCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   EndpointArn: string (required)
  ##              : EndpointArn used for SetEndpointAttributes action.
  ##   Attributes2Key: string
  ##   Attributes1Value: string
  ##   Attributes0Value: string
  ##   Action: string (required)
  ##   Attributes1Key: string
  ##   Attributes2Value: string
  ##   Attributes0Key: string
  ##   Version: string (required)
  var query_601918 = newJObject()
  add(query_601918, "EndpointArn", newJString(EndpointArn))
  add(query_601918, "Attributes.2.key", newJString(Attributes2Key))
  add(query_601918, "Attributes.1.value", newJString(Attributes1Value))
  add(query_601918, "Attributes.0.value", newJString(Attributes0Value))
  add(query_601918, "Action", newJString(Action))
  add(query_601918, "Attributes.1.key", newJString(Attributes1Key))
  add(query_601918, "Attributes.2.value", newJString(Attributes2Value))
  add(query_601918, "Attributes.0.key", newJString(Attributes0Key))
  add(query_601918, "Version", newJString(Version))
  result = call_601917.call(nil, query_601918, nil, nil, nil)

var getSetEndpointAttributes* = Call_GetSetEndpointAttributes_601897(
    name: "getSetEndpointAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetEndpointAttributes",
    validator: validate_GetSetEndpointAttributes_601898, base: "/",
    url: url_GetSetEndpointAttributes_601899, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetPlatformApplicationAttributes_601964 = ref object of OpenApiRestCall_600426
proc url_PostSetPlatformApplicationAttributes_601966(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetPlatformApplicationAttributes_601965(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601967 = query.getOrDefault("Action")
  valid_601967 = validateParameter(valid_601967, JString, required = true, default = newJString(
      "SetPlatformApplicationAttributes"))
  if valid_601967 != nil:
    section.add "Action", valid_601967
  var valid_601968 = query.getOrDefault("Version")
  valid_601968 = validateParameter(valid_601968, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601968 != nil:
    section.add "Version", valid_601968
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601969 = header.getOrDefault("X-Amz-Date")
  valid_601969 = validateParameter(valid_601969, JString, required = false,
                                 default = nil)
  if valid_601969 != nil:
    section.add "X-Amz-Date", valid_601969
  var valid_601970 = header.getOrDefault("X-Amz-Security-Token")
  valid_601970 = validateParameter(valid_601970, JString, required = false,
                                 default = nil)
  if valid_601970 != nil:
    section.add "X-Amz-Security-Token", valid_601970
  var valid_601971 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601971 = validateParameter(valid_601971, JString, required = false,
                                 default = nil)
  if valid_601971 != nil:
    section.add "X-Amz-Content-Sha256", valid_601971
  var valid_601972 = header.getOrDefault("X-Amz-Algorithm")
  valid_601972 = validateParameter(valid_601972, JString, required = false,
                                 default = nil)
  if valid_601972 != nil:
    section.add "X-Amz-Algorithm", valid_601972
  var valid_601973 = header.getOrDefault("X-Amz-Signature")
  valid_601973 = validateParameter(valid_601973, JString, required = false,
                                 default = nil)
  if valid_601973 != nil:
    section.add "X-Amz-Signature", valid_601973
  var valid_601974 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601974 = validateParameter(valid_601974, JString, required = false,
                                 default = nil)
  if valid_601974 != nil:
    section.add "X-Amz-SignedHeaders", valid_601974
  var valid_601975 = header.getOrDefault("X-Amz-Credential")
  valid_601975 = validateParameter(valid_601975, JString, required = false,
                                 default = nil)
  if valid_601975 != nil:
    section.add "X-Amz-Credential", valid_601975
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes.0.value: JString
  ##   Attributes.0.key: JString
  ##   Attributes.1.key: JString
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for SetPlatformApplicationAttributes action.
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   Attributes.1.value: JString
  section = newJObject()
  var valid_601976 = formData.getOrDefault("Attributes.0.value")
  valid_601976 = validateParameter(valid_601976, JString, required = false,
                                 default = nil)
  if valid_601976 != nil:
    section.add "Attributes.0.value", valid_601976
  var valid_601977 = formData.getOrDefault("Attributes.0.key")
  valid_601977 = validateParameter(valid_601977, JString, required = false,
                                 default = nil)
  if valid_601977 != nil:
    section.add "Attributes.0.key", valid_601977
  var valid_601978 = formData.getOrDefault("Attributes.1.key")
  valid_601978 = validateParameter(valid_601978, JString, required = false,
                                 default = nil)
  if valid_601978 != nil:
    section.add "Attributes.1.key", valid_601978
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_601979 = formData.getOrDefault("PlatformApplicationArn")
  valid_601979 = validateParameter(valid_601979, JString, required = true,
                                 default = nil)
  if valid_601979 != nil:
    section.add "PlatformApplicationArn", valid_601979
  var valid_601980 = formData.getOrDefault("Attributes.2.value")
  valid_601980 = validateParameter(valid_601980, JString, required = false,
                                 default = nil)
  if valid_601980 != nil:
    section.add "Attributes.2.value", valid_601980
  var valid_601981 = formData.getOrDefault("Attributes.2.key")
  valid_601981 = validateParameter(valid_601981, JString, required = false,
                                 default = nil)
  if valid_601981 != nil:
    section.add "Attributes.2.key", valid_601981
  var valid_601982 = formData.getOrDefault("Attributes.1.value")
  valid_601982 = validateParameter(valid_601982, JString, required = false,
                                 default = nil)
  if valid_601982 != nil:
    section.add "Attributes.1.value", valid_601982
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601983: Call_PostSetPlatformApplicationAttributes_601964;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  let valid = call_601983.validator(path, query, header, formData, body)
  let scheme = call_601983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601983.url(scheme.get, call_601983.host, call_601983.base,
                         call_601983.route, valid.getOrDefault("path"))
  result = hook(call_601983, url, valid)

proc call*(call_601984: Call_PostSetPlatformApplicationAttributes_601964;
          PlatformApplicationArn: string; Attributes0Value: string = "";
          Attributes0Key: string = ""; Attributes1Key: string = "";
          Action: string = "SetPlatformApplicationAttributes";
          Attributes2Value: string = ""; Attributes2Key: string = "";
          Version: string = "2010-03-31"; Attributes1Value: string = ""): Recallable =
  ## postSetPlatformApplicationAttributes
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ##   Attributes0Value: string
  ##   Attributes0Key: string
  ##   Attributes1Key: string
  ##   Action: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for SetPlatformApplicationAttributes action.
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_601985 = newJObject()
  var formData_601986 = newJObject()
  add(formData_601986, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_601986, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_601986, "Attributes.1.key", newJString(Attributes1Key))
  add(query_601985, "Action", newJString(Action))
  add(formData_601986, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(formData_601986, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_601986, "Attributes.2.key", newJString(Attributes2Key))
  add(query_601985, "Version", newJString(Version))
  add(formData_601986, "Attributes.1.value", newJString(Attributes1Value))
  result = call_601984.call(nil, query_601985, nil, formData_601986, nil)

var postSetPlatformApplicationAttributes* = Call_PostSetPlatformApplicationAttributes_601964(
    name: "postSetPlatformApplicationAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetPlatformApplicationAttributes",
    validator: validate_PostSetPlatformApplicationAttributes_601965, base: "/",
    url: url_PostSetPlatformApplicationAttributes_601966,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetPlatformApplicationAttributes_601942 = ref object of OpenApiRestCall_600426
proc url_GetSetPlatformApplicationAttributes_601944(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetPlatformApplicationAttributes_601943(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes.2.key: JString
  ##   Attributes.1.value: JString
  ##   Attributes.0.value: JString
  ##   Action: JString (required)
  ##   Attributes.1.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.0.key: JString
  ##   Version: JString (required)
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for SetPlatformApplicationAttributes action.
  section = newJObject()
  var valid_601945 = query.getOrDefault("Attributes.2.key")
  valid_601945 = validateParameter(valid_601945, JString, required = false,
                                 default = nil)
  if valid_601945 != nil:
    section.add "Attributes.2.key", valid_601945
  var valid_601946 = query.getOrDefault("Attributes.1.value")
  valid_601946 = validateParameter(valid_601946, JString, required = false,
                                 default = nil)
  if valid_601946 != nil:
    section.add "Attributes.1.value", valid_601946
  var valid_601947 = query.getOrDefault("Attributes.0.value")
  valid_601947 = validateParameter(valid_601947, JString, required = false,
                                 default = nil)
  if valid_601947 != nil:
    section.add "Attributes.0.value", valid_601947
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601948 = query.getOrDefault("Action")
  valid_601948 = validateParameter(valid_601948, JString, required = true, default = newJString(
      "SetPlatformApplicationAttributes"))
  if valid_601948 != nil:
    section.add "Action", valid_601948
  var valid_601949 = query.getOrDefault("Attributes.1.key")
  valid_601949 = validateParameter(valid_601949, JString, required = false,
                                 default = nil)
  if valid_601949 != nil:
    section.add "Attributes.1.key", valid_601949
  var valid_601950 = query.getOrDefault("Attributes.2.value")
  valid_601950 = validateParameter(valid_601950, JString, required = false,
                                 default = nil)
  if valid_601950 != nil:
    section.add "Attributes.2.value", valid_601950
  var valid_601951 = query.getOrDefault("Attributes.0.key")
  valid_601951 = validateParameter(valid_601951, JString, required = false,
                                 default = nil)
  if valid_601951 != nil:
    section.add "Attributes.0.key", valid_601951
  var valid_601952 = query.getOrDefault("Version")
  valid_601952 = validateParameter(valid_601952, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601952 != nil:
    section.add "Version", valid_601952
  var valid_601953 = query.getOrDefault("PlatformApplicationArn")
  valid_601953 = validateParameter(valid_601953, JString, required = true,
                                 default = nil)
  if valid_601953 != nil:
    section.add "PlatformApplicationArn", valid_601953
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601954 = header.getOrDefault("X-Amz-Date")
  valid_601954 = validateParameter(valid_601954, JString, required = false,
                                 default = nil)
  if valid_601954 != nil:
    section.add "X-Amz-Date", valid_601954
  var valid_601955 = header.getOrDefault("X-Amz-Security-Token")
  valid_601955 = validateParameter(valid_601955, JString, required = false,
                                 default = nil)
  if valid_601955 != nil:
    section.add "X-Amz-Security-Token", valid_601955
  var valid_601956 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601956 = validateParameter(valid_601956, JString, required = false,
                                 default = nil)
  if valid_601956 != nil:
    section.add "X-Amz-Content-Sha256", valid_601956
  var valid_601957 = header.getOrDefault("X-Amz-Algorithm")
  valid_601957 = validateParameter(valid_601957, JString, required = false,
                                 default = nil)
  if valid_601957 != nil:
    section.add "X-Amz-Algorithm", valid_601957
  var valid_601958 = header.getOrDefault("X-Amz-Signature")
  valid_601958 = validateParameter(valid_601958, JString, required = false,
                                 default = nil)
  if valid_601958 != nil:
    section.add "X-Amz-Signature", valid_601958
  var valid_601959 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601959 = validateParameter(valid_601959, JString, required = false,
                                 default = nil)
  if valid_601959 != nil:
    section.add "X-Amz-SignedHeaders", valid_601959
  var valid_601960 = header.getOrDefault("X-Amz-Credential")
  valid_601960 = validateParameter(valid_601960, JString, required = false,
                                 default = nil)
  if valid_601960 != nil:
    section.add "X-Amz-Credential", valid_601960
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601961: Call_GetSetPlatformApplicationAttributes_601942;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  let valid = call_601961.validator(path, query, header, formData, body)
  let scheme = call_601961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601961.url(scheme.get, call_601961.host, call_601961.base,
                         call_601961.route, valid.getOrDefault("path"))
  result = hook(call_601961, url, valid)

proc call*(call_601962: Call_GetSetPlatformApplicationAttributes_601942;
          PlatformApplicationArn: string; Attributes2Key: string = "";
          Attributes1Value: string = ""; Attributes0Value: string = "";
          Action: string = "SetPlatformApplicationAttributes";
          Attributes1Key: string = ""; Attributes2Value: string = "";
          Attributes0Key: string = ""; Version: string = "2010-03-31"): Recallable =
  ## getSetPlatformApplicationAttributes
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and GCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ##   Attributes2Key: string
  ##   Attributes1Value: string
  ##   Attributes0Value: string
  ##   Action: string (required)
  ##   Attributes1Key: string
  ##   Attributes2Value: string
  ##   Attributes0Key: string
  ##   Version: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for SetPlatformApplicationAttributes action.
  var query_601963 = newJObject()
  add(query_601963, "Attributes.2.key", newJString(Attributes2Key))
  add(query_601963, "Attributes.1.value", newJString(Attributes1Value))
  add(query_601963, "Attributes.0.value", newJString(Attributes0Value))
  add(query_601963, "Action", newJString(Action))
  add(query_601963, "Attributes.1.key", newJString(Attributes1Key))
  add(query_601963, "Attributes.2.value", newJString(Attributes2Value))
  add(query_601963, "Attributes.0.key", newJString(Attributes0Key))
  add(query_601963, "Version", newJString(Version))
  add(query_601963, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_601962.call(nil, query_601963, nil, nil, nil)

var getSetPlatformApplicationAttributes* = Call_GetSetPlatformApplicationAttributes_601942(
    name: "getSetPlatformApplicationAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetPlatformApplicationAttributes",
    validator: validate_GetSetPlatformApplicationAttributes_601943, base: "/",
    url: url_GetSetPlatformApplicationAttributes_601944,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSMSAttributes_602008 = ref object of OpenApiRestCall_600426
proc url_PostSetSMSAttributes_602010(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetSMSAttributes_602009(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602011 = query.getOrDefault("Action")
  valid_602011 = validateParameter(valid_602011, JString, required = true,
                                 default = newJString("SetSMSAttributes"))
  if valid_602011 != nil:
    section.add "Action", valid_602011
  var valid_602012 = query.getOrDefault("Version")
  valid_602012 = validateParameter(valid_602012, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602012 != nil:
    section.add "Version", valid_602012
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602013 = header.getOrDefault("X-Amz-Date")
  valid_602013 = validateParameter(valid_602013, JString, required = false,
                                 default = nil)
  if valid_602013 != nil:
    section.add "X-Amz-Date", valid_602013
  var valid_602014 = header.getOrDefault("X-Amz-Security-Token")
  valid_602014 = validateParameter(valid_602014, JString, required = false,
                                 default = nil)
  if valid_602014 != nil:
    section.add "X-Amz-Security-Token", valid_602014
  var valid_602015 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-Content-Sha256", valid_602015
  var valid_602016 = header.getOrDefault("X-Amz-Algorithm")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Algorithm", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Signature")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Signature", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-SignedHeaders", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Credential")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Credential", valid_602019
  result.add "header", section
  ## parameters in `formData` object:
  ##   attributes.2.value: JString
  ##   attributes.2.key: JString
  ##   attributes.1.value: JString
  ##   attributes.1.key: JString
  ##   attributes.0.key: JString
  ##   attributes.0.value: JString
  section = newJObject()
  var valid_602020 = formData.getOrDefault("attributes.2.value")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "attributes.2.value", valid_602020
  var valid_602021 = formData.getOrDefault("attributes.2.key")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "attributes.2.key", valid_602021
  var valid_602022 = formData.getOrDefault("attributes.1.value")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "attributes.1.value", valid_602022
  var valid_602023 = formData.getOrDefault("attributes.1.key")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "attributes.1.key", valid_602023
  var valid_602024 = formData.getOrDefault("attributes.0.key")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "attributes.0.key", valid_602024
  var valid_602025 = formData.getOrDefault("attributes.0.value")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "attributes.0.value", valid_602025
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602026: Call_PostSetSMSAttributes_602008; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_602026.validator(path, query, header, formData, body)
  let scheme = call_602026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602026.url(scheme.get, call_602026.host, call_602026.base,
                         call_602026.route, valid.getOrDefault("path"))
  result = hook(call_602026, url, valid)

proc call*(call_602027: Call_PostSetSMSAttributes_602008;
          attributes2Value: string = ""; attributes2Key: string = "";
          Action: string = "SetSMSAttributes"; attributes1Value: string = "";
          attributes1Key: string = ""; attributes0Key: string = "";
          Version: string = "2010-03-31"; attributes0Value: string = ""): Recallable =
  ## postSetSMSAttributes
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ##   attributes2Value: string
  ##   attributes2Key: string
  ##   Action: string (required)
  ##   attributes1Value: string
  ##   attributes1Key: string
  ##   attributes0Key: string
  ##   Version: string (required)
  ##   attributes0Value: string
  var query_602028 = newJObject()
  var formData_602029 = newJObject()
  add(formData_602029, "attributes.2.value", newJString(attributes2Value))
  add(formData_602029, "attributes.2.key", newJString(attributes2Key))
  add(query_602028, "Action", newJString(Action))
  add(formData_602029, "attributes.1.value", newJString(attributes1Value))
  add(formData_602029, "attributes.1.key", newJString(attributes1Key))
  add(formData_602029, "attributes.0.key", newJString(attributes0Key))
  add(query_602028, "Version", newJString(Version))
  add(formData_602029, "attributes.0.value", newJString(attributes0Value))
  result = call_602027.call(nil, query_602028, nil, formData_602029, nil)

var postSetSMSAttributes* = Call_PostSetSMSAttributes_602008(
    name: "postSetSMSAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetSMSAttributes",
    validator: validate_PostSetSMSAttributes_602009, base: "/",
    url: url_PostSetSMSAttributes_602010, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSMSAttributes_601987 = ref object of OpenApiRestCall_600426
proc url_GetSetSMSAttributes_601989(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetSMSAttributes_601988(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   attributes.2.key: JString
  ##   attributes.1.key: JString
  ##   Action: JString (required)
  ##   attributes.1.value: JString
  ##   attributes.0.value: JString
  ##   attributes.2.value: JString
  ##   attributes.0.key: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_601990 = query.getOrDefault("attributes.2.key")
  valid_601990 = validateParameter(valid_601990, JString, required = false,
                                 default = nil)
  if valid_601990 != nil:
    section.add "attributes.2.key", valid_601990
  var valid_601991 = query.getOrDefault("attributes.1.key")
  valid_601991 = validateParameter(valid_601991, JString, required = false,
                                 default = nil)
  if valid_601991 != nil:
    section.add "attributes.1.key", valid_601991
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601992 = query.getOrDefault("Action")
  valid_601992 = validateParameter(valid_601992, JString, required = true,
                                 default = newJString("SetSMSAttributes"))
  if valid_601992 != nil:
    section.add "Action", valid_601992
  var valid_601993 = query.getOrDefault("attributes.1.value")
  valid_601993 = validateParameter(valid_601993, JString, required = false,
                                 default = nil)
  if valid_601993 != nil:
    section.add "attributes.1.value", valid_601993
  var valid_601994 = query.getOrDefault("attributes.0.value")
  valid_601994 = validateParameter(valid_601994, JString, required = false,
                                 default = nil)
  if valid_601994 != nil:
    section.add "attributes.0.value", valid_601994
  var valid_601995 = query.getOrDefault("attributes.2.value")
  valid_601995 = validateParameter(valid_601995, JString, required = false,
                                 default = nil)
  if valid_601995 != nil:
    section.add "attributes.2.value", valid_601995
  var valid_601996 = query.getOrDefault("attributes.0.key")
  valid_601996 = validateParameter(valid_601996, JString, required = false,
                                 default = nil)
  if valid_601996 != nil:
    section.add "attributes.0.key", valid_601996
  var valid_601997 = query.getOrDefault("Version")
  valid_601997 = validateParameter(valid_601997, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601997 != nil:
    section.add "Version", valid_601997
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601998 = header.getOrDefault("X-Amz-Date")
  valid_601998 = validateParameter(valid_601998, JString, required = false,
                                 default = nil)
  if valid_601998 != nil:
    section.add "X-Amz-Date", valid_601998
  var valid_601999 = header.getOrDefault("X-Amz-Security-Token")
  valid_601999 = validateParameter(valid_601999, JString, required = false,
                                 default = nil)
  if valid_601999 != nil:
    section.add "X-Amz-Security-Token", valid_601999
  var valid_602000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = nil)
  if valid_602000 != nil:
    section.add "X-Amz-Content-Sha256", valid_602000
  var valid_602001 = header.getOrDefault("X-Amz-Algorithm")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Algorithm", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Signature")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Signature", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-SignedHeaders", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Credential")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Credential", valid_602004
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602005: Call_GetSetSMSAttributes_601987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_602005.validator(path, query, header, formData, body)
  let scheme = call_602005.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602005.url(scheme.get, call_602005.host, call_602005.base,
                         call_602005.route, valid.getOrDefault("path"))
  result = hook(call_602005, url, valid)

proc call*(call_602006: Call_GetSetSMSAttributes_601987;
          attributes2Key: string = ""; attributes1Key: string = "";
          Action: string = "SetSMSAttributes"; attributes1Value: string = "";
          attributes0Value: string = ""; attributes2Value: string = "";
          attributes0Key: string = ""; Version: string = "2010-03-31"): Recallable =
  ## getSetSMSAttributes
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ##   attributes2Key: string
  ##   attributes1Key: string
  ##   Action: string (required)
  ##   attributes1Value: string
  ##   attributes0Value: string
  ##   attributes2Value: string
  ##   attributes0Key: string
  ##   Version: string (required)
  var query_602007 = newJObject()
  add(query_602007, "attributes.2.key", newJString(attributes2Key))
  add(query_602007, "attributes.1.key", newJString(attributes1Key))
  add(query_602007, "Action", newJString(Action))
  add(query_602007, "attributes.1.value", newJString(attributes1Value))
  add(query_602007, "attributes.0.value", newJString(attributes0Value))
  add(query_602007, "attributes.2.value", newJString(attributes2Value))
  add(query_602007, "attributes.0.key", newJString(attributes0Key))
  add(query_602007, "Version", newJString(Version))
  result = call_602006.call(nil, query_602007, nil, nil, nil)

var getSetSMSAttributes* = Call_GetSetSMSAttributes_601987(
    name: "getSetSMSAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetSMSAttributes",
    validator: validate_GetSetSMSAttributes_601988, base: "/",
    url: url_GetSetSMSAttributes_601989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSubscriptionAttributes_602048 = ref object of OpenApiRestCall_600426
proc url_PostSetSubscriptionAttributes_602050(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetSubscriptionAttributes_602049(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602051 = query.getOrDefault("Action")
  valid_602051 = validateParameter(valid_602051, JString, required = true, default = newJString(
      "SetSubscriptionAttributes"))
  if valid_602051 != nil:
    section.add "Action", valid_602051
  var valid_602052 = query.getOrDefault("Version")
  valid_602052 = validateParameter(valid_602052, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602052 != nil:
    section.add "Version", valid_602052
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602053 = header.getOrDefault("X-Amz-Date")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "X-Amz-Date", valid_602053
  var valid_602054 = header.getOrDefault("X-Amz-Security-Token")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "X-Amz-Security-Token", valid_602054
  var valid_602055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "X-Amz-Content-Sha256", valid_602055
  var valid_602056 = header.getOrDefault("X-Amz-Algorithm")
  valid_602056 = validateParameter(valid_602056, JString, required = false,
                                 default = nil)
  if valid_602056 != nil:
    section.add "X-Amz-Algorithm", valid_602056
  var valid_602057 = header.getOrDefault("X-Amz-Signature")
  valid_602057 = validateParameter(valid_602057, JString, required = false,
                                 default = nil)
  if valid_602057 != nil:
    section.add "X-Amz-Signature", valid_602057
  var valid_602058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602058 = validateParameter(valid_602058, JString, required = false,
                                 default = nil)
  if valid_602058 != nil:
    section.add "X-Amz-SignedHeaders", valid_602058
  var valid_602059 = header.getOrDefault("X-Amz-Credential")
  valid_602059 = validateParameter(valid_602059, JString, required = false,
                                 default = nil)
  if valid_602059 != nil:
    section.add "X-Amz-Credential", valid_602059
  result.add "header", section
  ## parameters in `formData` object:
  ##   AttributeName: JString (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>FilterPolicy</code> – The simple JSON object that lets your subscriber receive only a subset of messages, rather than receiving every message published to the topic.</p> </li> <li> <p> <code>RawMessageDelivery</code> – When set to <code>true</code>, enables raw message delivery to Amazon SQS or HTTP/S endpoints. This eliminates the need for the endpoints to process JSON formatting, which is otherwise created for Amazon SNS metadata.</p> </li> </ul>
  ##   AttributeValue: JString
  ##                 : The new value for the attribute in JSON format.
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription to modify.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AttributeName` field"
  var valid_602060 = formData.getOrDefault("AttributeName")
  valid_602060 = validateParameter(valid_602060, JString, required = true,
                                 default = nil)
  if valid_602060 != nil:
    section.add "AttributeName", valid_602060
  var valid_602061 = formData.getOrDefault("AttributeValue")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "AttributeValue", valid_602061
  var valid_602062 = formData.getOrDefault("SubscriptionArn")
  valid_602062 = validateParameter(valid_602062, JString, required = true,
                                 default = nil)
  if valid_602062 != nil:
    section.add "SubscriptionArn", valid_602062
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602063: Call_PostSetSubscriptionAttributes_602048; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ## 
  let valid = call_602063.validator(path, query, header, formData, body)
  let scheme = call_602063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602063.url(scheme.get, call_602063.host, call_602063.base,
                         call_602063.route, valid.getOrDefault("path"))
  result = hook(call_602063, url, valid)

proc call*(call_602064: Call_PostSetSubscriptionAttributes_602048;
          AttributeName: string; SubscriptionArn: string;
          AttributeValue: string = ""; Action: string = "SetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postSetSubscriptionAttributes
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ##   AttributeName: string (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>FilterPolicy</code> – The simple JSON object that lets your subscriber receive only a subset of messages, rather than receiving every message published to the topic.</p> </li> <li> <p> <code>RawMessageDelivery</code> – When set to <code>true</code>, enables raw message delivery to Amazon SQS or HTTP/S endpoints. This eliminates the need for the endpoints to process JSON formatting, which is otherwise created for Amazon SNS metadata.</p> </li> </ul>
  ##   AttributeValue: string
  ##                 : The new value for the attribute in JSON format.
  ##   Action: string (required)
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to modify.
  ##   Version: string (required)
  var query_602065 = newJObject()
  var formData_602066 = newJObject()
  add(formData_602066, "AttributeName", newJString(AttributeName))
  add(formData_602066, "AttributeValue", newJString(AttributeValue))
  add(query_602065, "Action", newJString(Action))
  add(formData_602066, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_602065, "Version", newJString(Version))
  result = call_602064.call(nil, query_602065, nil, formData_602066, nil)

var postSetSubscriptionAttributes* = Call_PostSetSubscriptionAttributes_602048(
    name: "postSetSubscriptionAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetSubscriptionAttributes",
    validator: validate_PostSetSubscriptionAttributes_602049, base: "/",
    url: url_PostSetSubscriptionAttributes_602050,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSubscriptionAttributes_602030 = ref object of OpenApiRestCall_600426
proc url_GetSetSubscriptionAttributes_602032(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetSubscriptionAttributes_602031(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription to modify.
  ##   AttributeName: JString (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>FilterPolicy</code> – The simple JSON object that lets your subscriber receive only a subset of messages, rather than receiving every message published to the topic.</p> </li> <li> <p> <code>RawMessageDelivery</code> – When set to <code>true</code>, enables raw message delivery to Amazon SQS or HTTP/S endpoints. This eliminates the need for the endpoints to process JSON formatting, which is otherwise created for Amazon SNS metadata.</p> </li> </ul>
  ##   Action: JString (required)
  ##   AttributeValue: JString
  ##                 : The new value for the attribute in JSON format.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SubscriptionArn` field"
  var valid_602033 = query.getOrDefault("SubscriptionArn")
  valid_602033 = validateParameter(valid_602033, JString, required = true,
                                 default = nil)
  if valid_602033 != nil:
    section.add "SubscriptionArn", valid_602033
  var valid_602034 = query.getOrDefault("AttributeName")
  valid_602034 = validateParameter(valid_602034, JString, required = true,
                                 default = nil)
  if valid_602034 != nil:
    section.add "AttributeName", valid_602034
  var valid_602035 = query.getOrDefault("Action")
  valid_602035 = validateParameter(valid_602035, JString, required = true, default = newJString(
      "SetSubscriptionAttributes"))
  if valid_602035 != nil:
    section.add "Action", valid_602035
  var valid_602036 = query.getOrDefault("AttributeValue")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "AttributeValue", valid_602036
  var valid_602037 = query.getOrDefault("Version")
  valid_602037 = validateParameter(valid_602037, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602037 != nil:
    section.add "Version", valid_602037
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602038 = header.getOrDefault("X-Amz-Date")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-Date", valid_602038
  var valid_602039 = header.getOrDefault("X-Amz-Security-Token")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-Security-Token", valid_602039
  var valid_602040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "X-Amz-Content-Sha256", valid_602040
  var valid_602041 = header.getOrDefault("X-Amz-Algorithm")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-Algorithm", valid_602041
  var valid_602042 = header.getOrDefault("X-Amz-Signature")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "X-Amz-Signature", valid_602042
  var valid_602043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "X-Amz-SignedHeaders", valid_602043
  var valid_602044 = header.getOrDefault("X-Amz-Credential")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "X-Amz-Credential", valid_602044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602045: Call_GetSetSubscriptionAttributes_602030; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ## 
  let valid = call_602045.validator(path, query, header, formData, body)
  let scheme = call_602045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602045.url(scheme.get, call_602045.host, call_602045.base,
                         call_602045.route, valid.getOrDefault("path"))
  result = hook(call_602045, url, valid)

proc call*(call_602046: Call_GetSetSubscriptionAttributes_602030;
          SubscriptionArn: string; AttributeName: string;
          Action: string = "SetSubscriptionAttributes"; AttributeValue: string = "";
          Version: string = "2010-03-31"): Recallable =
  ## getSetSubscriptionAttributes
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to modify.
  ##   AttributeName: string (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>FilterPolicy</code> – The simple JSON object that lets your subscriber receive only a subset of messages, rather than receiving every message published to the topic.</p> </li> <li> <p> <code>RawMessageDelivery</code> – When set to <code>true</code>, enables raw message delivery to Amazon SQS or HTTP/S endpoints. This eliminates the need for the endpoints to process JSON formatting, which is otherwise created for Amazon SNS metadata.</p> </li> </ul>
  ##   Action: string (required)
  ##   AttributeValue: string
  ##                 : The new value for the attribute in JSON format.
  ##   Version: string (required)
  var query_602047 = newJObject()
  add(query_602047, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_602047, "AttributeName", newJString(AttributeName))
  add(query_602047, "Action", newJString(Action))
  add(query_602047, "AttributeValue", newJString(AttributeValue))
  add(query_602047, "Version", newJString(Version))
  result = call_602046.call(nil, query_602047, nil, nil, nil)

var getSetSubscriptionAttributes* = Call_GetSetSubscriptionAttributes_602030(
    name: "getSetSubscriptionAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetSubscriptionAttributes",
    validator: validate_GetSetSubscriptionAttributes_602031, base: "/",
    url: url_GetSetSubscriptionAttributes_602032,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetTopicAttributes_602085 = ref object of OpenApiRestCall_600426
proc url_PostSetTopicAttributes_602087(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSetTopicAttributes_602086(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602088 = query.getOrDefault("Action")
  valid_602088 = validateParameter(valid_602088, JString, required = true,
                                 default = newJString("SetTopicAttributes"))
  if valid_602088 != nil:
    section.add "Action", valid_602088
  var valid_602089 = query.getOrDefault("Version")
  valid_602089 = validateParameter(valid_602089, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602089 != nil:
    section.add "Version", valid_602089
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602090 = header.getOrDefault("X-Amz-Date")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Date", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Security-Token")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Security-Token", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Content-Sha256", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-Algorithm")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Algorithm", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-Signature")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-Signature", valid_602094
  var valid_602095 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-SignedHeaders", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-Credential")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-Credential", valid_602096
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic to modify.
  ##   AttributeName: JString (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>DisplayName</code> – The display name to use for a topic with SMS subscriptions.</p> </li> <li> <p> <code>Policy</code> – The policy that defines who can access your topic. By default, only the topic owner can publish or subscribe to the topic.</p> </li> </ul> <p>The following attribute applies only to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html">server-side-encryption</a>:</p> <ul> <li> <p> <code>KmsMasterKeyId</code> - The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK. For more information, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms">Key Terms</a>. For more examples, see <a 
  ## href="https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters">KeyId</a> in the <i>AWS Key Management Service API Reference</i>. </p> </li> </ul>
  ##   AttributeValue: JString
  ##                 : The new value for the attribute.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_602097 = formData.getOrDefault("TopicArn")
  valid_602097 = validateParameter(valid_602097, JString, required = true,
                                 default = nil)
  if valid_602097 != nil:
    section.add "TopicArn", valid_602097
  var valid_602098 = formData.getOrDefault("AttributeName")
  valid_602098 = validateParameter(valid_602098, JString, required = true,
                                 default = nil)
  if valid_602098 != nil:
    section.add "AttributeName", valid_602098
  var valid_602099 = formData.getOrDefault("AttributeValue")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "AttributeValue", valid_602099
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602100: Call_PostSetTopicAttributes_602085; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  let valid = call_602100.validator(path, query, header, formData, body)
  let scheme = call_602100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602100.url(scheme.get, call_602100.host, call_602100.base,
                         call_602100.route, valid.getOrDefault("path"))
  result = hook(call_602100, url, valid)

proc call*(call_602101: Call_PostSetTopicAttributes_602085; TopicArn: string;
          AttributeName: string; AttributeValue: string = "";
          Action: string = "SetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## postSetTopicAttributes
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic to modify.
  ##   AttributeName: string (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>DisplayName</code> – The display name to use for a topic with SMS subscriptions.</p> </li> <li> <p> <code>Policy</code> – The policy that defines who can access your topic. By default, only the topic owner can publish or subscribe to the topic.</p> </li> </ul> <p>The following attribute applies only to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html">server-side-encryption</a>:</p> <ul> <li> <p> <code>KmsMasterKeyId</code> - The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK. For more information, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms">Key Terms</a>. For more examples, see <a 
  ## href="https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters">KeyId</a> in the <i>AWS Key Management Service API Reference</i>. </p> </li> </ul>
  ##   AttributeValue: string
  ##                 : The new value for the attribute.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602102 = newJObject()
  var formData_602103 = newJObject()
  add(formData_602103, "TopicArn", newJString(TopicArn))
  add(formData_602103, "AttributeName", newJString(AttributeName))
  add(formData_602103, "AttributeValue", newJString(AttributeValue))
  add(query_602102, "Action", newJString(Action))
  add(query_602102, "Version", newJString(Version))
  result = call_602101.call(nil, query_602102, nil, formData_602103, nil)

var postSetTopicAttributes* = Call_PostSetTopicAttributes_602085(
    name: "postSetTopicAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetTopicAttributes",
    validator: validate_PostSetTopicAttributes_602086, base: "/",
    url: url_PostSetTopicAttributes_602087, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetTopicAttributes_602067 = ref object of OpenApiRestCall_600426
proc url_GetSetTopicAttributes_602069(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSetTopicAttributes_602068(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   AttributeName: JString (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>DisplayName</code> – The display name to use for a topic with SMS subscriptions.</p> </li> <li> <p> <code>Policy</code> – The policy that defines who can access your topic. By default, only the topic owner can publish or subscribe to the topic.</p> </li> </ul> <p>The following attribute applies only to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html">server-side-encryption</a>:</p> <ul> <li> <p> <code>KmsMasterKeyId</code> - The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK. For more information, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms">Key Terms</a>. For more examples, see <a 
  ## href="https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters">KeyId</a> in the <i>AWS Key Management Service API Reference</i>. </p> </li> </ul>
  ##   Action: JString (required)
  ##   AttributeValue: JString
  ##                 : The new value for the attribute.
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic to modify.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `AttributeName` field"
  var valid_602070 = query.getOrDefault("AttributeName")
  valid_602070 = validateParameter(valid_602070, JString, required = true,
                                 default = nil)
  if valid_602070 != nil:
    section.add "AttributeName", valid_602070
  var valid_602071 = query.getOrDefault("Action")
  valid_602071 = validateParameter(valid_602071, JString, required = true,
                                 default = newJString("SetTopicAttributes"))
  if valid_602071 != nil:
    section.add "Action", valid_602071
  var valid_602072 = query.getOrDefault("AttributeValue")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "AttributeValue", valid_602072
  var valid_602073 = query.getOrDefault("TopicArn")
  valid_602073 = validateParameter(valid_602073, JString, required = true,
                                 default = nil)
  if valid_602073 != nil:
    section.add "TopicArn", valid_602073
  var valid_602074 = query.getOrDefault("Version")
  valid_602074 = validateParameter(valid_602074, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602074 != nil:
    section.add "Version", valid_602074
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602075 = header.getOrDefault("X-Amz-Date")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Date", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Security-Token")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Security-Token", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Content-Sha256", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Algorithm")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Algorithm", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Signature")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Signature", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-SignedHeaders", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-Credential")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-Credential", valid_602081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602082: Call_GetSetTopicAttributes_602067; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  let valid = call_602082.validator(path, query, header, formData, body)
  let scheme = call_602082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602082.url(scheme.get, call_602082.host, call_602082.base,
                         call_602082.route, valid.getOrDefault("path"))
  result = hook(call_602082, url, valid)

proc call*(call_602083: Call_GetSetTopicAttributes_602067; AttributeName: string;
          TopicArn: string; Action: string = "SetTopicAttributes";
          AttributeValue: string = ""; Version: string = "2010-03-31"): Recallable =
  ## getSetTopicAttributes
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ##   AttributeName: string (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>DisplayName</code> – The display name to use for a topic with SMS subscriptions.</p> </li> <li> <p> <code>Policy</code> – The policy that defines who can access your topic. By default, only the topic owner can publish or subscribe to the topic.</p> </li> </ul> <p>The following attribute applies only to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html">server-side-encryption</a>:</p> <ul> <li> <p> <code>KmsMasterKeyId</code> - The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK. For more information, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms">Key Terms</a>. For more examples, see <a 
  ## href="https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters">KeyId</a> in the <i>AWS Key Management Service API Reference</i>. </p> </li> </ul>
  ##   Action: string (required)
  ##   AttributeValue: string
  ##                 : The new value for the attribute.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic to modify.
  ##   Version: string (required)
  var query_602084 = newJObject()
  add(query_602084, "AttributeName", newJString(AttributeName))
  add(query_602084, "Action", newJString(Action))
  add(query_602084, "AttributeValue", newJString(AttributeValue))
  add(query_602084, "TopicArn", newJString(TopicArn))
  add(query_602084, "Version", newJString(Version))
  result = call_602083.call(nil, query_602084, nil, nil, nil)

var getSetTopicAttributes* = Call_GetSetTopicAttributes_602067(
    name: "getSetTopicAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetTopicAttributes",
    validator: validate_GetSetTopicAttributes_602068, base: "/",
    url: url_GetSetTopicAttributes_602069, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSubscribe_602129 = ref object of OpenApiRestCall_600426
proc url_PostSubscribe_602131(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSubscribe_602130(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602132 = query.getOrDefault("Action")
  valid_602132 = validateParameter(valid_602132, JString, required = true,
                                 default = newJString("Subscribe"))
  if valid_602132 != nil:
    section.add "Action", valid_602132
  var valid_602133 = query.getOrDefault("Version")
  valid_602133 = validateParameter(valid_602133, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602133 != nil:
    section.add "Version", valid_602133
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602134 = header.getOrDefault("X-Amz-Date")
  valid_602134 = validateParameter(valid_602134, JString, required = false,
                                 default = nil)
  if valid_602134 != nil:
    section.add "X-Amz-Date", valid_602134
  var valid_602135 = header.getOrDefault("X-Amz-Security-Token")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "X-Amz-Security-Token", valid_602135
  var valid_602136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Content-Sha256", valid_602136
  var valid_602137 = header.getOrDefault("X-Amz-Algorithm")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-Algorithm", valid_602137
  var valid_602138 = header.getOrDefault("X-Amz-Signature")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Signature", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-SignedHeaders", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Credential")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Credential", valid_602140
  result.add "header", section
  ## parameters in `formData` object:
  ##   Endpoint: JString
  ##           : <p>The endpoint that you want to receive notifications. Endpoints vary by protocol:</p> <ul> <li> <p>For the <code>http</code> protocol, the endpoint is an URL beginning with "https://"</p> </li> <li> <p>For the <code>https</code> protocol, the endpoint is a URL beginning with "https://"</p> </li> <li> <p>For the <code>email</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>email-json</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>sms</code> protocol, the endpoint is a phone number of an SMS-enabled device</p> </li> <li> <p>For the <code>sqs</code> protocol, the endpoint is the ARN of an Amazon SQS queue</p> </li> <li> <p>For the <code>application</code> protocol, the endpoint is the EndpointArn of a mobile app and device.</p> </li> <li> <p>For the <code>lambda</code> protocol, the endpoint is the ARN of an AWS Lambda function.</p> </li> </ul>
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic you want to subscribe to.
  ##   Attributes.0.value: JString
  ##   Protocol: JString (required)
  ##           : <p>The protocol you want to use. Supported protocols include:</p> <ul> <li> <p> <code>http</code> – delivery of JSON-encoded message via HTTP POST</p> </li> <li> <p> <code>https</code> – delivery of JSON-encoded message via HTTPS POST</p> </li> <li> <p> <code>email</code> – delivery of message via SMTP</p> </li> <li> <p> <code>email-json</code> – delivery of JSON-encoded message via SMTP</p> </li> <li> <p> <code>sms</code> – delivery of message via SMS</p> </li> <li> <p> <code>sqs</code> – delivery of JSON-encoded message to an Amazon SQS queue</p> </li> <li> <p> <code>application</code> – delivery of JSON-encoded message to an EndpointArn for a mobile app and device.</p> </li> <li> <p> <code>lambda</code> – delivery of JSON-encoded message to an AWS Lambda function.</p> </li> </ul>
  ##   Attributes.0.key: JString
  ##   Attributes.1.key: JString
  ##   ReturnSubscriptionArn: JBool
  ##                        : <p>Sets whether the response from the <code>Subscribe</code> request includes the subscription ARN, even if the subscription is not yet confirmed.</p> <p>If you set this parameter to <code>false</code>, the response includes the ARN for confirmed subscriptions, but it includes an ARN value of "pending subscription" for subscriptions that are not yet confirmed. A subscription becomes confirmed when the subscriber calls the <code>ConfirmSubscription</code> action with a confirmation token.</p> <p>If you set this parameter to <code>true</code>, the response includes the ARN in all cases, even if the subscription is not yet confirmed.</p> <p>The default value is <code>false</code>.</p>
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   Attributes.1.value: JString
  section = newJObject()
  var valid_602141 = formData.getOrDefault("Endpoint")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "Endpoint", valid_602141
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_602142 = formData.getOrDefault("TopicArn")
  valid_602142 = validateParameter(valid_602142, JString, required = true,
                                 default = nil)
  if valid_602142 != nil:
    section.add "TopicArn", valid_602142
  var valid_602143 = formData.getOrDefault("Attributes.0.value")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "Attributes.0.value", valid_602143
  var valid_602144 = formData.getOrDefault("Protocol")
  valid_602144 = validateParameter(valid_602144, JString, required = true,
                                 default = nil)
  if valid_602144 != nil:
    section.add "Protocol", valid_602144
  var valid_602145 = formData.getOrDefault("Attributes.0.key")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "Attributes.0.key", valid_602145
  var valid_602146 = formData.getOrDefault("Attributes.1.key")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "Attributes.1.key", valid_602146
  var valid_602147 = formData.getOrDefault("ReturnSubscriptionArn")
  valid_602147 = validateParameter(valid_602147, JBool, required = false, default = nil)
  if valid_602147 != nil:
    section.add "ReturnSubscriptionArn", valid_602147
  var valid_602148 = formData.getOrDefault("Attributes.2.value")
  valid_602148 = validateParameter(valid_602148, JString, required = false,
                                 default = nil)
  if valid_602148 != nil:
    section.add "Attributes.2.value", valid_602148
  var valid_602149 = formData.getOrDefault("Attributes.2.key")
  valid_602149 = validateParameter(valid_602149, JString, required = false,
                                 default = nil)
  if valid_602149 != nil:
    section.add "Attributes.2.key", valid_602149
  var valid_602150 = formData.getOrDefault("Attributes.1.value")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "Attributes.1.value", valid_602150
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602151: Call_PostSubscribe_602129; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_602151.validator(path, query, header, formData, body)
  let scheme = call_602151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602151.url(scheme.get, call_602151.host, call_602151.base,
                         call_602151.route, valid.getOrDefault("path"))
  result = hook(call_602151, url, valid)

proc call*(call_602152: Call_PostSubscribe_602129; TopicArn: string;
          Protocol: string; Endpoint: string = ""; Attributes0Value: string = "";
          Attributes0Key: string = ""; Attributes1Key: string = "";
          ReturnSubscriptionArn: bool = false; Action: string = "Subscribe";
          Attributes2Value: string = ""; Attributes2Key: string = "";
          Version: string = "2010-03-31"; Attributes1Value: string = ""): Recallable =
  ## postSubscribe
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   Endpoint: string
  ##           : <p>The endpoint that you want to receive notifications. Endpoints vary by protocol:</p> <ul> <li> <p>For the <code>http</code> protocol, the endpoint is an URL beginning with "https://"</p> </li> <li> <p>For the <code>https</code> protocol, the endpoint is a URL beginning with "https://"</p> </li> <li> <p>For the <code>email</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>email-json</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>sms</code> protocol, the endpoint is a phone number of an SMS-enabled device</p> </li> <li> <p>For the <code>sqs</code> protocol, the endpoint is the ARN of an Amazon SQS queue</p> </li> <li> <p>For the <code>application</code> protocol, the endpoint is the EndpointArn of a mobile app and device.</p> </li> <li> <p>For the <code>lambda</code> protocol, the endpoint is the ARN of an AWS Lambda function.</p> </li> </ul>
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to subscribe to.
  ##   Attributes0Value: string
  ##   Protocol: string (required)
  ##           : <p>The protocol you want to use. Supported protocols include:</p> <ul> <li> <p> <code>http</code> – delivery of JSON-encoded message via HTTP POST</p> </li> <li> <p> <code>https</code> – delivery of JSON-encoded message via HTTPS POST</p> </li> <li> <p> <code>email</code> – delivery of message via SMTP</p> </li> <li> <p> <code>email-json</code> – delivery of JSON-encoded message via SMTP</p> </li> <li> <p> <code>sms</code> – delivery of message via SMS</p> </li> <li> <p> <code>sqs</code> – delivery of JSON-encoded message to an Amazon SQS queue</p> </li> <li> <p> <code>application</code> – delivery of JSON-encoded message to an EndpointArn for a mobile app and device.</p> </li> <li> <p> <code>lambda</code> – delivery of JSON-encoded message to an AWS Lambda function.</p> </li> </ul>
  ##   Attributes0Key: string
  ##   Attributes1Key: string
  ##   ReturnSubscriptionArn: bool
  ##                        : <p>Sets whether the response from the <code>Subscribe</code> request includes the subscription ARN, even if the subscription is not yet confirmed.</p> <p>If you set this parameter to <code>false</code>, the response includes the ARN for confirmed subscriptions, but it includes an ARN value of "pending subscription" for subscriptions that are not yet confirmed. A subscription becomes confirmed when the subscriber calls the <code>ConfirmSubscription</code> action with a confirmation token.</p> <p>If you set this parameter to <code>true</code>, the response includes the ARN in all cases, even if the subscription is not yet confirmed.</p> <p>The default value is <code>false</code>.</p>
  ##   Action: string (required)
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_602153 = newJObject()
  var formData_602154 = newJObject()
  add(formData_602154, "Endpoint", newJString(Endpoint))
  add(formData_602154, "TopicArn", newJString(TopicArn))
  add(formData_602154, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_602154, "Protocol", newJString(Protocol))
  add(formData_602154, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_602154, "Attributes.1.key", newJString(Attributes1Key))
  add(formData_602154, "ReturnSubscriptionArn", newJBool(ReturnSubscriptionArn))
  add(query_602153, "Action", newJString(Action))
  add(formData_602154, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_602154, "Attributes.2.key", newJString(Attributes2Key))
  add(query_602153, "Version", newJString(Version))
  add(formData_602154, "Attributes.1.value", newJString(Attributes1Value))
  result = call_602152.call(nil, query_602153, nil, formData_602154, nil)

var postSubscribe* = Call_PostSubscribe_602129(name: "postSubscribe",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=Subscribe", validator: validate_PostSubscribe_602130,
    base: "/", url: url_PostSubscribe_602131, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSubscribe_602104 = ref object of OpenApiRestCall_600426
proc url_GetSubscribe_602106(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSubscribe_602105(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes.2.key: JString
  ##   Endpoint: JString
  ##           : <p>The endpoint that you want to receive notifications. Endpoints vary by protocol:</p> <ul> <li> <p>For the <code>http</code> protocol, the endpoint is an URL beginning with "https://"</p> </li> <li> <p>For the <code>https</code> protocol, the endpoint is a URL beginning with "https://"</p> </li> <li> <p>For the <code>email</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>email-json</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>sms</code> protocol, the endpoint is a phone number of an SMS-enabled device</p> </li> <li> <p>For the <code>sqs</code> protocol, the endpoint is the ARN of an Amazon SQS queue</p> </li> <li> <p>For the <code>application</code> protocol, the endpoint is the EndpointArn of a mobile app and device.</p> </li> <li> <p>For the <code>lambda</code> protocol, the endpoint is the ARN of an AWS Lambda function.</p> </li> </ul>
  ##   Protocol: JString (required)
  ##           : <p>The protocol you want to use. Supported protocols include:</p> <ul> <li> <p> <code>http</code> – delivery of JSON-encoded message via HTTP POST</p> </li> <li> <p> <code>https</code> – delivery of JSON-encoded message via HTTPS POST</p> </li> <li> <p> <code>email</code> – delivery of message via SMTP</p> </li> <li> <p> <code>email-json</code> – delivery of JSON-encoded message via SMTP</p> </li> <li> <p> <code>sms</code> – delivery of message via SMS</p> </li> <li> <p> <code>sqs</code> – delivery of JSON-encoded message to an Amazon SQS queue</p> </li> <li> <p> <code>application</code> – delivery of JSON-encoded message to an EndpointArn for a mobile app and device.</p> </li> <li> <p> <code>lambda</code> – delivery of JSON-encoded message to an AWS Lambda function.</p> </li> </ul>
  ##   Attributes.1.value: JString
  ##   Attributes.0.value: JString
  ##   Action: JString (required)
  ##   ReturnSubscriptionArn: JBool
  ##                        : <p>Sets whether the response from the <code>Subscribe</code> request includes the subscription ARN, even if the subscription is not yet confirmed.</p> <p>If you set this parameter to <code>false</code>, the response includes the ARN for confirmed subscriptions, but it includes an ARN value of "pending subscription" for subscriptions that are not yet confirmed. A subscription becomes confirmed when the subscriber calls the <code>ConfirmSubscription</code> action with a confirmation token.</p> <p>If you set this parameter to <code>true</code>, the response includes the ARN in all cases, even if the subscription is not yet confirmed.</p> <p>The default value is <code>false</code>.</p>
  ##   Attributes.1.key: JString
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic you want to subscribe to.
  ##   Attributes.2.value: JString
  ##   Attributes.0.key: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_602107 = query.getOrDefault("Attributes.2.key")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "Attributes.2.key", valid_602107
  var valid_602108 = query.getOrDefault("Endpoint")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "Endpoint", valid_602108
  assert query != nil,
        "query argument is necessary due to required `Protocol` field"
  var valid_602109 = query.getOrDefault("Protocol")
  valid_602109 = validateParameter(valid_602109, JString, required = true,
                                 default = nil)
  if valid_602109 != nil:
    section.add "Protocol", valid_602109
  var valid_602110 = query.getOrDefault("Attributes.1.value")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "Attributes.1.value", valid_602110
  var valid_602111 = query.getOrDefault("Attributes.0.value")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "Attributes.0.value", valid_602111
  var valid_602112 = query.getOrDefault("Action")
  valid_602112 = validateParameter(valid_602112, JString, required = true,
                                 default = newJString("Subscribe"))
  if valid_602112 != nil:
    section.add "Action", valid_602112
  var valid_602113 = query.getOrDefault("ReturnSubscriptionArn")
  valid_602113 = validateParameter(valid_602113, JBool, required = false, default = nil)
  if valid_602113 != nil:
    section.add "ReturnSubscriptionArn", valid_602113
  var valid_602114 = query.getOrDefault("Attributes.1.key")
  valid_602114 = validateParameter(valid_602114, JString, required = false,
                                 default = nil)
  if valid_602114 != nil:
    section.add "Attributes.1.key", valid_602114
  var valid_602115 = query.getOrDefault("TopicArn")
  valid_602115 = validateParameter(valid_602115, JString, required = true,
                                 default = nil)
  if valid_602115 != nil:
    section.add "TopicArn", valid_602115
  var valid_602116 = query.getOrDefault("Attributes.2.value")
  valid_602116 = validateParameter(valid_602116, JString, required = false,
                                 default = nil)
  if valid_602116 != nil:
    section.add "Attributes.2.value", valid_602116
  var valid_602117 = query.getOrDefault("Attributes.0.key")
  valid_602117 = validateParameter(valid_602117, JString, required = false,
                                 default = nil)
  if valid_602117 != nil:
    section.add "Attributes.0.key", valid_602117
  var valid_602118 = query.getOrDefault("Version")
  valid_602118 = validateParameter(valid_602118, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602118 != nil:
    section.add "Version", valid_602118
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602119 = header.getOrDefault("X-Amz-Date")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "X-Amz-Date", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-Security-Token")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-Security-Token", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Content-Sha256", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Algorithm")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Algorithm", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Signature")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Signature", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-SignedHeaders", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Credential")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Credential", valid_602125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602126: Call_GetSubscribe_602104; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_602126.validator(path, query, header, formData, body)
  let scheme = call_602126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602126.url(scheme.get, call_602126.host, call_602126.base,
                         call_602126.route, valid.getOrDefault("path"))
  result = hook(call_602126, url, valid)

proc call*(call_602127: Call_GetSubscribe_602104; Protocol: string; TopicArn: string;
          Attributes2Key: string = ""; Endpoint: string = "";
          Attributes1Value: string = ""; Attributes0Value: string = "";
          Action: string = "Subscribe"; ReturnSubscriptionArn: bool = false;
          Attributes1Key: string = ""; Attributes2Value: string = "";
          Attributes0Key: string = ""; Version: string = "2010-03-31"): Recallable =
  ## getSubscribe
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   Attributes2Key: string
  ##   Endpoint: string
  ##           : <p>The endpoint that you want to receive notifications. Endpoints vary by protocol:</p> <ul> <li> <p>For the <code>http</code> protocol, the endpoint is an URL beginning with "https://"</p> </li> <li> <p>For the <code>https</code> protocol, the endpoint is a URL beginning with "https://"</p> </li> <li> <p>For the <code>email</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>email-json</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>sms</code> protocol, the endpoint is a phone number of an SMS-enabled device</p> </li> <li> <p>For the <code>sqs</code> protocol, the endpoint is the ARN of an Amazon SQS queue</p> </li> <li> <p>For the <code>application</code> protocol, the endpoint is the EndpointArn of a mobile app and device.</p> </li> <li> <p>For the <code>lambda</code> protocol, the endpoint is the ARN of an AWS Lambda function.</p> </li> </ul>
  ##   Protocol: string (required)
  ##           : <p>The protocol you want to use. Supported protocols include:</p> <ul> <li> <p> <code>http</code> – delivery of JSON-encoded message via HTTP POST</p> </li> <li> <p> <code>https</code> – delivery of JSON-encoded message via HTTPS POST</p> </li> <li> <p> <code>email</code> – delivery of message via SMTP</p> </li> <li> <p> <code>email-json</code> – delivery of JSON-encoded message via SMTP</p> </li> <li> <p> <code>sms</code> – delivery of message via SMS</p> </li> <li> <p> <code>sqs</code> – delivery of JSON-encoded message to an Amazon SQS queue</p> </li> <li> <p> <code>application</code> – delivery of JSON-encoded message to an EndpointArn for a mobile app and device.</p> </li> <li> <p> <code>lambda</code> – delivery of JSON-encoded message to an AWS Lambda function.</p> </li> </ul>
  ##   Attributes1Value: string
  ##   Attributes0Value: string
  ##   Action: string (required)
  ##   ReturnSubscriptionArn: bool
  ##                        : <p>Sets whether the response from the <code>Subscribe</code> request includes the subscription ARN, even if the subscription is not yet confirmed.</p> <p>If you set this parameter to <code>false</code>, the response includes the ARN for confirmed subscriptions, but it includes an ARN value of "pending subscription" for subscriptions that are not yet confirmed. A subscription becomes confirmed when the subscriber calls the <code>ConfirmSubscription</code> action with a confirmation token.</p> <p>If you set this parameter to <code>true</code>, the response includes the ARN in all cases, even if the subscription is not yet confirmed.</p> <p>The default value is <code>false</code>.</p>
  ##   Attributes1Key: string
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to subscribe to.
  ##   Attributes2Value: string
  ##   Attributes0Key: string
  ##   Version: string (required)
  var query_602128 = newJObject()
  add(query_602128, "Attributes.2.key", newJString(Attributes2Key))
  add(query_602128, "Endpoint", newJString(Endpoint))
  add(query_602128, "Protocol", newJString(Protocol))
  add(query_602128, "Attributes.1.value", newJString(Attributes1Value))
  add(query_602128, "Attributes.0.value", newJString(Attributes0Value))
  add(query_602128, "Action", newJString(Action))
  add(query_602128, "ReturnSubscriptionArn", newJBool(ReturnSubscriptionArn))
  add(query_602128, "Attributes.1.key", newJString(Attributes1Key))
  add(query_602128, "TopicArn", newJString(TopicArn))
  add(query_602128, "Attributes.2.value", newJString(Attributes2Value))
  add(query_602128, "Attributes.0.key", newJString(Attributes0Key))
  add(query_602128, "Version", newJString(Version))
  result = call_602127.call(nil, query_602128, nil, nil, nil)

var getSubscribe* = Call_GetSubscribe_602104(name: "getSubscribe",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=Subscribe", validator: validate_GetSubscribe_602105, base: "/",
    url: url_GetSubscribe_602106, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTagResource_602172 = ref object of OpenApiRestCall_600426
proc url_PostTagResource_602174(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostTagResource_602173(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-limits.html#limits-topics">Limits Related to Topics</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602175 = query.getOrDefault("Action")
  valid_602175 = validateParameter(valid_602175, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_602175 != nil:
    section.add "Action", valid_602175
  var valid_602176 = query.getOrDefault("Version")
  valid_602176 = validateParameter(valid_602176, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602176 != nil:
    section.add "Version", valid_602176
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602177 = header.getOrDefault("X-Amz-Date")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "X-Amz-Date", valid_602177
  var valid_602178 = header.getOrDefault("X-Amz-Security-Token")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-Security-Token", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Content-Sha256", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-Algorithm")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Algorithm", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Signature")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Signature", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-SignedHeaders", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-Credential")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-Credential", valid_602183
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##       : The tags to be added to the specified topic. A tag consists of a required key and an optional value.
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic to which to add tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_602184 = formData.getOrDefault("Tags")
  valid_602184 = validateParameter(valid_602184, JArray, required = true, default = nil)
  if valid_602184 != nil:
    section.add "Tags", valid_602184
  var valid_602185 = formData.getOrDefault("ResourceArn")
  valid_602185 = validateParameter(valid_602185, JString, required = true,
                                 default = nil)
  if valid_602185 != nil:
    section.add "ResourceArn", valid_602185
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602186: Call_PostTagResource_602172; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-limits.html#limits-topics">Limits Related to Topics</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_602186.validator(path, query, header, formData, body)
  let scheme = call_602186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602186.url(scheme.get, call_602186.host, call_602186.base,
                         call_602186.route, valid.getOrDefault("path"))
  result = hook(call_602186, url, valid)

proc call*(call_602187: Call_PostTagResource_602172; Tags: JsonNode;
          ResourceArn: string; Action: string = "TagResource";
          Version: string = "2010-03-31"): Recallable =
  ## postTagResource
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-limits.html#limits-topics">Limits Related to Topics</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ##   Tags: JArray (required)
  ##       : The tags to be added to the specified topic. A tag consists of a required key and an optional value.
  ##   Action: string (required)
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic to which to add tags.
  ##   Version: string (required)
  var query_602188 = newJObject()
  var formData_602189 = newJObject()
  if Tags != nil:
    formData_602189.add "Tags", Tags
  add(query_602188, "Action", newJString(Action))
  add(formData_602189, "ResourceArn", newJString(ResourceArn))
  add(query_602188, "Version", newJString(Version))
  result = call_602187.call(nil, query_602188, nil, formData_602189, nil)

var postTagResource* = Call_PostTagResource_602172(name: "postTagResource",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_PostTagResource_602173,
    base: "/", url: url_PostTagResource_602174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagResource_602155 = ref object of OpenApiRestCall_600426
proc url_GetTagResource_602157(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetTagResource_602156(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-limits.html#limits-topics">Limits Related to Topics</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic to which to add tags.
  ##   Tags: JArray (required)
  ##       : The tags to be added to the specified topic. A tag consists of a required key and an optional value.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceArn` field"
  var valid_602158 = query.getOrDefault("ResourceArn")
  valid_602158 = validateParameter(valid_602158, JString, required = true,
                                 default = nil)
  if valid_602158 != nil:
    section.add "ResourceArn", valid_602158
  var valid_602159 = query.getOrDefault("Tags")
  valid_602159 = validateParameter(valid_602159, JArray, required = true, default = nil)
  if valid_602159 != nil:
    section.add "Tags", valid_602159
  var valid_602160 = query.getOrDefault("Action")
  valid_602160 = validateParameter(valid_602160, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_602160 != nil:
    section.add "Action", valid_602160
  var valid_602161 = query.getOrDefault("Version")
  valid_602161 = validateParameter(valid_602161, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602161 != nil:
    section.add "Version", valid_602161
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602162 = header.getOrDefault("X-Amz-Date")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-Date", valid_602162
  var valid_602163 = header.getOrDefault("X-Amz-Security-Token")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-Security-Token", valid_602163
  var valid_602164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "X-Amz-Content-Sha256", valid_602164
  var valid_602165 = header.getOrDefault("X-Amz-Algorithm")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "X-Amz-Algorithm", valid_602165
  var valid_602166 = header.getOrDefault("X-Amz-Signature")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-Signature", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-SignedHeaders", valid_602167
  var valid_602168 = header.getOrDefault("X-Amz-Credential")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-Credential", valid_602168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602169: Call_GetTagResource_602155; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-limits.html#limits-topics">Limits Related to Topics</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_602169.validator(path, query, header, formData, body)
  let scheme = call_602169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602169.url(scheme.get, call_602169.host, call_602169.base,
                         call_602169.route, valid.getOrDefault("path"))
  result = hook(call_602169, url, valid)

proc call*(call_602170: Call_GetTagResource_602155; ResourceArn: string;
          Tags: JsonNode; Action: string = "TagResource";
          Version: string = "2010-03-31"): Recallable =
  ## getTagResource
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul> <p>For a full list of tag restrictions, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-limits.html#limits-topics">Limits Related to Topics</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic to which to add tags.
  ##   Tags: JArray (required)
  ##       : The tags to be added to the specified topic. A tag consists of a required key and an optional value.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602171 = newJObject()
  add(query_602171, "ResourceArn", newJString(ResourceArn))
  if Tags != nil:
    query_602171.add "Tags", Tags
  add(query_602171, "Action", newJString(Action))
  add(query_602171, "Version", newJString(Version))
  result = call_602170.call(nil, query_602171, nil, nil, nil)

var getTagResource* = Call_GetTagResource_602155(name: "getTagResource",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_GetTagResource_602156,
    base: "/", url: url_GetTagResource_602157, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUnsubscribe_602206 = ref object of OpenApiRestCall_600426
proc url_PostUnsubscribe_602208(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUnsubscribe_602207(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602209 = query.getOrDefault("Action")
  valid_602209 = validateParameter(valid_602209, JString, required = true,
                                 default = newJString("Unsubscribe"))
  if valid_602209 != nil:
    section.add "Action", valid_602209
  var valid_602210 = query.getOrDefault("Version")
  valid_602210 = validateParameter(valid_602210, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602210 != nil:
    section.add "Version", valid_602210
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602211 = header.getOrDefault("X-Amz-Date")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-Date", valid_602211
  var valid_602212 = header.getOrDefault("X-Amz-Security-Token")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "X-Amz-Security-Token", valid_602212
  var valid_602213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "X-Amz-Content-Sha256", valid_602213
  var valid_602214 = header.getOrDefault("X-Amz-Algorithm")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "X-Amz-Algorithm", valid_602214
  var valid_602215 = header.getOrDefault("X-Amz-Signature")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "X-Amz-Signature", valid_602215
  var valid_602216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "X-Amz-SignedHeaders", valid_602216
  var valid_602217 = header.getOrDefault("X-Amz-Credential")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "X-Amz-Credential", valid_602217
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription to be deleted.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionArn` field"
  var valid_602218 = formData.getOrDefault("SubscriptionArn")
  valid_602218 = validateParameter(valid_602218, JString, required = true,
                                 default = nil)
  if valid_602218 != nil:
    section.add "SubscriptionArn", valid_602218
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602219: Call_PostUnsubscribe_602206; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_602219.validator(path, query, header, formData, body)
  let scheme = call_602219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602219.url(scheme.get, call_602219.host, call_602219.base,
                         call_602219.route, valid.getOrDefault("path"))
  result = hook(call_602219, url, valid)

proc call*(call_602220: Call_PostUnsubscribe_602206; SubscriptionArn: string;
          Action: string = "Unsubscribe"; Version: string = "2010-03-31"): Recallable =
  ## postUnsubscribe
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   Action: string (required)
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to be deleted.
  ##   Version: string (required)
  var query_602221 = newJObject()
  var formData_602222 = newJObject()
  add(query_602221, "Action", newJString(Action))
  add(formData_602222, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_602221, "Version", newJString(Version))
  result = call_602220.call(nil, query_602221, nil, formData_602222, nil)

var postUnsubscribe* = Call_PostUnsubscribe_602206(name: "postUnsubscribe",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=Unsubscribe", validator: validate_PostUnsubscribe_602207,
    base: "/", url: url_PostUnsubscribe_602208, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUnsubscribe_602190 = ref object of OpenApiRestCall_600426
proc url_GetUnsubscribe_602192(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUnsubscribe_602191(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription to be deleted.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SubscriptionArn` field"
  var valid_602193 = query.getOrDefault("SubscriptionArn")
  valid_602193 = validateParameter(valid_602193, JString, required = true,
                                 default = nil)
  if valid_602193 != nil:
    section.add "SubscriptionArn", valid_602193
  var valid_602194 = query.getOrDefault("Action")
  valid_602194 = validateParameter(valid_602194, JString, required = true,
                                 default = newJString("Unsubscribe"))
  if valid_602194 != nil:
    section.add "Action", valid_602194
  var valid_602195 = query.getOrDefault("Version")
  valid_602195 = validateParameter(valid_602195, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602195 != nil:
    section.add "Version", valid_602195
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602196 = header.getOrDefault("X-Amz-Date")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Date", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-Security-Token")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Security-Token", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-Content-Sha256", valid_602198
  var valid_602199 = header.getOrDefault("X-Amz-Algorithm")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-Algorithm", valid_602199
  var valid_602200 = header.getOrDefault("X-Amz-Signature")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-Signature", valid_602200
  var valid_602201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "X-Amz-SignedHeaders", valid_602201
  var valid_602202 = header.getOrDefault("X-Amz-Credential")
  valid_602202 = validateParameter(valid_602202, JString, required = false,
                                 default = nil)
  if valid_602202 != nil:
    section.add "X-Amz-Credential", valid_602202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602203: Call_GetUnsubscribe_602190; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_602203.validator(path, query, header, formData, body)
  let scheme = call_602203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602203.url(scheme.get, call_602203.host, call_602203.base,
                         call_602203.route, valid.getOrDefault("path"))
  result = hook(call_602203, url, valid)

proc call*(call_602204: Call_GetUnsubscribe_602190; SubscriptionArn: string;
          Action: string = "Unsubscribe"; Version: string = "2010-03-31"): Recallable =
  ## getUnsubscribe
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to be deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602205 = newJObject()
  add(query_602205, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_602205, "Action", newJString(Action))
  add(query_602205, "Version", newJString(Version))
  result = call_602204.call(nil, query_602205, nil, nil, nil)

var getUnsubscribe* = Call_GetUnsubscribe_602190(name: "getUnsubscribe",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=Unsubscribe", validator: validate_GetUnsubscribe_602191,
    base: "/", url: url_GetUnsubscribe_602192, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUntagResource_602240 = ref object of OpenApiRestCall_600426
proc url_PostUntagResource_602242(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUntagResource_602241(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602243 = query.getOrDefault("Action")
  valid_602243 = validateParameter(valid_602243, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_602243 != nil:
    section.add "Action", valid_602243
  var valid_602244 = query.getOrDefault("Version")
  valid_602244 = validateParameter(valid_602244, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602244 != nil:
    section.add "Version", valid_602244
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602245 = header.getOrDefault("X-Amz-Date")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-Date", valid_602245
  var valid_602246 = header.getOrDefault("X-Amz-Security-Token")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-Security-Token", valid_602246
  var valid_602247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = nil)
  if valid_602247 != nil:
    section.add "X-Amz-Content-Sha256", valid_602247
  var valid_602248 = header.getOrDefault("X-Amz-Algorithm")
  valid_602248 = validateParameter(valid_602248, JString, required = false,
                                 default = nil)
  if valid_602248 != nil:
    section.add "X-Amz-Algorithm", valid_602248
  var valid_602249 = header.getOrDefault("X-Amz-Signature")
  valid_602249 = validateParameter(valid_602249, JString, required = false,
                                 default = nil)
  if valid_602249 != nil:
    section.add "X-Amz-Signature", valid_602249
  var valid_602250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "X-Amz-SignedHeaders", valid_602250
  var valid_602251 = header.getOrDefault("X-Amz-Credential")
  valid_602251 = validateParameter(valid_602251, JString, required = false,
                                 default = nil)
  if valid_602251 != nil:
    section.add "X-Amz-Credential", valid_602251
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the specified topic.
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic from which to remove tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_602252 = formData.getOrDefault("TagKeys")
  valid_602252 = validateParameter(valid_602252, JArray, required = true, default = nil)
  if valid_602252 != nil:
    section.add "TagKeys", valid_602252
  var valid_602253 = formData.getOrDefault("ResourceArn")
  valid_602253 = validateParameter(valid_602253, JString, required = true,
                                 default = nil)
  if valid_602253 != nil:
    section.add "ResourceArn", valid_602253
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602254: Call_PostUntagResource_602240; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  let valid = call_602254.validator(path, query, header, formData, body)
  let scheme = call_602254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602254.url(scheme.get, call_602254.host, call_602254.base,
                         call_602254.route, valid.getOrDefault("path"))
  result = hook(call_602254, url, valid)

proc call*(call_602255: Call_PostUntagResource_602240; TagKeys: JsonNode;
          ResourceArn: string; Action: string = "UntagResource";
          Version: string = "2010-03-31"): Recallable =
  ## postUntagResource
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the specified topic.
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic from which to remove tags.
  ##   Version: string (required)
  var query_602256 = newJObject()
  var formData_602257 = newJObject()
  add(query_602256, "Action", newJString(Action))
  if TagKeys != nil:
    formData_602257.add "TagKeys", TagKeys
  add(formData_602257, "ResourceArn", newJString(ResourceArn))
  add(query_602256, "Version", newJString(Version))
  result = call_602255.call(nil, query_602256, nil, formData_602257, nil)

var postUntagResource* = Call_PostUntagResource_602240(name: "postUntagResource",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_PostUntagResource_602241,
    base: "/", url: url_PostUntagResource_602242,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUntagResource_602223 = ref object of OpenApiRestCall_600426
proc url_GetUntagResource_602225(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUntagResource_602224(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic from which to remove tags.
  ##   Action: JString (required)
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the specified topic.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceArn` field"
  var valid_602226 = query.getOrDefault("ResourceArn")
  valid_602226 = validateParameter(valid_602226, JString, required = true,
                                 default = nil)
  if valid_602226 != nil:
    section.add "ResourceArn", valid_602226
  var valid_602227 = query.getOrDefault("Action")
  valid_602227 = validateParameter(valid_602227, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_602227 != nil:
    section.add "Action", valid_602227
  var valid_602228 = query.getOrDefault("TagKeys")
  valid_602228 = validateParameter(valid_602228, JArray, required = true, default = nil)
  if valid_602228 != nil:
    section.add "TagKeys", valid_602228
  var valid_602229 = query.getOrDefault("Version")
  valid_602229 = validateParameter(valid_602229, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602229 != nil:
    section.add "Version", valid_602229
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602230 = header.getOrDefault("X-Amz-Date")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-Date", valid_602230
  var valid_602231 = header.getOrDefault("X-Amz-Security-Token")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-Security-Token", valid_602231
  var valid_602232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602232 = validateParameter(valid_602232, JString, required = false,
                                 default = nil)
  if valid_602232 != nil:
    section.add "X-Amz-Content-Sha256", valid_602232
  var valid_602233 = header.getOrDefault("X-Amz-Algorithm")
  valid_602233 = validateParameter(valid_602233, JString, required = false,
                                 default = nil)
  if valid_602233 != nil:
    section.add "X-Amz-Algorithm", valid_602233
  var valid_602234 = header.getOrDefault("X-Amz-Signature")
  valid_602234 = validateParameter(valid_602234, JString, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "X-Amz-Signature", valid_602234
  var valid_602235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "X-Amz-SignedHeaders", valid_602235
  var valid_602236 = header.getOrDefault("X-Amz-Credential")
  valid_602236 = validateParameter(valid_602236, JString, required = false,
                                 default = nil)
  if valid_602236 != nil:
    section.add "X-Amz-Credential", valid_602236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602237: Call_GetUntagResource_602223; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  let valid = call_602237.validator(path, query, header, formData, body)
  let scheme = call_602237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602237.url(scheme.get, call_602237.host, call_602237.base,
                         call_602237.route, valid.getOrDefault("path"))
  result = hook(call_602237, url, valid)

proc call*(call_602238: Call_GetUntagResource_602223; ResourceArn: string;
          TagKeys: JsonNode; Action: string = "UntagResource";
          Version: string = "2010-03-31"): Recallable =
  ## getUntagResource
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic from which to remove tags.
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the specified topic.
  ##   Version: string (required)
  var query_602239 = newJObject()
  add(query_602239, "ResourceArn", newJString(ResourceArn))
  add(query_602239, "Action", newJString(Action))
  if TagKeys != nil:
    query_602239.add "TagKeys", TagKeys
  add(query_602239, "Version", newJString(Version))
  result = call_602238.call(nil, query_602239, nil, nil, nil)

var getUntagResource* = Call_GetUntagResource_602223(name: "getUntagResource",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_GetUntagResource_602224,
    base: "/", url: url_GetUntagResource_602225,
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
