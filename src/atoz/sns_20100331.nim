
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_PostAddPermission_21626037 = ref object of OpenApiRestCall_21625435
proc url_PostAddPermission_21626039(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAddPermission_21626038(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626040 = query.getOrDefault("Action")
  valid_21626040 = validateParameter(valid_21626040, JString, required = true,
                                   default = newJString("AddPermission"))
  if valid_21626040 != nil:
    section.add "Action", valid_21626040
  var valid_21626041 = query.getOrDefault("Version")
  valid_21626041 = validateParameter(valid_21626041, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626041 != nil:
    section.add "Version", valid_21626041
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626042 = header.getOrDefault("X-Amz-Date")
  valid_21626042 = validateParameter(valid_21626042, JString, required = false,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "X-Amz-Date", valid_21626042
  var valid_21626043 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "X-Amz-Security-Token", valid_21626043
  var valid_21626044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626044 = validateParameter(valid_21626044, JString, required = false,
                                   default = nil)
  if valid_21626044 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626044
  var valid_21626045 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626045 = validateParameter(valid_21626045, JString, required = false,
                                   default = nil)
  if valid_21626045 != nil:
    section.add "X-Amz-Algorithm", valid_21626045
  var valid_21626046 = header.getOrDefault("X-Amz-Signature")
  valid_21626046 = validateParameter(valid_21626046, JString, required = false,
                                   default = nil)
  if valid_21626046 != nil:
    section.add "X-Amz-Signature", valid_21626046
  var valid_21626047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-Credential")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-Credential", valid_21626048
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   AWSAccountId: JArray (required)
  ##               : The AWS account IDs of the users (principals) who will be given access to the specified actions. The users must have AWS accounts, but do not need to be signed up for this service.
  ##   Label: JString (required)
  ##        : A unique identifier for the new policy statement.
  ##   ActionName: JArray (required)
  ##             : <p>The action you want to allow for the specified principal(s).</p> <p>Valid values: Any Amazon SNS action name, for example <code>Publish</code>.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_21626049 = formData.getOrDefault("TopicArn")
  valid_21626049 = validateParameter(valid_21626049, JString, required = true,
                                   default = nil)
  if valid_21626049 != nil:
    section.add "TopicArn", valid_21626049
  var valid_21626050 = formData.getOrDefault("AWSAccountId")
  valid_21626050 = validateParameter(valid_21626050, JArray, required = true,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "AWSAccountId", valid_21626050
  var valid_21626051 = formData.getOrDefault("Label")
  valid_21626051 = validateParameter(valid_21626051, JString, required = true,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "Label", valid_21626051
  var valid_21626052 = formData.getOrDefault("ActionName")
  valid_21626052 = validateParameter(valid_21626052, JArray, required = true,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "ActionName", valid_21626052
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626053: Call_PostAddPermission_21626037; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  let valid = call_21626053.validator(path, query, header, formData, body, _)
  let scheme = call_21626053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626053.makeUrl(scheme.get, call_21626053.host, call_21626053.base,
                               call_21626053.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626053, uri, valid, _)

proc call*(call_21626054: Call_PostAddPermission_21626037; TopicArn: string;
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
  ##             : <p>The action you want to allow for the specified principal(s).</p> <p>Valid values: Any Amazon SNS action name, for example <code>Publish</code>.</p>
  ##   Version: string (required)
  var query_21626055 = newJObject()
  var formData_21626056 = newJObject()
  add(formData_21626056, "TopicArn", newJString(TopicArn))
  if AWSAccountId != nil:
    formData_21626056.add "AWSAccountId", AWSAccountId
  add(formData_21626056, "Label", newJString(Label))
  add(query_21626055, "Action", newJString(Action))
  if ActionName != nil:
    formData_21626056.add "ActionName", ActionName
  add(query_21626055, "Version", newJString(Version))
  result = call_21626054.call(nil, query_21626055, nil, formData_21626056, nil)

var postAddPermission* = Call_PostAddPermission_21626037(name: "postAddPermission",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=AddPermission", validator: validate_PostAddPermission_21626038,
    base: "/", makeUrl: url_PostAddPermission_21626039,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddPermission_21625779 = ref object of OpenApiRestCall_21625435
proc url_GetAddPermission_21625781(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAddPermission_21625780(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ActionName: JArray (required)
  ##             : <p>The action you want to allow for the specified principal(s).</p> <p>Valid values: Any Amazon SNS action name, for example <code>Publish</code>.</p>
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
  var valid_21625882 = query.getOrDefault("ActionName")
  valid_21625882 = validateParameter(valid_21625882, JArray, required = true,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "ActionName", valid_21625882
  var valid_21625897 = query.getOrDefault("Action")
  valid_21625897 = validateParameter(valid_21625897, JString, required = true,
                                   default = newJString("AddPermission"))
  if valid_21625897 != nil:
    section.add "Action", valid_21625897
  var valid_21625898 = query.getOrDefault("TopicArn")
  valid_21625898 = validateParameter(valid_21625898, JString, required = true,
                                   default = nil)
  if valid_21625898 != nil:
    section.add "TopicArn", valid_21625898
  var valid_21625899 = query.getOrDefault("Version")
  valid_21625899 = validateParameter(valid_21625899, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21625899 != nil:
    section.add "Version", valid_21625899
  var valid_21625900 = query.getOrDefault("Label")
  valid_21625900 = validateParameter(valid_21625900, JString, required = true,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "Label", valid_21625900
  var valid_21625901 = query.getOrDefault("AWSAccountId")
  valid_21625901 = validateParameter(valid_21625901, JArray, required = true,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "AWSAccountId", valid_21625901
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21625902 = header.getOrDefault("X-Amz-Date")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-Date", valid_21625902
  var valid_21625903 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625903 = validateParameter(valid_21625903, JString, required = false,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "X-Amz-Security-Token", valid_21625903
  var valid_21625904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625904 = validateParameter(valid_21625904, JString, required = false,
                                   default = nil)
  if valid_21625904 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625904
  var valid_21625905 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625905 = validateParameter(valid_21625905, JString, required = false,
                                   default = nil)
  if valid_21625905 != nil:
    section.add "X-Amz-Algorithm", valid_21625905
  var valid_21625906 = header.getOrDefault("X-Amz-Signature")
  valid_21625906 = validateParameter(valid_21625906, JString, required = false,
                                   default = nil)
  if valid_21625906 != nil:
    section.add "X-Amz-Signature", valid_21625906
  var valid_21625907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625907 = validateParameter(valid_21625907, JString, required = false,
                                   default = nil)
  if valid_21625907 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625907
  var valid_21625908 = header.getOrDefault("X-Amz-Credential")
  valid_21625908 = validateParameter(valid_21625908, JString, required = false,
                                   default = nil)
  if valid_21625908 != nil:
    section.add "X-Amz-Credential", valid_21625908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625933: Call_GetAddPermission_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  let valid = call_21625933.validator(path, query, header, formData, body, _)
  let scheme = call_21625933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625933.makeUrl(scheme.get, call_21625933.host, call_21625933.base,
                               call_21625933.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625933, uri, valid, _)

proc call*(call_21625996: Call_GetAddPermission_21625779; ActionName: JsonNode;
          TopicArn: string; Label: string; AWSAccountId: JsonNode;
          Action: string = "AddPermission"; Version: string = "2010-03-31"): Recallable =
  ## getAddPermission
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ##   ActionName: JArray (required)
  ##             : <p>The action you want to allow for the specified principal(s).</p> <p>Valid values: Any Amazon SNS action name, for example <code>Publish</code>.</p>
  ##   Action: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Version: string (required)
  ##   Label: string (required)
  ##        : A unique identifier for the new policy statement.
  ##   AWSAccountId: JArray (required)
  ##               : The AWS account IDs of the users (principals) who will be given access to the specified actions. The users must have AWS accounts, but do not need to be signed up for this service.
  var query_21625998 = newJObject()
  if ActionName != nil:
    query_21625998.add "ActionName", ActionName
  add(query_21625998, "Action", newJString(Action))
  add(query_21625998, "TopicArn", newJString(TopicArn))
  add(query_21625998, "Version", newJString(Version))
  add(query_21625998, "Label", newJString(Label))
  if AWSAccountId != nil:
    query_21625998.add "AWSAccountId", AWSAccountId
  result = call_21625996.call(nil, query_21625998, nil, nil, nil)

var getAddPermission* = Call_GetAddPermission_21625779(name: "getAddPermission",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=AddPermission", validator: validate_GetAddPermission_21625780,
    base: "/", makeUrl: url_GetAddPermission_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCheckIfPhoneNumberIsOptedOut_21626073 = ref object of OpenApiRestCall_21625435
proc url_PostCheckIfPhoneNumberIsOptedOut_21626075(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCheckIfPhoneNumberIsOptedOut_21626074(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626076 = query.getOrDefault("Action")
  valid_21626076 = validateParameter(valid_21626076, JString, required = true, default = newJString(
      "CheckIfPhoneNumberIsOptedOut"))
  if valid_21626076 != nil:
    section.add "Action", valid_21626076
  var valid_21626077 = query.getOrDefault("Version")
  valid_21626077 = validateParameter(valid_21626077, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626077 != nil:
    section.add "Version", valid_21626077
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626078 = header.getOrDefault("X-Amz-Date")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-Date", valid_21626078
  var valid_21626079 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626079 = validateParameter(valid_21626079, JString, required = false,
                                   default = nil)
  if valid_21626079 != nil:
    section.add "X-Amz-Security-Token", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-Algorithm", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Signature")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Signature", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Credential")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Credential", valid_21626084
  result.add "header", section
  ## parameters in `formData` object:
  ##   phoneNumber: JString (required)
  ##              : The phone number for which you want to check the opt out status.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `phoneNumber` field"
  var valid_21626085 = formData.getOrDefault("phoneNumber")
  valid_21626085 = validateParameter(valid_21626085, JString, required = true,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "phoneNumber", valid_21626085
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626086: Call_PostCheckIfPhoneNumberIsOptedOut_21626073;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ## 
  let valid = call_21626086.validator(path, query, header, formData, body, _)
  let scheme = call_21626086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626086.makeUrl(scheme.get, call_21626086.host, call_21626086.base,
                               call_21626086.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626086, uri, valid, _)

proc call*(call_21626087: Call_PostCheckIfPhoneNumberIsOptedOut_21626073;
          phoneNumber: string; Action: string = "CheckIfPhoneNumberIsOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## postCheckIfPhoneNumberIsOptedOut
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ##   Action: string (required)
  ##   phoneNumber: string (required)
  ##              : The phone number for which you want to check the opt out status.
  ##   Version: string (required)
  var query_21626088 = newJObject()
  var formData_21626089 = newJObject()
  add(query_21626088, "Action", newJString(Action))
  add(formData_21626089, "phoneNumber", newJString(phoneNumber))
  add(query_21626088, "Version", newJString(Version))
  result = call_21626087.call(nil, query_21626088, nil, formData_21626089, nil)

var postCheckIfPhoneNumberIsOptedOut* = Call_PostCheckIfPhoneNumberIsOptedOut_21626073(
    name: "postCheckIfPhoneNumberIsOptedOut", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CheckIfPhoneNumberIsOptedOut",
    validator: validate_PostCheckIfPhoneNumberIsOptedOut_21626074, base: "/",
    makeUrl: url_PostCheckIfPhoneNumberIsOptedOut_21626075,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCheckIfPhoneNumberIsOptedOut_21626057 = ref object of OpenApiRestCall_21625435
proc url_GetCheckIfPhoneNumberIsOptedOut_21626059(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCheckIfPhoneNumberIsOptedOut_21626058(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626060 = query.getOrDefault("phoneNumber")
  valid_21626060 = validateParameter(valid_21626060, JString, required = true,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "phoneNumber", valid_21626060
  var valid_21626061 = query.getOrDefault("Action")
  valid_21626061 = validateParameter(valid_21626061, JString, required = true, default = newJString(
      "CheckIfPhoneNumberIsOptedOut"))
  if valid_21626061 != nil:
    section.add "Action", valid_21626061
  var valid_21626062 = query.getOrDefault("Version")
  valid_21626062 = validateParameter(valid_21626062, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626062 != nil:
    section.add "Version", valid_21626062
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626063 = header.getOrDefault("X-Amz-Date")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Date", valid_21626063
  var valid_21626064 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626064 = validateParameter(valid_21626064, JString, required = false,
                                   default = nil)
  if valid_21626064 != nil:
    section.add "X-Amz-Security-Token", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Algorithm", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Signature")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Signature", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-Credential")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Credential", valid_21626069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626070: Call_GetCheckIfPhoneNumberIsOptedOut_21626057;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ## 
  let valid = call_21626070.validator(path, query, header, formData, body, _)
  let scheme = call_21626070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626070.makeUrl(scheme.get, call_21626070.host, call_21626070.base,
                               call_21626070.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626070, uri, valid, _)

proc call*(call_21626071: Call_GetCheckIfPhoneNumberIsOptedOut_21626057;
          phoneNumber: string; Action: string = "CheckIfPhoneNumberIsOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## getCheckIfPhoneNumberIsOptedOut
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number for which you want to check the opt out status.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626072 = newJObject()
  add(query_21626072, "phoneNumber", newJString(phoneNumber))
  add(query_21626072, "Action", newJString(Action))
  add(query_21626072, "Version", newJString(Version))
  result = call_21626071.call(nil, query_21626072, nil, nil, nil)

var getCheckIfPhoneNumberIsOptedOut* = Call_GetCheckIfPhoneNumberIsOptedOut_21626057(
    name: "getCheckIfPhoneNumberIsOptedOut", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CheckIfPhoneNumberIsOptedOut",
    validator: validate_GetCheckIfPhoneNumberIsOptedOut_21626058, base: "/",
    makeUrl: url_GetCheckIfPhoneNumberIsOptedOut_21626059,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostConfirmSubscription_21626109 = ref object of OpenApiRestCall_21625435
proc url_PostConfirmSubscription_21626111(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostConfirmSubscription_21626110(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626112 = query.getOrDefault("Action")
  valid_21626112 = validateParameter(valid_21626112, JString, required = true,
                                   default = newJString("ConfirmSubscription"))
  if valid_21626112 != nil:
    section.add "Action", valid_21626112
  var valid_21626113 = query.getOrDefault("Version")
  valid_21626113 = validateParameter(valid_21626113, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626113 != nil:
    section.add "Version", valid_21626113
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626114 = header.getOrDefault("X-Amz-Date")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Date", valid_21626114
  var valid_21626115 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626115 = validateParameter(valid_21626115, JString, required = false,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "X-Amz-Security-Token", valid_21626115
  var valid_21626116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626116 = validateParameter(valid_21626116, JString, required = false,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626116
  var valid_21626117 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626117 = validateParameter(valid_21626117, JString, required = false,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "X-Amz-Algorithm", valid_21626117
  var valid_21626118 = header.getOrDefault("X-Amz-Signature")
  valid_21626118 = validateParameter(valid_21626118, JString, required = false,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "X-Amz-Signature", valid_21626118
  var valid_21626119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626119 = validateParameter(valid_21626119, JString, required = false,
                                   default = nil)
  if valid_21626119 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626119
  var valid_21626120 = header.getOrDefault("X-Amz-Credential")
  valid_21626120 = validateParameter(valid_21626120, JString, required = false,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "X-Amz-Credential", valid_21626120
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
  var valid_21626121 = formData.getOrDefault("TopicArn")
  valid_21626121 = validateParameter(valid_21626121, JString, required = true,
                                   default = nil)
  if valid_21626121 != nil:
    section.add "TopicArn", valid_21626121
  var valid_21626122 = formData.getOrDefault("AuthenticateOnUnsubscribe")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "AuthenticateOnUnsubscribe", valid_21626122
  var valid_21626123 = formData.getOrDefault("Token")
  valid_21626123 = validateParameter(valid_21626123, JString, required = true,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "Token", valid_21626123
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626124: Call_PostConfirmSubscription_21626109;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  let valid = call_21626124.validator(path, query, header, formData, body, _)
  let scheme = call_21626124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626124.makeUrl(scheme.get, call_21626124.host, call_21626124.base,
                               call_21626124.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626124, uri, valid, _)

proc call*(call_21626125: Call_PostConfirmSubscription_21626109; TopicArn: string;
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
  var query_21626126 = newJObject()
  var formData_21626127 = newJObject()
  add(formData_21626127, "TopicArn", newJString(TopicArn))
  add(formData_21626127, "AuthenticateOnUnsubscribe",
      newJString(AuthenticateOnUnsubscribe))
  add(query_21626126, "Action", newJString(Action))
  add(query_21626126, "Version", newJString(Version))
  add(formData_21626127, "Token", newJString(Token))
  result = call_21626125.call(nil, query_21626126, nil, formData_21626127, nil)

var postConfirmSubscription* = Call_PostConfirmSubscription_21626109(
    name: "postConfirmSubscription", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ConfirmSubscription",
    validator: validate_PostConfirmSubscription_21626110, base: "/",
    makeUrl: url_PostConfirmSubscription_21626111,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfirmSubscription_21626090 = ref object of OpenApiRestCall_21625435
proc url_GetConfirmSubscription_21626092(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetConfirmSubscription_21626091(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626093 = query.getOrDefault("Token")
  valid_21626093 = validateParameter(valid_21626093, JString, required = true,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "Token", valid_21626093
  var valid_21626094 = query.getOrDefault("Action")
  valid_21626094 = validateParameter(valid_21626094, JString, required = true,
                                   default = newJString("ConfirmSubscription"))
  if valid_21626094 != nil:
    section.add "Action", valid_21626094
  var valid_21626095 = query.getOrDefault("TopicArn")
  valid_21626095 = validateParameter(valid_21626095, JString, required = true,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "TopicArn", valid_21626095
  var valid_21626096 = query.getOrDefault("AuthenticateOnUnsubscribe")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "AuthenticateOnUnsubscribe", valid_21626096
  var valid_21626097 = query.getOrDefault("Version")
  valid_21626097 = validateParameter(valid_21626097, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626097 != nil:
    section.add "Version", valid_21626097
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626098 = header.getOrDefault("X-Amz-Date")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-Date", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Security-Token", valid_21626099
  var valid_21626100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626100
  var valid_21626101 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "X-Amz-Algorithm", valid_21626101
  var valid_21626102 = header.getOrDefault("X-Amz-Signature")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "X-Amz-Signature", valid_21626102
  var valid_21626103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626103 = validateParameter(valid_21626103, JString, required = false,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626103
  var valid_21626104 = header.getOrDefault("X-Amz-Credential")
  valid_21626104 = validateParameter(valid_21626104, JString, required = false,
                                   default = nil)
  if valid_21626104 != nil:
    section.add "X-Amz-Credential", valid_21626104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626105: Call_GetConfirmSubscription_21626090;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  let valid = call_21626105.validator(path, query, header, formData, body, _)
  let scheme = call_21626105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626105.makeUrl(scheme.get, call_21626105.host, call_21626105.base,
                               call_21626105.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626105, uri, valid, _)

proc call*(call_21626106: Call_GetConfirmSubscription_21626090; Token: string;
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
  var query_21626107 = newJObject()
  add(query_21626107, "Token", newJString(Token))
  add(query_21626107, "Action", newJString(Action))
  add(query_21626107, "TopicArn", newJString(TopicArn))
  add(query_21626107, "AuthenticateOnUnsubscribe",
      newJString(AuthenticateOnUnsubscribe))
  add(query_21626107, "Version", newJString(Version))
  result = call_21626106.call(nil, query_21626107, nil, nil, nil)

var getConfirmSubscription* = Call_GetConfirmSubscription_21626090(
    name: "getConfirmSubscription", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ConfirmSubscription",
    validator: validate_GetConfirmSubscription_21626091, base: "/",
    makeUrl: url_GetConfirmSubscription_21626092,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformApplication_21626151 = ref object of OpenApiRestCall_21625435
proc url_PostCreatePlatformApplication_21626153(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreatePlatformApplication_21626152(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For FCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For FCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626154 = query.getOrDefault("Action")
  valid_21626154 = validateParameter(valid_21626154, JString, required = true, default = newJString(
      "CreatePlatformApplication"))
  if valid_21626154 != nil:
    section.add "Action", valid_21626154
  var valid_21626155 = query.getOrDefault("Version")
  valid_21626155 = validateParameter(valid_21626155, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626155 != nil:
    section.add "Version", valid_21626155
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626156 = header.getOrDefault("X-Amz-Date")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "X-Amz-Date", valid_21626156
  var valid_21626157 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "X-Amz-Security-Token", valid_21626157
  var valid_21626158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626158 = validateParameter(valid_21626158, JString, required = false,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626158
  var valid_21626159 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626159 = validateParameter(valid_21626159, JString, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "X-Amz-Algorithm", valid_21626159
  var valid_21626160 = header.getOrDefault("X-Amz-Signature")
  valid_21626160 = validateParameter(valid_21626160, JString, required = false,
                                   default = nil)
  if valid_21626160 != nil:
    section.add "X-Amz-Signature", valid_21626160
  var valid_21626161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626161 = validateParameter(valid_21626161, JString, required = false,
                                   default = nil)
  if valid_21626161 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626161
  var valid_21626162 = header.getOrDefault("X-Amz-Credential")
  valid_21626162 = validateParameter(valid_21626162, JString, required = false,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "X-Amz-Credential", valid_21626162
  result.add "header", section
  ## parameters in `formData` object:
  ##   Name: JString (required)
  ##       : Application names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, hyphens, and periods, and must be between 1 and 256 characters long.
  ##   Attributes.0.value: JString
  ##   Attributes.0.key: JString
  ##   Attributes.1.key: JString
  ##   Attributes.2.value: JString
  ##   Platform: JString (required)
  ##           : The following platforms are supported: ADM (Amazon Device Messaging), APNS (Apple Push Notification Service), APNS_SANDBOX, and FCM (Firebase Cloud Messaging).
  ##   Attributes.2.key: JString
  ##   Attributes.1.value: JString
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Name` field"
  var valid_21626163 = formData.getOrDefault("Name")
  valid_21626163 = validateParameter(valid_21626163, JString, required = true,
                                   default = nil)
  if valid_21626163 != nil:
    section.add "Name", valid_21626163
  var valid_21626164 = formData.getOrDefault("Attributes.0.value")
  valid_21626164 = validateParameter(valid_21626164, JString, required = false,
                                   default = nil)
  if valid_21626164 != nil:
    section.add "Attributes.0.value", valid_21626164
  var valid_21626165 = formData.getOrDefault("Attributes.0.key")
  valid_21626165 = validateParameter(valid_21626165, JString, required = false,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "Attributes.0.key", valid_21626165
  var valid_21626166 = formData.getOrDefault("Attributes.1.key")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "Attributes.1.key", valid_21626166
  var valid_21626167 = formData.getOrDefault("Attributes.2.value")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "Attributes.2.value", valid_21626167
  var valid_21626168 = formData.getOrDefault("Platform")
  valid_21626168 = validateParameter(valid_21626168, JString, required = true,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "Platform", valid_21626168
  var valid_21626169 = formData.getOrDefault("Attributes.2.key")
  valid_21626169 = validateParameter(valid_21626169, JString, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "Attributes.2.key", valid_21626169
  var valid_21626170 = formData.getOrDefault("Attributes.1.value")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "Attributes.1.value", valid_21626170
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626171: Call_PostCreatePlatformApplication_21626151;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For FCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For FCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action.</p>
  ## 
  let valid = call_21626171.validator(path, query, header, formData, body, _)
  let scheme = call_21626171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626171.makeUrl(scheme.get, call_21626171.host, call_21626171.base,
                               call_21626171.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626171, uri, valid, _)

proc call*(call_21626172: Call_PostCreatePlatformApplication_21626151;
          Name: string; Platform: string; Attributes0Value: string = "";
          Attributes0Key: string = ""; Attributes1Key: string = "";
          Action: string = "CreatePlatformApplication";
          Attributes2Value: string = ""; Attributes2Key: string = "";
          Version: string = "2010-03-31"; Attributes1Value: string = ""): Recallable =
  ## postCreatePlatformApplication
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For FCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For FCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action.</p>
  ##   Name: string (required)
  ##       : Application names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, hyphens, and periods, and must be between 1 and 256 characters long.
  ##   Attributes0Value: string
  ##   Attributes0Key: string
  ##   Attributes1Key: string
  ##   Action: string (required)
  ##   Attributes2Value: string
  ##   Platform: string (required)
  ##           : The following platforms are supported: ADM (Amazon Device Messaging), APNS (Apple Push Notification Service), APNS_SANDBOX, and FCM (Firebase Cloud Messaging).
  ##   Attributes2Key: string
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_21626173 = newJObject()
  var formData_21626174 = newJObject()
  add(formData_21626174, "Name", newJString(Name))
  add(formData_21626174, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_21626174, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_21626174, "Attributes.1.key", newJString(Attributes1Key))
  add(query_21626173, "Action", newJString(Action))
  add(formData_21626174, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_21626174, "Platform", newJString(Platform))
  add(formData_21626174, "Attributes.2.key", newJString(Attributes2Key))
  add(query_21626173, "Version", newJString(Version))
  add(formData_21626174, "Attributes.1.value", newJString(Attributes1Value))
  result = call_21626172.call(nil, query_21626173, nil, formData_21626174, nil)

var postCreatePlatformApplication* = Call_PostCreatePlatformApplication_21626151(
    name: "postCreatePlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformApplication",
    validator: validate_PostCreatePlatformApplication_21626152, base: "/",
    makeUrl: url_PostCreatePlatformApplication_21626153,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformApplication_21626128 = ref object of OpenApiRestCall_21625435
proc url_GetCreatePlatformApplication_21626130(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreatePlatformApplication_21626129(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For FCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For FCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action.</p>
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
  ##           : The following platforms are supported: ADM (Amazon Device Messaging), APNS (Apple Push Notification Service), APNS_SANDBOX, and FCM (Firebase Cloud Messaging).
  ##   Attributes.2.value: JString
  ##   Attributes.0.key: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626131 = query.getOrDefault("Attributes.2.key")
  valid_21626131 = validateParameter(valid_21626131, JString, required = false,
                                   default = nil)
  if valid_21626131 != nil:
    section.add "Attributes.2.key", valid_21626131
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_21626132 = query.getOrDefault("Name")
  valid_21626132 = validateParameter(valid_21626132, JString, required = true,
                                   default = nil)
  if valid_21626132 != nil:
    section.add "Name", valid_21626132
  var valid_21626133 = query.getOrDefault("Attributes.1.value")
  valid_21626133 = validateParameter(valid_21626133, JString, required = false,
                                   default = nil)
  if valid_21626133 != nil:
    section.add "Attributes.1.value", valid_21626133
  var valid_21626134 = query.getOrDefault("Attributes.0.value")
  valid_21626134 = validateParameter(valid_21626134, JString, required = false,
                                   default = nil)
  if valid_21626134 != nil:
    section.add "Attributes.0.value", valid_21626134
  var valid_21626135 = query.getOrDefault("Action")
  valid_21626135 = validateParameter(valid_21626135, JString, required = true, default = newJString(
      "CreatePlatformApplication"))
  if valid_21626135 != nil:
    section.add "Action", valid_21626135
  var valid_21626136 = query.getOrDefault("Attributes.1.key")
  valid_21626136 = validateParameter(valid_21626136, JString, required = false,
                                   default = nil)
  if valid_21626136 != nil:
    section.add "Attributes.1.key", valid_21626136
  var valid_21626137 = query.getOrDefault("Platform")
  valid_21626137 = validateParameter(valid_21626137, JString, required = true,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "Platform", valid_21626137
  var valid_21626138 = query.getOrDefault("Attributes.2.value")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "Attributes.2.value", valid_21626138
  var valid_21626139 = query.getOrDefault("Attributes.0.key")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "Attributes.0.key", valid_21626139
  var valid_21626140 = query.getOrDefault("Version")
  valid_21626140 = validateParameter(valid_21626140, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626140 != nil:
    section.add "Version", valid_21626140
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626141 = header.getOrDefault("X-Amz-Date")
  valid_21626141 = validateParameter(valid_21626141, JString, required = false,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "X-Amz-Date", valid_21626141
  var valid_21626142 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-Security-Token", valid_21626142
  var valid_21626143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626143
  var valid_21626144 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-Algorithm", valid_21626144
  var valid_21626145 = header.getOrDefault("X-Amz-Signature")
  valid_21626145 = validateParameter(valid_21626145, JString, required = false,
                                   default = nil)
  if valid_21626145 != nil:
    section.add "X-Amz-Signature", valid_21626145
  var valid_21626146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626146 = validateParameter(valid_21626146, JString, required = false,
                                   default = nil)
  if valid_21626146 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626146
  var valid_21626147 = header.getOrDefault("X-Amz-Credential")
  valid_21626147 = validateParameter(valid_21626147, JString, required = false,
                                   default = nil)
  if valid_21626147 != nil:
    section.add "X-Amz-Credential", valid_21626147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626148: Call_GetCreatePlatformApplication_21626128;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For FCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For FCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action.</p>
  ## 
  let valid = call_21626148.validator(path, query, header, formData, body, _)
  let scheme = call_21626148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626148.makeUrl(scheme.get, call_21626148.host, call_21626148.base,
                               call_21626148.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626148, uri, valid, _)

proc call*(call_21626149: Call_GetCreatePlatformApplication_21626128; Name: string;
          Platform: string; Attributes2Key: string = "";
          Attributes1Value: string = ""; Attributes0Value: string = "";
          Action: string = "CreatePlatformApplication"; Attributes1Key: string = "";
          Attributes2Value: string = ""; Attributes0Key: string = "";
          Version: string = "2010-03-31"): Recallable =
  ## getCreatePlatformApplication
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For FCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For FCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action.</p>
  ##   Attributes2Key: string
  ##   Name: string (required)
  ##       : Application names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, hyphens, and periods, and must be between 1 and 256 characters long.
  ##   Attributes1Value: string
  ##   Attributes0Value: string
  ##   Action: string (required)
  ##   Attributes1Key: string
  ##   Platform: string (required)
  ##           : The following platforms are supported: ADM (Amazon Device Messaging), APNS (Apple Push Notification Service), APNS_SANDBOX, and FCM (Firebase Cloud Messaging).
  ##   Attributes2Value: string
  ##   Attributes0Key: string
  ##   Version: string (required)
  var query_21626150 = newJObject()
  add(query_21626150, "Attributes.2.key", newJString(Attributes2Key))
  add(query_21626150, "Name", newJString(Name))
  add(query_21626150, "Attributes.1.value", newJString(Attributes1Value))
  add(query_21626150, "Attributes.0.value", newJString(Attributes0Value))
  add(query_21626150, "Action", newJString(Action))
  add(query_21626150, "Attributes.1.key", newJString(Attributes1Key))
  add(query_21626150, "Platform", newJString(Platform))
  add(query_21626150, "Attributes.2.value", newJString(Attributes2Value))
  add(query_21626150, "Attributes.0.key", newJString(Attributes0Key))
  add(query_21626150, "Version", newJString(Version))
  result = call_21626149.call(nil, query_21626150, nil, nil, nil)

var getCreatePlatformApplication* = Call_GetCreatePlatformApplication_21626128(
    name: "getCreatePlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformApplication",
    validator: validate_GetCreatePlatformApplication_21626129, base: "/",
    makeUrl: url_GetCreatePlatformApplication_21626130,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformEndpoint_21626199 = ref object of OpenApiRestCall_21625435
proc url_PostCreatePlatformEndpoint_21626201(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreatePlatformEndpoint_21626200(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as FCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626202 = query.getOrDefault("Action")
  valid_21626202 = validateParameter(valid_21626202, JString, required = true, default = newJString(
      "CreatePlatformEndpoint"))
  if valid_21626202 != nil:
    section.add "Action", valid_21626202
  var valid_21626203 = query.getOrDefault("Version")
  valid_21626203 = validateParameter(valid_21626203, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626203 != nil:
    section.add "Version", valid_21626203
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626204 = header.getOrDefault("X-Amz-Date")
  valid_21626204 = validateParameter(valid_21626204, JString, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "X-Amz-Date", valid_21626204
  var valid_21626205 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626205 = validateParameter(valid_21626205, JString, required = false,
                                   default = nil)
  if valid_21626205 != nil:
    section.add "X-Amz-Security-Token", valid_21626205
  var valid_21626206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626206 = validateParameter(valid_21626206, JString, required = false,
                                   default = nil)
  if valid_21626206 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626206
  var valid_21626207 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626207 = validateParameter(valid_21626207, JString, required = false,
                                   default = nil)
  if valid_21626207 != nil:
    section.add "X-Amz-Algorithm", valid_21626207
  var valid_21626208 = header.getOrDefault("X-Amz-Signature")
  valid_21626208 = validateParameter(valid_21626208, JString, required = false,
                                   default = nil)
  if valid_21626208 != nil:
    section.add "X-Amz-Signature", valid_21626208
  var valid_21626209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626209 = validateParameter(valid_21626209, JString, required = false,
                                   default = nil)
  if valid_21626209 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626209
  var valid_21626210 = header.getOrDefault("X-Amz-Credential")
  valid_21626210 = validateParameter(valid_21626210, JString, required = false,
                                   default = nil)
  if valid_21626210 != nil:
    section.add "X-Amz-Credential", valid_21626210
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
  ##        : Unique identifier created by the notification service for an app on a device. The specific name for Token will vary, depending on which notification service is being used. For example, when using APNS as the notification service, you need the device token. Alternatively, when using FCM or ADM, the device token equivalent is called the registration ID.
  section = newJObject()
  var valid_21626211 = formData.getOrDefault("Attributes.0.value")
  valid_21626211 = validateParameter(valid_21626211, JString, required = false,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "Attributes.0.value", valid_21626211
  var valid_21626212 = formData.getOrDefault("Attributes.0.key")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "Attributes.0.key", valid_21626212
  var valid_21626213 = formData.getOrDefault("Attributes.1.key")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "Attributes.1.key", valid_21626213
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_21626214 = formData.getOrDefault("PlatformApplicationArn")
  valid_21626214 = validateParameter(valid_21626214, JString, required = true,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "PlatformApplicationArn", valid_21626214
  var valid_21626215 = formData.getOrDefault("CustomUserData")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "CustomUserData", valid_21626215
  var valid_21626216 = formData.getOrDefault("Attributes.2.value")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "Attributes.2.value", valid_21626216
  var valid_21626217 = formData.getOrDefault("Attributes.2.key")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "Attributes.2.key", valid_21626217
  var valid_21626218 = formData.getOrDefault("Attributes.1.value")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "Attributes.1.value", valid_21626218
  var valid_21626219 = formData.getOrDefault("Token")
  valid_21626219 = validateParameter(valid_21626219, JString, required = true,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "Token", valid_21626219
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626220: Call_PostCreatePlatformEndpoint_21626199;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as FCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  let valid = call_21626220.validator(path, query, header, formData, body, _)
  let scheme = call_21626220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626220.makeUrl(scheme.get, call_21626220.host, call_21626220.base,
                               call_21626220.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626220, uri, valid, _)

proc call*(call_21626221: Call_PostCreatePlatformEndpoint_21626199;
          PlatformApplicationArn: string; Token: string;
          Attributes0Value: string = ""; Attributes0Key: string = "";
          Attributes1Key: string = ""; Action: string = "CreatePlatformEndpoint";
          CustomUserData: string = ""; Attributes2Value: string = "";
          Attributes2Key: string = ""; Version: string = "2010-03-31";
          Attributes1Value: string = ""): Recallable =
  ## postCreatePlatformEndpoint
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as FCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
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
  ##        : Unique identifier created by the notification service for an app on a device. The specific name for Token will vary, depending on which notification service is being used. For example, when using APNS as the notification service, you need the device token. Alternatively, when using FCM or ADM, the device token equivalent is called the registration ID.
  var query_21626222 = newJObject()
  var formData_21626223 = newJObject()
  add(formData_21626223, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_21626223, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_21626223, "Attributes.1.key", newJString(Attributes1Key))
  add(query_21626222, "Action", newJString(Action))
  add(formData_21626223, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(formData_21626223, "CustomUserData", newJString(CustomUserData))
  add(formData_21626223, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_21626223, "Attributes.2.key", newJString(Attributes2Key))
  add(query_21626222, "Version", newJString(Version))
  add(formData_21626223, "Attributes.1.value", newJString(Attributes1Value))
  add(formData_21626223, "Token", newJString(Token))
  result = call_21626221.call(nil, query_21626222, nil, formData_21626223, nil)

var postCreatePlatformEndpoint* = Call_PostCreatePlatformEndpoint_21626199(
    name: "postCreatePlatformEndpoint", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformEndpoint",
    validator: validate_PostCreatePlatformEndpoint_21626200, base: "/",
    makeUrl: url_PostCreatePlatformEndpoint_21626201,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformEndpoint_21626175 = ref object of OpenApiRestCall_21625435
proc url_GetCreatePlatformEndpoint_21626177(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreatePlatformEndpoint_21626176(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as FCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
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
  ##        : Unique identifier created by the notification service for an app on a device. The specific name for Token will vary, depending on which notification service is being used. For example, when using APNS as the notification service, you need the device token. Alternatively, when using FCM or ADM, the device token equivalent is called the registration ID.
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
  var valid_21626178 = query.getOrDefault("CustomUserData")
  valid_21626178 = validateParameter(valid_21626178, JString, required = false,
                                   default = nil)
  if valid_21626178 != nil:
    section.add "CustomUserData", valid_21626178
  var valid_21626179 = query.getOrDefault("Attributes.2.key")
  valid_21626179 = validateParameter(valid_21626179, JString, required = false,
                                   default = nil)
  if valid_21626179 != nil:
    section.add "Attributes.2.key", valid_21626179
  assert query != nil, "query argument is necessary due to required `Token` field"
  var valid_21626180 = query.getOrDefault("Token")
  valid_21626180 = validateParameter(valid_21626180, JString, required = true,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "Token", valid_21626180
  var valid_21626181 = query.getOrDefault("Attributes.1.value")
  valid_21626181 = validateParameter(valid_21626181, JString, required = false,
                                   default = nil)
  if valid_21626181 != nil:
    section.add "Attributes.1.value", valid_21626181
  var valid_21626182 = query.getOrDefault("Attributes.0.value")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "Attributes.0.value", valid_21626182
  var valid_21626183 = query.getOrDefault("Action")
  valid_21626183 = validateParameter(valid_21626183, JString, required = true, default = newJString(
      "CreatePlatformEndpoint"))
  if valid_21626183 != nil:
    section.add "Action", valid_21626183
  var valid_21626184 = query.getOrDefault("Attributes.1.key")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "Attributes.1.key", valid_21626184
  var valid_21626185 = query.getOrDefault("Attributes.2.value")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "Attributes.2.value", valid_21626185
  var valid_21626186 = query.getOrDefault("Attributes.0.key")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "Attributes.0.key", valid_21626186
  var valid_21626187 = query.getOrDefault("Version")
  valid_21626187 = validateParameter(valid_21626187, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626187 != nil:
    section.add "Version", valid_21626187
  var valid_21626188 = query.getOrDefault("PlatformApplicationArn")
  valid_21626188 = validateParameter(valid_21626188, JString, required = true,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "PlatformApplicationArn", valid_21626188
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626189 = header.getOrDefault("X-Amz-Date")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "X-Amz-Date", valid_21626189
  var valid_21626190 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626190 = validateParameter(valid_21626190, JString, required = false,
                                   default = nil)
  if valid_21626190 != nil:
    section.add "X-Amz-Security-Token", valid_21626190
  var valid_21626191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626191 = validateParameter(valid_21626191, JString, required = false,
                                   default = nil)
  if valid_21626191 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626191
  var valid_21626192 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626192 = validateParameter(valid_21626192, JString, required = false,
                                   default = nil)
  if valid_21626192 != nil:
    section.add "X-Amz-Algorithm", valid_21626192
  var valid_21626193 = header.getOrDefault("X-Amz-Signature")
  valid_21626193 = validateParameter(valid_21626193, JString, required = false,
                                   default = nil)
  if valid_21626193 != nil:
    section.add "X-Amz-Signature", valid_21626193
  var valid_21626194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626194 = validateParameter(valid_21626194, JString, required = false,
                                   default = nil)
  if valid_21626194 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626194
  var valid_21626195 = header.getOrDefault("X-Amz-Credential")
  valid_21626195 = validateParameter(valid_21626195, JString, required = false,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "X-Amz-Credential", valid_21626195
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626196: Call_GetCreatePlatformEndpoint_21626175;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as FCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  let valid = call_21626196.validator(path, query, header, formData, body, _)
  let scheme = call_21626196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626196.makeUrl(scheme.get, call_21626196.host, call_21626196.base,
                               call_21626196.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626196, uri, valid, _)

proc call*(call_21626197: Call_GetCreatePlatformEndpoint_21626175; Token: string;
          PlatformApplicationArn: string; CustomUserData: string = "";
          Attributes2Key: string = ""; Attributes1Value: string = "";
          Attributes0Value: string = ""; Action: string = "CreatePlatformEndpoint";
          Attributes1Key: string = ""; Attributes2Value: string = "";
          Attributes0Key: string = ""; Version: string = "2010-03-31"): Recallable =
  ## getCreatePlatformEndpoint
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as FCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ##   CustomUserData: string
  ##                 : Arbitrary user data to associate with the endpoint. Amazon SNS does not use this data. The data must be in UTF-8 format and less than 2KB.
  ##   Attributes2Key: string
  ##   Token: string (required)
  ##        : Unique identifier created by the notification service for an app on a device. The specific name for Token will vary, depending on which notification service is being used. For example, when using APNS as the notification service, you need the device token. Alternatively, when using FCM or ADM, the device token equivalent is called the registration ID.
  ##   Attributes1Value: string
  ##   Attributes0Value: string
  ##   Action: string (required)
  ##   Attributes1Key: string
  ##   Attributes2Value: string
  ##   Attributes0Key: string
  ##   Version: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn returned from CreatePlatformApplication is used to create a an endpoint.
  var query_21626198 = newJObject()
  add(query_21626198, "CustomUserData", newJString(CustomUserData))
  add(query_21626198, "Attributes.2.key", newJString(Attributes2Key))
  add(query_21626198, "Token", newJString(Token))
  add(query_21626198, "Attributes.1.value", newJString(Attributes1Value))
  add(query_21626198, "Attributes.0.value", newJString(Attributes0Value))
  add(query_21626198, "Action", newJString(Action))
  add(query_21626198, "Attributes.1.key", newJString(Attributes1Key))
  add(query_21626198, "Attributes.2.value", newJString(Attributes2Value))
  add(query_21626198, "Attributes.0.key", newJString(Attributes0Key))
  add(query_21626198, "Version", newJString(Version))
  add(query_21626198, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_21626197.call(nil, query_21626198, nil, nil, nil)

var getCreatePlatformEndpoint* = Call_GetCreatePlatformEndpoint_21626175(
    name: "getCreatePlatformEndpoint", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformEndpoint",
    validator: validate_GetCreatePlatformEndpoint_21626176, base: "/",
    makeUrl: url_GetCreatePlatformEndpoint_21626177,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateTopic_21626247 = ref object of OpenApiRestCall_21625435
proc url_PostCreateTopic_21626249(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateTopic_21626248(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626250 = query.getOrDefault("Action")
  valid_21626250 = validateParameter(valid_21626250, JString, required = true,
                                   default = newJString("CreateTopic"))
  if valid_21626250 != nil:
    section.add "Action", valid_21626250
  var valid_21626251 = query.getOrDefault("Version")
  valid_21626251 = validateParameter(valid_21626251, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626251 != nil:
    section.add "Version", valid_21626251
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626252 = header.getOrDefault("X-Amz-Date")
  valid_21626252 = validateParameter(valid_21626252, JString, required = false,
                                   default = nil)
  if valid_21626252 != nil:
    section.add "X-Amz-Date", valid_21626252
  var valid_21626253 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626253 = validateParameter(valid_21626253, JString, required = false,
                                   default = nil)
  if valid_21626253 != nil:
    section.add "X-Amz-Security-Token", valid_21626253
  var valid_21626254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626254 = validateParameter(valid_21626254, JString, required = false,
                                   default = nil)
  if valid_21626254 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626254
  var valid_21626255 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626255 = validateParameter(valid_21626255, JString, required = false,
                                   default = nil)
  if valid_21626255 != nil:
    section.add "X-Amz-Algorithm", valid_21626255
  var valid_21626256 = header.getOrDefault("X-Amz-Signature")
  valid_21626256 = validateParameter(valid_21626256, JString, required = false,
                                   default = nil)
  if valid_21626256 != nil:
    section.add "X-Amz-Signature", valid_21626256
  var valid_21626257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626257 = validateParameter(valid_21626257, JString, required = false,
                                   default = nil)
  if valid_21626257 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626257
  var valid_21626258 = header.getOrDefault("X-Amz-Credential")
  valid_21626258 = validateParameter(valid_21626258, JString, required = false,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "X-Amz-Credential", valid_21626258
  result.add "header", section
  ## parameters in `formData` object:
  ##   Name: JString (required)
  ##       : <p>The name of the topic you want to create.</p> <p>Constraints: Topic names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, and hyphens, and must be between 1 and 256 characters long.</p>
  ##   Attributes.0.value: JString
  ##   Attributes.0.key: JString
  ##   Tags: JArray
  ##       : <p>The list of tags to add to a new topic.</p> <note> <p>To be able to tag a topic on creation, you must have the <code>sns:CreateTopic</code> and <code>sns:TagResource</code> permissions.</p> </note>
  ##   Attributes.1.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   Attributes.1.value: JString
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Name` field"
  var valid_21626259 = formData.getOrDefault("Name")
  valid_21626259 = validateParameter(valid_21626259, JString, required = true,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "Name", valid_21626259
  var valid_21626260 = formData.getOrDefault("Attributes.0.value")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "Attributes.0.value", valid_21626260
  var valid_21626261 = formData.getOrDefault("Attributes.0.key")
  valid_21626261 = validateParameter(valid_21626261, JString, required = false,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "Attributes.0.key", valid_21626261
  var valid_21626262 = formData.getOrDefault("Tags")
  valid_21626262 = validateParameter(valid_21626262, JArray, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "Tags", valid_21626262
  var valid_21626263 = formData.getOrDefault("Attributes.1.key")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "Attributes.1.key", valid_21626263
  var valid_21626264 = formData.getOrDefault("Attributes.2.value")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "Attributes.2.value", valid_21626264
  var valid_21626265 = formData.getOrDefault("Attributes.2.key")
  valid_21626265 = validateParameter(valid_21626265, JString, required = false,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "Attributes.2.key", valid_21626265
  var valid_21626266 = formData.getOrDefault("Attributes.1.value")
  valid_21626266 = validateParameter(valid_21626266, JString, required = false,
                                   default = nil)
  if valid_21626266 != nil:
    section.add "Attributes.1.value", valid_21626266
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626267: Call_PostCreateTopic_21626247; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  let valid = call_21626267.validator(path, query, header, formData, body, _)
  let scheme = call_21626267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626267.makeUrl(scheme.get, call_21626267.host, call_21626267.base,
                               call_21626267.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626267, uri, valid, _)

proc call*(call_21626268: Call_PostCreateTopic_21626247; Name: string;
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
  ##       : <p>The list of tags to add to a new topic.</p> <note> <p>To be able to tag a topic on creation, you must have the <code>sns:CreateTopic</code> and <code>sns:TagResource</code> permissions.</p> </note>
  ##   Attributes1Key: string
  ##   Action: string (required)
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_21626269 = newJObject()
  var formData_21626270 = newJObject()
  add(formData_21626270, "Name", newJString(Name))
  add(formData_21626270, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_21626270, "Attributes.0.key", newJString(Attributes0Key))
  if Tags != nil:
    formData_21626270.add "Tags", Tags
  add(formData_21626270, "Attributes.1.key", newJString(Attributes1Key))
  add(query_21626269, "Action", newJString(Action))
  add(formData_21626270, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_21626270, "Attributes.2.key", newJString(Attributes2Key))
  add(query_21626269, "Version", newJString(Version))
  add(formData_21626270, "Attributes.1.value", newJString(Attributes1Value))
  result = call_21626268.call(nil, query_21626269, nil, formData_21626270, nil)

var postCreateTopic* = Call_PostCreateTopic_21626247(name: "postCreateTopic",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=CreateTopic", validator: validate_PostCreateTopic_21626248,
    base: "/", makeUrl: url_PostCreateTopic_21626249,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateTopic_21626224 = ref object of OpenApiRestCall_21625435
proc url_GetCreateTopic_21626226(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateTopic_21626225(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##       : <p>The list of tags to add to a new topic.</p> <note> <p>To be able to tag a topic on creation, you must have the <code>sns:CreateTopic</code> and <code>sns:TagResource</code> permissions.</p> </note>
  ##   Attributes.0.value: JString
  ##   Action: JString (required)
  ##   Attributes.1.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.0.key: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626227 = query.getOrDefault("Attributes.2.key")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "Attributes.2.key", valid_21626227
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_21626228 = query.getOrDefault("Name")
  valid_21626228 = validateParameter(valid_21626228, JString, required = true,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "Name", valid_21626228
  var valid_21626229 = query.getOrDefault("Attributes.1.value")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "Attributes.1.value", valid_21626229
  var valid_21626230 = query.getOrDefault("Tags")
  valid_21626230 = validateParameter(valid_21626230, JArray, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "Tags", valid_21626230
  var valid_21626231 = query.getOrDefault("Attributes.0.value")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "Attributes.0.value", valid_21626231
  var valid_21626232 = query.getOrDefault("Action")
  valid_21626232 = validateParameter(valid_21626232, JString, required = true,
                                   default = newJString("CreateTopic"))
  if valid_21626232 != nil:
    section.add "Action", valid_21626232
  var valid_21626233 = query.getOrDefault("Attributes.1.key")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "Attributes.1.key", valid_21626233
  var valid_21626234 = query.getOrDefault("Attributes.2.value")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "Attributes.2.value", valid_21626234
  var valid_21626235 = query.getOrDefault("Attributes.0.key")
  valid_21626235 = validateParameter(valid_21626235, JString, required = false,
                                   default = nil)
  if valid_21626235 != nil:
    section.add "Attributes.0.key", valid_21626235
  var valid_21626236 = query.getOrDefault("Version")
  valid_21626236 = validateParameter(valid_21626236, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626236 != nil:
    section.add "Version", valid_21626236
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626237 = header.getOrDefault("X-Amz-Date")
  valid_21626237 = validateParameter(valid_21626237, JString, required = false,
                                   default = nil)
  if valid_21626237 != nil:
    section.add "X-Amz-Date", valid_21626237
  var valid_21626238 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626238 = validateParameter(valid_21626238, JString, required = false,
                                   default = nil)
  if valid_21626238 != nil:
    section.add "X-Amz-Security-Token", valid_21626238
  var valid_21626239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626239 = validateParameter(valid_21626239, JString, required = false,
                                   default = nil)
  if valid_21626239 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626239
  var valid_21626240 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626240 = validateParameter(valid_21626240, JString, required = false,
                                   default = nil)
  if valid_21626240 != nil:
    section.add "X-Amz-Algorithm", valid_21626240
  var valid_21626241 = header.getOrDefault("X-Amz-Signature")
  valid_21626241 = validateParameter(valid_21626241, JString, required = false,
                                   default = nil)
  if valid_21626241 != nil:
    section.add "X-Amz-Signature", valid_21626241
  var valid_21626242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626242 = validateParameter(valid_21626242, JString, required = false,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626242
  var valid_21626243 = header.getOrDefault("X-Amz-Credential")
  valid_21626243 = validateParameter(valid_21626243, JString, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "X-Amz-Credential", valid_21626243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626244: Call_GetCreateTopic_21626224; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  let valid = call_21626244.validator(path, query, header, formData, body, _)
  let scheme = call_21626244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626244.makeUrl(scheme.get, call_21626244.host, call_21626244.base,
                               call_21626244.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626244, uri, valid, _)

proc call*(call_21626245: Call_GetCreateTopic_21626224; Name: string;
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
  ##       : <p>The list of tags to add to a new topic.</p> <note> <p>To be able to tag a topic on creation, you must have the <code>sns:CreateTopic</code> and <code>sns:TagResource</code> permissions.</p> </note>
  ##   Attributes0Value: string
  ##   Action: string (required)
  ##   Attributes1Key: string
  ##   Attributes2Value: string
  ##   Attributes0Key: string
  ##   Version: string (required)
  var query_21626246 = newJObject()
  add(query_21626246, "Attributes.2.key", newJString(Attributes2Key))
  add(query_21626246, "Name", newJString(Name))
  add(query_21626246, "Attributes.1.value", newJString(Attributes1Value))
  if Tags != nil:
    query_21626246.add "Tags", Tags
  add(query_21626246, "Attributes.0.value", newJString(Attributes0Value))
  add(query_21626246, "Action", newJString(Action))
  add(query_21626246, "Attributes.1.key", newJString(Attributes1Key))
  add(query_21626246, "Attributes.2.value", newJString(Attributes2Value))
  add(query_21626246, "Attributes.0.key", newJString(Attributes0Key))
  add(query_21626246, "Version", newJString(Version))
  result = call_21626245.call(nil, query_21626246, nil, nil, nil)

var getCreateTopic* = Call_GetCreateTopic_21626224(name: "getCreateTopic",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=CreateTopic", validator: validate_GetCreateTopic_21626225,
    base: "/", makeUrl: url_GetCreateTopic_21626226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEndpoint_21626287 = ref object of OpenApiRestCall_21625435
proc url_PostDeleteEndpoint_21626289(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteEndpoint_21626288(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626290 = query.getOrDefault("Action")
  valid_21626290 = validateParameter(valid_21626290, JString, required = true,
                                   default = newJString("DeleteEndpoint"))
  if valid_21626290 != nil:
    section.add "Action", valid_21626290
  var valid_21626291 = query.getOrDefault("Version")
  valid_21626291 = validateParameter(valid_21626291, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626291 != nil:
    section.add "Version", valid_21626291
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626292 = header.getOrDefault("X-Amz-Date")
  valid_21626292 = validateParameter(valid_21626292, JString, required = false,
                                   default = nil)
  if valid_21626292 != nil:
    section.add "X-Amz-Date", valid_21626292
  var valid_21626293 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "X-Amz-Security-Token", valid_21626293
  var valid_21626294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626294
  var valid_21626295 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626295 = validateParameter(valid_21626295, JString, required = false,
                                   default = nil)
  if valid_21626295 != nil:
    section.add "X-Amz-Algorithm", valid_21626295
  var valid_21626296 = header.getOrDefault("X-Amz-Signature")
  valid_21626296 = validateParameter(valid_21626296, JString, required = false,
                                   default = nil)
  if valid_21626296 != nil:
    section.add "X-Amz-Signature", valid_21626296
  var valid_21626297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626297 = validateParameter(valid_21626297, JString, required = false,
                                   default = nil)
  if valid_21626297 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626297
  var valid_21626298 = header.getOrDefault("X-Amz-Credential")
  valid_21626298 = validateParameter(valid_21626298, JString, required = false,
                                   default = nil)
  if valid_21626298 != nil:
    section.add "X-Amz-Credential", valid_21626298
  result.add "header", section
  ## parameters in `formData` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn of endpoint to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_21626299 = formData.getOrDefault("EndpointArn")
  valid_21626299 = validateParameter(valid_21626299, JString, required = true,
                                   default = nil)
  if valid_21626299 != nil:
    section.add "EndpointArn", valid_21626299
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626300: Call_PostDeleteEndpoint_21626287; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ## 
  let valid = call_21626300.validator(path, query, header, formData, body, _)
  let scheme = call_21626300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626300.makeUrl(scheme.get, call_21626300.host, call_21626300.base,
                               call_21626300.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626300, uri, valid, _)

proc call*(call_21626301: Call_PostDeleteEndpoint_21626287; EndpointArn: string;
          Action: string = "DeleteEndpoint"; Version: string = "2010-03-31"): Recallable =
  ## postDeleteEndpoint
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ##   Action: string (required)
  ##   EndpointArn: string (required)
  ##              : EndpointArn of endpoint to delete.
  ##   Version: string (required)
  var query_21626302 = newJObject()
  var formData_21626303 = newJObject()
  add(query_21626302, "Action", newJString(Action))
  add(formData_21626303, "EndpointArn", newJString(EndpointArn))
  add(query_21626302, "Version", newJString(Version))
  result = call_21626301.call(nil, query_21626302, nil, formData_21626303, nil)

var postDeleteEndpoint* = Call_PostDeleteEndpoint_21626287(
    name: "postDeleteEndpoint", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=DeleteEndpoint",
    validator: validate_PostDeleteEndpoint_21626288, base: "/",
    makeUrl: url_PostDeleteEndpoint_21626289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEndpoint_21626271 = ref object of OpenApiRestCall_21625435
proc url_GetDeleteEndpoint_21626273(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteEndpoint_21626272(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626274 = query.getOrDefault("EndpointArn")
  valid_21626274 = validateParameter(valid_21626274, JString, required = true,
                                   default = nil)
  if valid_21626274 != nil:
    section.add "EndpointArn", valid_21626274
  var valid_21626275 = query.getOrDefault("Action")
  valid_21626275 = validateParameter(valid_21626275, JString, required = true,
                                   default = newJString("DeleteEndpoint"))
  if valid_21626275 != nil:
    section.add "Action", valid_21626275
  var valid_21626276 = query.getOrDefault("Version")
  valid_21626276 = validateParameter(valid_21626276, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626276 != nil:
    section.add "Version", valid_21626276
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626277 = header.getOrDefault("X-Amz-Date")
  valid_21626277 = validateParameter(valid_21626277, JString, required = false,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "X-Amz-Date", valid_21626277
  var valid_21626278 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626278 = validateParameter(valid_21626278, JString, required = false,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "X-Amz-Security-Token", valid_21626278
  var valid_21626279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626279 = validateParameter(valid_21626279, JString, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626279
  var valid_21626280 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626280 = validateParameter(valid_21626280, JString, required = false,
                                   default = nil)
  if valid_21626280 != nil:
    section.add "X-Amz-Algorithm", valid_21626280
  var valid_21626281 = header.getOrDefault("X-Amz-Signature")
  valid_21626281 = validateParameter(valid_21626281, JString, required = false,
                                   default = nil)
  if valid_21626281 != nil:
    section.add "X-Amz-Signature", valid_21626281
  var valid_21626282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626282 = validateParameter(valid_21626282, JString, required = false,
                                   default = nil)
  if valid_21626282 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626282
  var valid_21626283 = header.getOrDefault("X-Amz-Credential")
  valid_21626283 = validateParameter(valid_21626283, JString, required = false,
                                   default = nil)
  if valid_21626283 != nil:
    section.add "X-Amz-Credential", valid_21626283
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626284: Call_GetDeleteEndpoint_21626271; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ## 
  let valid = call_21626284.validator(path, query, header, formData, body, _)
  let scheme = call_21626284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626284.makeUrl(scheme.get, call_21626284.host, call_21626284.base,
                               call_21626284.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626284, uri, valid, _)

proc call*(call_21626285: Call_GetDeleteEndpoint_21626271; EndpointArn: string;
          Action: string = "DeleteEndpoint"; Version: string = "2010-03-31"): Recallable =
  ## getDeleteEndpoint
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ##   EndpointArn: string (required)
  ##              : EndpointArn of endpoint to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626286 = newJObject()
  add(query_21626286, "EndpointArn", newJString(EndpointArn))
  add(query_21626286, "Action", newJString(Action))
  add(query_21626286, "Version", newJString(Version))
  result = call_21626285.call(nil, query_21626286, nil, nil, nil)

var getDeleteEndpoint* = Call_GetDeleteEndpoint_21626271(name: "getDeleteEndpoint",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=DeleteEndpoint", validator: validate_GetDeleteEndpoint_21626272,
    base: "/", makeUrl: url_GetDeleteEndpoint_21626273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeletePlatformApplication_21626320 = ref object of OpenApiRestCall_21625435
proc url_PostDeletePlatformApplication_21626322(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeletePlatformApplication_21626321(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626323 = query.getOrDefault("Action")
  valid_21626323 = validateParameter(valid_21626323, JString, required = true, default = newJString(
      "DeletePlatformApplication"))
  if valid_21626323 != nil:
    section.add "Action", valid_21626323
  var valid_21626324 = query.getOrDefault("Version")
  valid_21626324 = validateParameter(valid_21626324, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626324 != nil:
    section.add "Version", valid_21626324
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626325 = header.getOrDefault("X-Amz-Date")
  valid_21626325 = validateParameter(valid_21626325, JString, required = false,
                                   default = nil)
  if valid_21626325 != nil:
    section.add "X-Amz-Date", valid_21626325
  var valid_21626326 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626326 = validateParameter(valid_21626326, JString, required = false,
                                   default = nil)
  if valid_21626326 != nil:
    section.add "X-Amz-Security-Token", valid_21626326
  var valid_21626327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626327 = validateParameter(valid_21626327, JString, required = false,
                                   default = nil)
  if valid_21626327 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626327
  var valid_21626328 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626328 = validateParameter(valid_21626328, JString, required = false,
                                   default = nil)
  if valid_21626328 != nil:
    section.add "X-Amz-Algorithm", valid_21626328
  var valid_21626329 = header.getOrDefault("X-Amz-Signature")
  valid_21626329 = validateParameter(valid_21626329, JString, required = false,
                                   default = nil)
  if valid_21626329 != nil:
    section.add "X-Amz-Signature", valid_21626329
  var valid_21626330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626330 = validateParameter(valid_21626330, JString, required = false,
                                   default = nil)
  if valid_21626330 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626330
  var valid_21626331 = header.getOrDefault("X-Amz-Credential")
  valid_21626331 = validateParameter(valid_21626331, JString, required = false,
                                   default = nil)
  if valid_21626331 != nil:
    section.add "X-Amz-Credential", valid_21626331
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_21626332 = formData.getOrDefault("PlatformApplicationArn")
  valid_21626332 = validateParameter(valid_21626332, JString, required = true,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "PlatformApplicationArn", valid_21626332
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626333: Call_PostDeletePlatformApplication_21626320;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_21626333.validator(path, query, header, formData, body, _)
  let scheme = call_21626333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626333.makeUrl(scheme.get, call_21626333.host, call_21626333.base,
                               call_21626333.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626333, uri, valid, _)

proc call*(call_21626334: Call_PostDeletePlatformApplication_21626320;
          PlatformApplicationArn: string;
          Action: string = "DeletePlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## postDeletePlatformApplication
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  ##   Version: string (required)
  var query_21626335 = newJObject()
  var formData_21626336 = newJObject()
  add(query_21626335, "Action", newJString(Action))
  add(formData_21626336, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(query_21626335, "Version", newJString(Version))
  result = call_21626334.call(nil, query_21626335, nil, formData_21626336, nil)

var postDeletePlatformApplication* = Call_PostDeletePlatformApplication_21626320(
    name: "postDeletePlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=DeletePlatformApplication",
    validator: validate_PostDeletePlatformApplication_21626321, base: "/",
    makeUrl: url_PostDeletePlatformApplication_21626322,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeletePlatformApplication_21626304 = ref object of OpenApiRestCall_21625435
proc url_GetDeletePlatformApplication_21626306(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeletePlatformApplication_21626305(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
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
  var valid_21626307 = query.getOrDefault("Action")
  valid_21626307 = validateParameter(valid_21626307, JString, required = true, default = newJString(
      "DeletePlatformApplication"))
  if valid_21626307 != nil:
    section.add "Action", valid_21626307
  var valid_21626308 = query.getOrDefault("Version")
  valid_21626308 = validateParameter(valid_21626308, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626308 != nil:
    section.add "Version", valid_21626308
  var valid_21626309 = query.getOrDefault("PlatformApplicationArn")
  valid_21626309 = validateParameter(valid_21626309, JString, required = true,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "PlatformApplicationArn", valid_21626309
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626310 = header.getOrDefault("X-Amz-Date")
  valid_21626310 = validateParameter(valid_21626310, JString, required = false,
                                   default = nil)
  if valid_21626310 != nil:
    section.add "X-Amz-Date", valid_21626310
  var valid_21626311 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626311 = validateParameter(valid_21626311, JString, required = false,
                                   default = nil)
  if valid_21626311 != nil:
    section.add "X-Amz-Security-Token", valid_21626311
  var valid_21626312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626312 = validateParameter(valid_21626312, JString, required = false,
                                   default = nil)
  if valid_21626312 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626312
  var valid_21626313 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626313 = validateParameter(valid_21626313, JString, required = false,
                                   default = nil)
  if valid_21626313 != nil:
    section.add "X-Amz-Algorithm", valid_21626313
  var valid_21626314 = header.getOrDefault("X-Amz-Signature")
  valid_21626314 = validateParameter(valid_21626314, JString, required = false,
                                   default = nil)
  if valid_21626314 != nil:
    section.add "X-Amz-Signature", valid_21626314
  var valid_21626315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626315 = validateParameter(valid_21626315, JString, required = false,
                                   default = nil)
  if valid_21626315 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626315
  var valid_21626316 = header.getOrDefault("X-Amz-Credential")
  valid_21626316 = validateParameter(valid_21626316, JString, required = false,
                                   default = nil)
  if valid_21626316 != nil:
    section.add "X-Amz-Credential", valid_21626316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626317: Call_GetDeletePlatformApplication_21626304;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_21626317.validator(path, query, header, formData, body, _)
  let scheme = call_21626317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626317.makeUrl(scheme.get, call_21626317.host, call_21626317.base,
                               call_21626317.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626317, uri, valid, _)

proc call*(call_21626318: Call_GetDeletePlatformApplication_21626304;
          PlatformApplicationArn: string;
          Action: string = "DeletePlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## getDeletePlatformApplication
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  var query_21626319 = newJObject()
  add(query_21626319, "Action", newJString(Action))
  add(query_21626319, "Version", newJString(Version))
  add(query_21626319, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_21626318.call(nil, query_21626319, nil, nil, nil)

var getDeletePlatformApplication* = Call_GetDeletePlatformApplication_21626304(
    name: "getDeletePlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=DeletePlatformApplication",
    validator: validate_GetDeletePlatformApplication_21626305, base: "/",
    makeUrl: url_GetDeletePlatformApplication_21626306,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteTopic_21626353 = ref object of OpenApiRestCall_21625435
proc url_PostDeleteTopic_21626355(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteTopic_21626354(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626356 = query.getOrDefault("Action")
  valid_21626356 = validateParameter(valid_21626356, JString, required = true,
                                   default = newJString("DeleteTopic"))
  if valid_21626356 != nil:
    section.add "Action", valid_21626356
  var valid_21626357 = query.getOrDefault("Version")
  valid_21626357 = validateParameter(valid_21626357, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626357 != nil:
    section.add "Version", valid_21626357
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626358 = header.getOrDefault("X-Amz-Date")
  valid_21626358 = validateParameter(valid_21626358, JString, required = false,
                                   default = nil)
  if valid_21626358 != nil:
    section.add "X-Amz-Date", valid_21626358
  var valid_21626359 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626359 = validateParameter(valid_21626359, JString, required = false,
                                   default = nil)
  if valid_21626359 != nil:
    section.add "X-Amz-Security-Token", valid_21626359
  var valid_21626360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626360 = validateParameter(valid_21626360, JString, required = false,
                                   default = nil)
  if valid_21626360 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626360
  var valid_21626361 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626361 = validateParameter(valid_21626361, JString, required = false,
                                   default = nil)
  if valid_21626361 != nil:
    section.add "X-Amz-Algorithm", valid_21626361
  var valid_21626362 = header.getOrDefault("X-Amz-Signature")
  valid_21626362 = validateParameter(valid_21626362, JString, required = false,
                                   default = nil)
  if valid_21626362 != nil:
    section.add "X-Amz-Signature", valid_21626362
  var valid_21626363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626363 = validateParameter(valid_21626363, JString, required = false,
                                   default = nil)
  if valid_21626363 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626363
  var valid_21626364 = header.getOrDefault("X-Amz-Credential")
  valid_21626364 = validateParameter(valid_21626364, JString, required = false,
                                   default = nil)
  if valid_21626364 != nil:
    section.add "X-Amz-Credential", valid_21626364
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic you want to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_21626365 = formData.getOrDefault("TopicArn")
  valid_21626365 = validateParameter(valid_21626365, JString, required = true,
                                   default = nil)
  if valid_21626365 != nil:
    section.add "TopicArn", valid_21626365
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626366: Call_PostDeleteTopic_21626353; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ## 
  let valid = call_21626366.validator(path, query, header, formData, body, _)
  let scheme = call_21626366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626366.makeUrl(scheme.get, call_21626366.host, call_21626366.base,
                               call_21626366.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626366, uri, valid, _)

proc call*(call_21626367: Call_PostDeleteTopic_21626353; TopicArn: string;
          Action: string = "DeleteTopic"; Version: string = "2010-03-31"): Recallable =
  ## postDeleteTopic
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626368 = newJObject()
  var formData_21626369 = newJObject()
  add(formData_21626369, "TopicArn", newJString(TopicArn))
  add(query_21626368, "Action", newJString(Action))
  add(query_21626368, "Version", newJString(Version))
  result = call_21626367.call(nil, query_21626368, nil, formData_21626369, nil)

var postDeleteTopic* = Call_PostDeleteTopic_21626353(name: "postDeleteTopic",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=DeleteTopic", validator: validate_PostDeleteTopic_21626354,
    base: "/", makeUrl: url_PostDeleteTopic_21626355,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteTopic_21626337 = ref object of OpenApiRestCall_21625435
proc url_GetDeleteTopic_21626339(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteTopic_21626338(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626340 = query.getOrDefault("Action")
  valid_21626340 = validateParameter(valid_21626340, JString, required = true,
                                   default = newJString("DeleteTopic"))
  if valid_21626340 != nil:
    section.add "Action", valid_21626340
  var valid_21626341 = query.getOrDefault("TopicArn")
  valid_21626341 = validateParameter(valid_21626341, JString, required = true,
                                   default = nil)
  if valid_21626341 != nil:
    section.add "TopicArn", valid_21626341
  var valid_21626342 = query.getOrDefault("Version")
  valid_21626342 = validateParameter(valid_21626342, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626342 != nil:
    section.add "Version", valid_21626342
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626343 = header.getOrDefault("X-Amz-Date")
  valid_21626343 = validateParameter(valid_21626343, JString, required = false,
                                   default = nil)
  if valid_21626343 != nil:
    section.add "X-Amz-Date", valid_21626343
  var valid_21626344 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626344 = validateParameter(valid_21626344, JString, required = false,
                                   default = nil)
  if valid_21626344 != nil:
    section.add "X-Amz-Security-Token", valid_21626344
  var valid_21626345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626345 = validateParameter(valid_21626345, JString, required = false,
                                   default = nil)
  if valid_21626345 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626345
  var valid_21626346 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626346 = validateParameter(valid_21626346, JString, required = false,
                                   default = nil)
  if valid_21626346 != nil:
    section.add "X-Amz-Algorithm", valid_21626346
  var valid_21626347 = header.getOrDefault("X-Amz-Signature")
  valid_21626347 = validateParameter(valid_21626347, JString, required = false,
                                   default = nil)
  if valid_21626347 != nil:
    section.add "X-Amz-Signature", valid_21626347
  var valid_21626348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626348 = validateParameter(valid_21626348, JString, required = false,
                                   default = nil)
  if valid_21626348 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626348
  var valid_21626349 = header.getOrDefault("X-Amz-Credential")
  valid_21626349 = validateParameter(valid_21626349, JString, required = false,
                                   default = nil)
  if valid_21626349 != nil:
    section.add "X-Amz-Credential", valid_21626349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626350: Call_GetDeleteTopic_21626337; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ## 
  let valid = call_21626350.validator(path, query, header, formData, body, _)
  let scheme = call_21626350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626350.makeUrl(scheme.get, call_21626350.host, call_21626350.base,
                               call_21626350.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626350, uri, valid, _)

proc call*(call_21626351: Call_GetDeleteTopic_21626337; TopicArn: string;
          Action: string = "DeleteTopic"; Version: string = "2010-03-31"): Recallable =
  ## getDeleteTopic
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ##   Action: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to delete.
  ##   Version: string (required)
  var query_21626352 = newJObject()
  add(query_21626352, "Action", newJString(Action))
  add(query_21626352, "TopicArn", newJString(TopicArn))
  add(query_21626352, "Version", newJString(Version))
  result = call_21626351.call(nil, query_21626352, nil, nil, nil)

var getDeleteTopic* = Call_GetDeleteTopic_21626337(name: "getDeleteTopic",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=DeleteTopic", validator: validate_GetDeleteTopic_21626338,
    base: "/", makeUrl: url_GetDeleteTopic_21626339,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetEndpointAttributes_21626386 = ref object of OpenApiRestCall_21625435
proc url_PostGetEndpointAttributes_21626388(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetEndpointAttributes_21626387(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626389 = query.getOrDefault("Action")
  valid_21626389 = validateParameter(valid_21626389, JString, required = true, default = newJString(
      "GetEndpointAttributes"))
  if valid_21626389 != nil:
    section.add "Action", valid_21626389
  var valid_21626390 = query.getOrDefault("Version")
  valid_21626390 = validateParameter(valid_21626390, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626390 != nil:
    section.add "Version", valid_21626390
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626391 = header.getOrDefault("X-Amz-Date")
  valid_21626391 = validateParameter(valid_21626391, JString, required = false,
                                   default = nil)
  if valid_21626391 != nil:
    section.add "X-Amz-Date", valid_21626391
  var valid_21626392 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626392 = validateParameter(valid_21626392, JString, required = false,
                                   default = nil)
  if valid_21626392 != nil:
    section.add "X-Amz-Security-Token", valid_21626392
  var valid_21626393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626393 = validateParameter(valid_21626393, JString, required = false,
                                   default = nil)
  if valid_21626393 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626393
  var valid_21626394 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626394 = validateParameter(valid_21626394, JString, required = false,
                                   default = nil)
  if valid_21626394 != nil:
    section.add "X-Amz-Algorithm", valid_21626394
  var valid_21626395 = header.getOrDefault("X-Amz-Signature")
  valid_21626395 = validateParameter(valid_21626395, JString, required = false,
                                   default = nil)
  if valid_21626395 != nil:
    section.add "X-Amz-Signature", valid_21626395
  var valid_21626396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626396 = validateParameter(valid_21626396, JString, required = false,
                                   default = nil)
  if valid_21626396 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626396
  var valid_21626397 = header.getOrDefault("X-Amz-Credential")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "X-Amz-Credential", valid_21626397
  result.add "header", section
  ## parameters in `formData` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_21626398 = formData.getOrDefault("EndpointArn")
  valid_21626398 = validateParameter(valid_21626398, JString, required = true,
                                   default = nil)
  if valid_21626398 != nil:
    section.add "EndpointArn", valid_21626398
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626399: Call_PostGetEndpointAttributes_21626386;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_21626399.validator(path, query, header, formData, body, _)
  let scheme = call_21626399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626399.makeUrl(scheme.get, call_21626399.host, call_21626399.base,
                               call_21626399.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626399, uri, valid, _)

proc call*(call_21626400: Call_PostGetEndpointAttributes_21626386;
          EndpointArn: string; Action: string = "GetEndpointAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetEndpointAttributes
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   EndpointArn: string (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  ##   Version: string (required)
  var query_21626401 = newJObject()
  var formData_21626402 = newJObject()
  add(query_21626401, "Action", newJString(Action))
  add(formData_21626402, "EndpointArn", newJString(EndpointArn))
  add(query_21626401, "Version", newJString(Version))
  result = call_21626400.call(nil, query_21626401, nil, formData_21626402, nil)

var postGetEndpointAttributes* = Call_PostGetEndpointAttributes_21626386(
    name: "postGetEndpointAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetEndpointAttributes",
    validator: validate_PostGetEndpointAttributes_21626387, base: "/",
    makeUrl: url_PostGetEndpointAttributes_21626388,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetEndpointAttributes_21626370 = ref object of OpenApiRestCall_21625435
proc url_GetGetEndpointAttributes_21626372(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetEndpointAttributes_21626371(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
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
  var valid_21626373 = query.getOrDefault("EndpointArn")
  valid_21626373 = validateParameter(valid_21626373, JString, required = true,
                                   default = nil)
  if valid_21626373 != nil:
    section.add "EndpointArn", valid_21626373
  var valid_21626374 = query.getOrDefault("Action")
  valid_21626374 = validateParameter(valid_21626374, JString, required = true, default = newJString(
      "GetEndpointAttributes"))
  if valid_21626374 != nil:
    section.add "Action", valid_21626374
  var valid_21626375 = query.getOrDefault("Version")
  valid_21626375 = validateParameter(valid_21626375, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626375 != nil:
    section.add "Version", valid_21626375
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626376 = header.getOrDefault("X-Amz-Date")
  valid_21626376 = validateParameter(valid_21626376, JString, required = false,
                                   default = nil)
  if valid_21626376 != nil:
    section.add "X-Amz-Date", valid_21626376
  var valid_21626377 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626377 = validateParameter(valid_21626377, JString, required = false,
                                   default = nil)
  if valid_21626377 != nil:
    section.add "X-Amz-Security-Token", valid_21626377
  var valid_21626378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626378 = validateParameter(valid_21626378, JString, required = false,
                                   default = nil)
  if valid_21626378 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626378
  var valid_21626379 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626379 = validateParameter(valid_21626379, JString, required = false,
                                   default = nil)
  if valid_21626379 != nil:
    section.add "X-Amz-Algorithm", valid_21626379
  var valid_21626380 = header.getOrDefault("X-Amz-Signature")
  valid_21626380 = validateParameter(valid_21626380, JString, required = false,
                                   default = nil)
  if valid_21626380 != nil:
    section.add "X-Amz-Signature", valid_21626380
  var valid_21626381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626381 = validateParameter(valid_21626381, JString, required = false,
                                   default = nil)
  if valid_21626381 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626381
  var valid_21626382 = header.getOrDefault("X-Amz-Credential")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "X-Amz-Credential", valid_21626382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626383: Call_GetGetEndpointAttributes_21626370;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_21626383.validator(path, query, header, formData, body, _)
  let scheme = call_21626383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626383.makeUrl(scheme.get, call_21626383.host, call_21626383.base,
                               call_21626383.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626383, uri, valid, _)

proc call*(call_21626384: Call_GetGetEndpointAttributes_21626370;
          EndpointArn: string; Action: string = "GetEndpointAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getGetEndpointAttributes
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   EndpointArn: string (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626385 = newJObject()
  add(query_21626385, "EndpointArn", newJString(EndpointArn))
  add(query_21626385, "Action", newJString(Action))
  add(query_21626385, "Version", newJString(Version))
  result = call_21626384.call(nil, query_21626385, nil, nil, nil)

var getGetEndpointAttributes* = Call_GetGetEndpointAttributes_21626370(
    name: "getGetEndpointAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetEndpointAttributes",
    validator: validate_GetGetEndpointAttributes_21626371, base: "/",
    makeUrl: url_GetGetEndpointAttributes_21626372,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetPlatformApplicationAttributes_21626419 = ref object of OpenApiRestCall_21625435
proc url_PostGetPlatformApplicationAttributes_21626421(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetPlatformApplicationAttributes_21626420(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626422 = query.getOrDefault("Action")
  valid_21626422 = validateParameter(valid_21626422, JString, required = true, default = newJString(
      "GetPlatformApplicationAttributes"))
  if valid_21626422 != nil:
    section.add "Action", valid_21626422
  var valid_21626423 = query.getOrDefault("Version")
  valid_21626423 = validateParameter(valid_21626423, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626423 != nil:
    section.add "Version", valid_21626423
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626424 = header.getOrDefault("X-Amz-Date")
  valid_21626424 = validateParameter(valid_21626424, JString, required = false,
                                   default = nil)
  if valid_21626424 != nil:
    section.add "X-Amz-Date", valid_21626424
  var valid_21626425 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626425 = validateParameter(valid_21626425, JString, required = false,
                                   default = nil)
  if valid_21626425 != nil:
    section.add "X-Amz-Security-Token", valid_21626425
  var valid_21626426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626426 = validateParameter(valid_21626426, JString, required = false,
                                   default = nil)
  if valid_21626426 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626426
  var valid_21626427 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626427 = validateParameter(valid_21626427, JString, required = false,
                                   default = nil)
  if valid_21626427 != nil:
    section.add "X-Amz-Algorithm", valid_21626427
  var valid_21626428 = header.getOrDefault("X-Amz-Signature")
  valid_21626428 = validateParameter(valid_21626428, JString, required = false,
                                   default = nil)
  if valid_21626428 != nil:
    section.add "X-Amz-Signature", valid_21626428
  var valid_21626429 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626429 = validateParameter(valid_21626429, JString, required = false,
                                   default = nil)
  if valid_21626429 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626429
  var valid_21626430 = header.getOrDefault("X-Amz-Credential")
  valid_21626430 = validateParameter(valid_21626430, JString, required = false,
                                   default = nil)
  if valid_21626430 != nil:
    section.add "X-Amz-Credential", valid_21626430
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_21626431 = formData.getOrDefault("PlatformApplicationArn")
  valid_21626431 = validateParameter(valid_21626431, JString, required = true,
                                   default = nil)
  if valid_21626431 != nil:
    section.add "PlatformApplicationArn", valid_21626431
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626432: Call_PostGetPlatformApplicationAttributes_21626419;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_21626432.validator(path, query, header, formData, body, _)
  let scheme = call_21626432.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626432.makeUrl(scheme.get, call_21626432.host, call_21626432.base,
                               call_21626432.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626432, uri, valid, _)

proc call*(call_21626433: Call_PostGetPlatformApplicationAttributes_21626419;
          PlatformApplicationArn: string;
          Action: string = "GetPlatformApplicationAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetPlatformApplicationAttributes
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  ##   Version: string (required)
  var query_21626434 = newJObject()
  var formData_21626435 = newJObject()
  add(query_21626434, "Action", newJString(Action))
  add(formData_21626435, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(query_21626434, "Version", newJString(Version))
  result = call_21626433.call(nil, query_21626434, nil, formData_21626435, nil)

var postGetPlatformApplicationAttributes* = Call_PostGetPlatformApplicationAttributes_21626419(
    name: "postGetPlatformApplicationAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetPlatformApplicationAttributes",
    validator: validate_PostGetPlatformApplicationAttributes_21626420, base: "/",
    makeUrl: url_PostGetPlatformApplicationAttributes_21626421,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetPlatformApplicationAttributes_21626403 = ref object of OpenApiRestCall_21625435
proc url_GetGetPlatformApplicationAttributes_21626405(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetPlatformApplicationAttributes_21626404(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
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
  var valid_21626406 = query.getOrDefault("Action")
  valid_21626406 = validateParameter(valid_21626406, JString, required = true, default = newJString(
      "GetPlatformApplicationAttributes"))
  if valid_21626406 != nil:
    section.add "Action", valid_21626406
  var valid_21626407 = query.getOrDefault("Version")
  valid_21626407 = validateParameter(valid_21626407, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626407 != nil:
    section.add "Version", valid_21626407
  var valid_21626408 = query.getOrDefault("PlatformApplicationArn")
  valid_21626408 = validateParameter(valid_21626408, JString, required = true,
                                   default = nil)
  if valid_21626408 != nil:
    section.add "PlatformApplicationArn", valid_21626408
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626409 = header.getOrDefault("X-Amz-Date")
  valid_21626409 = validateParameter(valid_21626409, JString, required = false,
                                   default = nil)
  if valid_21626409 != nil:
    section.add "X-Amz-Date", valid_21626409
  var valid_21626410 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626410 = validateParameter(valid_21626410, JString, required = false,
                                   default = nil)
  if valid_21626410 != nil:
    section.add "X-Amz-Security-Token", valid_21626410
  var valid_21626411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626411 = validateParameter(valid_21626411, JString, required = false,
                                   default = nil)
  if valid_21626411 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626411
  var valid_21626412 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626412 = validateParameter(valid_21626412, JString, required = false,
                                   default = nil)
  if valid_21626412 != nil:
    section.add "X-Amz-Algorithm", valid_21626412
  var valid_21626413 = header.getOrDefault("X-Amz-Signature")
  valid_21626413 = validateParameter(valid_21626413, JString, required = false,
                                   default = nil)
  if valid_21626413 != nil:
    section.add "X-Amz-Signature", valid_21626413
  var valid_21626414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626414 = validateParameter(valid_21626414, JString, required = false,
                                   default = nil)
  if valid_21626414 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626414
  var valid_21626415 = header.getOrDefault("X-Amz-Credential")
  valid_21626415 = validateParameter(valid_21626415, JString, required = false,
                                   default = nil)
  if valid_21626415 != nil:
    section.add "X-Amz-Credential", valid_21626415
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626416: Call_GetGetPlatformApplicationAttributes_21626403;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_21626416.validator(path, query, header, formData, body, _)
  let scheme = call_21626416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626416.makeUrl(scheme.get, call_21626416.host, call_21626416.base,
                               call_21626416.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626416, uri, valid, _)

proc call*(call_21626417: Call_GetGetPlatformApplicationAttributes_21626403;
          PlatformApplicationArn: string;
          Action: string = "GetPlatformApplicationAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getGetPlatformApplicationAttributes
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  var query_21626418 = newJObject()
  add(query_21626418, "Action", newJString(Action))
  add(query_21626418, "Version", newJString(Version))
  add(query_21626418, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_21626417.call(nil, query_21626418, nil, nil, nil)

var getGetPlatformApplicationAttributes* = Call_GetGetPlatformApplicationAttributes_21626403(
    name: "getGetPlatformApplicationAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetPlatformApplicationAttributes",
    validator: validate_GetGetPlatformApplicationAttributes_21626404, base: "/",
    makeUrl: url_GetGetPlatformApplicationAttributes_21626405,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetSMSAttributes_21626452 = ref object of OpenApiRestCall_21625435
proc url_PostGetSMSAttributes_21626454(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetSMSAttributes_21626453(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626455 = query.getOrDefault("Action")
  valid_21626455 = validateParameter(valid_21626455, JString, required = true,
                                   default = newJString("GetSMSAttributes"))
  if valid_21626455 != nil:
    section.add "Action", valid_21626455
  var valid_21626456 = query.getOrDefault("Version")
  valid_21626456 = validateParameter(valid_21626456, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626456 != nil:
    section.add "Version", valid_21626456
  result.add "query", section
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
  ## parameters in `formData` object:
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  section = newJObject()
  var valid_21626464 = formData.getOrDefault("attributes")
  valid_21626464 = validateParameter(valid_21626464, JArray, required = false,
                                   default = nil)
  if valid_21626464 != nil:
    section.add "attributes", valid_21626464
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626465: Call_PostGetSMSAttributes_21626452; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  let valid = call_21626465.validator(path, query, header, formData, body, _)
  let scheme = call_21626465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626465.makeUrl(scheme.get, call_21626465.host, call_21626465.base,
                               call_21626465.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626465, uri, valid, _)

proc call*(call_21626466: Call_PostGetSMSAttributes_21626452;
          attributes: JsonNode = nil; Action: string = "GetSMSAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetSMSAttributes
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626467 = newJObject()
  var formData_21626468 = newJObject()
  if attributes != nil:
    formData_21626468.add "attributes", attributes
  add(query_21626467, "Action", newJString(Action))
  add(query_21626467, "Version", newJString(Version))
  result = call_21626466.call(nil, query_21626467, nil, formData_21626468, nil)

var postGetSMSAttributes* = Call_PostGetSMSAttributes_21626452(
    name: "postGetSMSAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetSMSAttributes",
    validator: validate_PostGetSMSAttributes_21626453, base: "/",
    makeUrl: url_PostGetSMSAttributes_21626454,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetSMSAttributes_21626436 = ref object of OpenApiRestCall_21625435
proc url_GetGetSMSAttributes_21626438(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetSMSAttributes_21626437(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626439 = query.getOrDefault("attributes")
  valid_21626439 = validateParameter(valid_21626439, JArray, required = false,
                                   default = nil)
  if valid_21626439 != nil:
    section.add "attributes", valid_21626439
  var valid_21626440 = query.getOrDefault("Action")
  valid_21626440 = validateParameter(valid_21626440, JString, required = true,
                                   default = newJString("GetSMSAttributes"))
  if valid_21626440 != nil:
    section.add "Action", valid_21626440
  var valid_21626441 = query.getOrDefault("Version")
  valid_21626441 = validateParameter(valid_21626441, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626441 != nil:
    section.add "Version", valid_21626441
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626442 = header.getOrDefault("X-Amz-Date")
  valid_21626442 = validateParameter(valid_21626442, JString, required = false,
                                   default = nil)
  if valid_21626442 != nil:
    section.add "X-Amz-Date", valid_21626442
  var valid_21626443 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626443 = validateParameter(valid_21626443, JString, required = false,
                                   default = nil)
  if valid_21626443 != nil:
    section.add "X-Amz-Security-Token", valid_21626443
  var valid_21626444 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626444 = validateParameter(valid_21626444, JString, required = false,
                                   default = nil)
  if valid_21626444 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626444
  var valid_21626445 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626445 = validateParameter(valid_21626445, JString, required = false,
                                   default = nil)
  if valid_21626445 != nil:
    section.add "X-Amz-Algorithm", valid_21626445
  var valid_21626446 = header.getOrDefault("X-Amz-Signature")
  valid_21626446 = validateParameter(valid_21626446, JString, required = false,
                                   default = nil)
  if valid_21626446 != nil:
    section.add "X-Amz-Signature", valid_21626446
  var valid_21626447 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626447 = validateParameter(valid_21626447, JString, required = false,
                                   default = nil)
  if valid_21626447 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626447
  var valid_21626448 = header.getOrDefault("X-Amz-Credential")
  valid_21626448 = validateParameter(valid_21626448, JString, required = false,
                                   default = nil)
  if valid_21626448 != nil:
    section.add "X-Amz-Credential", valid_21626448
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626449: Call_GetGetSMSAttributes_21626436; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  let valid = call_21626449.validator(path, query, header, formData, body, _)
  let scheme = call_21626449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626449.makeUrl(scheme.get, call_21626449.host, call_21626449.base,
                               call_21626449.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626449, uri, valid, _)

proc call*(call_21626450: Call_GetGetSMSAttributes_21626436;
          attributes: JsonNode = nil; Action: string = "GetSMSAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getGetSMSAttributes
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626451 = newJObject()
  if attributes != nil:
    query_21626451.add "attributes", attributes
  add(query_21626451, "Action", newJString(Action))
  add(query_21626451, "Version", newJString(Version))
  result = call_21626450.call(nil, query_21626451, nil, nil, nil)

var getGetSMSAttributes* = Call_GetGetSMSAttributes_21626436(
    name: "getGetSMSAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetSMSAttributes",
    validator: validate_GetGetSMSAttributes_21626437, base: "/",
    makeUrl: url_GetGetSMSAttributes_21626438,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetSubscriptionAttributes_21626485 = ref object of OpenApiRestCall_21625435
proc url_PostGetSubscriptionAttributes_21626487(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetSubscriptionAttributes_21626486(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626488 = query.getOrDefault("Action")
  valid_21626488 = validateParameter(valid_21626488, JString, required = true, default = newJString(
      "GetSubscriptionAttributes"))
  if valid_21626488 != nil:
    section.add "Action", valid_21626488
  var valid_21626489 = query.getOrDefault("Version")
  valid_21626489 = validateParameter(valid_21626489, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626489 != nil:
    section.add "Version", valid_21626489
  result.add "query", section
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
  ## parameters in `formData` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionArn` field"
  var valid_21626497 = formData.getOrDefault("SubscriptionArn")
  valid_21626497 = validateParameter(valid_21626497, JString, required = true,
                                   default = nil)
  if valid_21626497 != nil:
    section.add "SubscriptionArn", valid_21626497
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626498: Call_PostGetSubscriptionAttributes_21626485;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns all of the properties of a subscription.
  ## 
  let valid = call_21626498.validator(path, query, header, formData, body, _)
  let scheme = call_21626498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626498.makeUrl(scheme.get, call_21626498.host, call_21626498.base,
                               call_21626498.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626498, uri, valid, _)

proc call*(call_21626499: Call_PostGetSubscriptionAttributes_21626485;
          SubscriptionArn: string; Action: string = "GetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetSubscriptionAttributes
  ## Returns all of the properties of a subscription.
  ##   Action: string (required)
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  ##   Version: string (required)
  var query_21626500 = newJObject()
  var formData_21626501 = newJObject()
  add(query_21626500, "Action", newJString(Action))
  add(formData_21626501, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_21626500, "Version", newJString(Version))
  result = call_21626499.call(nil, query_21626500, nil, formData_21626501, nil)

var postGetSubscriptionAttributes* = Call_PostGetSubscriptionAttributes_21626485(
    name: "postGetSubscriptionAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetSubscriptionAttributes",
    validator: validate_PostGetSubscriptionAttributes_21626486, base: "/",
    makeUrl: url_PostGetSubscriptionAttributes_21626487,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetSubscriptionAttributes_21626469 = ref object of OpenApiRestCall_21625435
proc url_GetGetSubscriptionAttributes_21626471(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetSubscriptionAttributes_21626470(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626472 = query.getOrDefault("SubscriptionArn")
  valid_21626472 = validateParameter(valid_21626472, JString, required = true,
                                   default = nil)
  if valid_21626472 != nil:
    section.add "SubscriptionArn", valid_21626472
  var valid_21626473 = query.getOrDefault("Action")
  valid_21626473 = validateParameter(valid_21626473, JString, required = true, default = newJString(
      "GetSubscriptionAttributes"))
  if valid_21626473 != nil:
    section.add "Action", valid_21626473
  var valid_21626474 = query.getOrDefault("Version")
  valid_21626474 = validateParameter(valid_21626474, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626474 != nil:
    section.add "Version", valid_21626474
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626475 = header.getOrDefault("X-Amz-Date")
  valid_21626475 = validateParameter(valid_21626475, JString, required = false,
                                   default = nil)
  if valid_21626475 != nil:
    section.add "X-Amz-Date", valid_21626475
  var valid_21626476 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626476 = validateParameter(valid_21626476, JString, required = false,
                                   default = nil)
  if valid_21626476 != nil:
    section.add "X-Amz-Security-Token", valid_21626476
  var valid_21626477 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626477 = validateParameter(valid_21626477, JString, required = false,
                                   default = nil)
  if valid_21626477 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626477
  var valid_21626478 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626478 = validateParameter(valid_21626478, JString, required = false,
                                   default = nil)
  if valid_21626478 != nil:
    section.add "X-Amz-Algorithm", valid_21626478
  var valid_21626479 = header.getOrDefault("X-Amz-Signature")
  valid_21626479 = validateParameter(valid_21626479, JString, required = false,
                                   default = nil)
  if valid_21626479 != nil:
    section.add "X-Amz-Signature", valid_21626479
  var valid_21626480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626480 = validateParameter(valid_21626480, JString, required = false,
                                   default = nil)
  if valid_21626480 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626480
  var valid_21626481 = header.getOrDefault("X-Amz-Credential")
  valid_21626481 = validateParameter(valid_21626481, JString, required = false,
                                   default = nil)
  if valid_21626481 != nil:
    section.add "X-Amz-Credential", valid_21626481
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626482: Call_GetGetSubscriptionAttributes_21626469;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns all of the properties of a subscription.
  ## 
  let valid = call_21626482.validator(path, query, header, formData, body, _)
  let scheme = call_21626482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626482.makeUrl(scheme.get, call_21626482.host, call_21626482.base,
                               call_21626482.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626482, uri, valid, _)

proc call*(call_21626483: Call_GetGetSubscriptionAttributes_21626469;
          SubscriptionArn: string; Action: string = "GetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getGetSubscriptionAttributes
  ## Returns all of the properties of a subscription.
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626484 = newJObject()
  add(query_21626484, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_21626484, "Action", newJString(Action))
  add(query_21626484, "Version", newJString(Version))
  result = call_21626483.call(nil, query_21626484, nil, nil, nil)

var getGetSubscriptionAttributes* = Call_GetGetSubscriptionAttributes_21626469(
    name: "getGetSubscriptionAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetSubscriptionAttributes",
    validator: validate_GetGetSubscriptionAttributes_21626470, base: "/",
    makeUrl: url_GetGetSubscriptionAttributes_21626471,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetTopicAttributes_21626518 = ref object of OpenApiRestCall_21625435
proc url_PostGetTopicAttributes_21626520(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetTopicAttributes_21626519(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626521 = query.getOrDefault("Action")
  valid_21626521 = validateParameter(valid_21626521, JString, required = true,
                                   default = newJString("GetTopicAttributes"))
  if valid_21626521 != nil:
    section.add "Action", valid_21626521
  var valid_21626522 = query.getOrDefault("Version")
  valid_21626522 = validateParameter(valid_21626522, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626522 != nil:
    section.add "Version", valid_21626522
  result.add "query", section
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
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose properties you want to get.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_21626530 = formData.getOrDefault("TopicArn")
  valid_21626530 = validateParameter(valid_21626530, JString, required = true,
                                   default = nil)
  if valid_21626530 != nil:
    section.add "TopicArn", valid_21626530
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626531: Call_PostGetTopicAttributes_21626518;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ## 
  let valid = call_21626531.validator(path, query, header, formData, body, _)
  let scheme = call_21626531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626531.makeUrl(scheme.get, call_21626531.host, call_21626531.base,
                               call_21626531.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626531, uri, valid, _)

proc call*(call_21626532: Call_PostGetTopicAttributes_21626518; TopicArn: string;
          Action: string = "GetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## postGetTopicAttributes
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose properties you want to get.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626533 = newJObject()
  var formData_21626534 = newJObject()
  add(formData_21626534, "TopicArn", newJString(TopicArn))
  add(query_21626533, "Action", newJString(Action))
  add(query_21626533, "Version", newJString(Version))
  result = call_21626532.call(nil, query_21626533, nil, formData_21626534, nil)

var postGetTopicAttributes* = Call_PostGetTopicAttributes_21626518(
    name: "postGetTopicAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetTopicAttributes",
    validator: validate_PostGetTopicAttributes_21626519, base: "/",
    makeUrl: url_PostGetTopicAttributes_21626520,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetTopicAttributes_21626502 = ref object of OpenApiRestCall_21625435
proc url_GetGetTopicAttributes_21626504(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetTopicAttributes_21626503(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626505 = query.getOrDefault("Action")
  valid_21626505 = validateParameter(valid_21626505, JString, required = true,
                                   default = newJString("GetTopicAttributes"))
  if valid_21626505 != nil:
    section.add "Action", valid_21626505
  var valid_21626506 = query.getOrDefault("TopicArn")
  valid_21626506 = validateParameter(valid_21626506, JString, required = true,
                                   default = nil)
  if valid_21626506 != nil:
    section.add "TopicArn", valid_21626506
  var valid_21626507 = query.getOrDefault("Version")
  valid_21626507 = validateParameter(valid_21626507, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626507 != nil:
    section.add "Version", valid_21626507
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626508 = header.getOrDefault("X-Amz-Date")
  valid_21626508 = validateParameter(valid_21626508, JString, required = false,
                                   default = nil)
  if valid_21626508 != nil:
    section.add "X-Amz-Date", valid_21626508
  var valid_21626509 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626509 = validateParameter(valid_21626509, JString, required = false,
                                   default = nil)
  if valid_21626509 != nil:
    section.add "X-Amz-Security-Token", valid_21626509
  var valid_21626510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626510 = validateParameter(valid_21626510, JString, required = false,
                                   default = nil)
  if valid_21626510 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626510
  var valid_21626511 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626511 = validateParameter(valid_21626511, JString, required = false,
                                   default = nil)
  if valid_21626511 != nil:
    section.add "X-Amz-Algorithm", valid_21626511
  var valid_21626512 = header.getOrDefault("X-Amz-Signature")
  valid_21626512 = validateParameter(valid_21626512, JString, required = false,
                                   default = nil)
  if valid_21626512 != nil:
    section.add "X-Amz-Signature", valid_21626512
  var valid_21626513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626513 = validateParameter(valid_21626513, JString, required = false,
                                   default = nil)
  if valid_21626513 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626513
  var valid_21626514 = header.getOrDefault("X-Amz-Credential")
  valid_21626514 = validateParameter(valid_21626514, JString, required = false,
                                   default = nil)
  if valid_21626514 != nil:
    section.add "X-Amz-Credential", valid_21626514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626515: Call_GetGetTopicAttributes_21626502;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ## 
  let valid = call_21626515.validator(path, query, header, formData, body, _)
  let scheme = call_21626515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626515.makeUrl(scheme.get, call_21626515.host, call_21626515.base,
                               call_21626515.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626515, uri, valid, _)

proc call*(call_21626516: Call_GetGetTopicAttributes_21626502; TopicArn: string;
          Action: string = "GetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## getGetTopicAttributes
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ##   Action: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose properties you want to get.
  ##   Version: string (required)
  var query_21626517 = newJObject()
  add(query_21626517, "Action", newJString(Action))
  add(query_21626517, "TopicArn", newJString(TopicArn))
  add(query_21626517, "Version", newJString(Version))
  result = call_21626516.call(nil, query_21626517, nil, nil, nil)

var getGetTopicAttributes* = Call_GetGetTopicAttributes_21626502(
    name: "getGetTopicAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetTopicAttributes",
    validator: validate_GetGetTopicAttributes_21626503, base: "/",
    makeUrl: url_GetGetTopicAttributes_21626504,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListEndpointsByPlatformApplication_21626552 = ref object of OpenApiRestCall_21625435
proc url_PostListEndpointsByPlatformApplication_21626554(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListEndpointsByPlatformApplication_21626553(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as FCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626555 = query.getOrDefault("Action")
  valid_21626555 = validateParameter(valid_21626555, JString, required = true, default = newJString(
      "ListEndpointsByPlatformApplication"))
  if valid_21626555 != nil:
    section.add "Action", valid_21626555
  var valid_21626556 = query.getOrDefault("Version")
  valid_21626556 = validateParameter(valid_21626556, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626556 != nil:
    section.add "Version", valid_21626556
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626557 = header.getOrDefault("X-Amz-Date")
  valid_21626557 = validateParameter(valid_21626557, JString, required = false,
                                   default = nil)
  if valid_21626557 != nil:
    section.add "X-Amz-Date", valid_21626557
  var valid_21626558 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626558 = validateParameter(valid_21626558, JString, required = false,
                                   default = nil)
  if valid_21626558 != nil:
    section.add "X-Amz-Security-Token", valid_21626558
  var valid_21626559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626559 = validateParameter(valid_21626559, JString, required = false,
                                   default = nil)
  if valid_21626559 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626559
  var valid_21626560 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626560 = validateParameter(valid_21626560, JString, required = false,
                                   default = nil)
  if valid_21626560 != nil:
    section.add "X-Amz-Algorithm", valid_21626560
  var valid_21626561 = header.getOrDefault("X-Amz-Signature")
  valid_21626561 = validateParameter(valid_21626561, JString, required = false,
                                   default = nil)
  if valid_21626561 != nil:
    section.add "X-Amz-Signature", valid_21626561
  var valid_21626562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626562 = validateParameter(valid_21626562, JString, required = false,
                                   default = nil)
  if valid_21626562 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626562
  var valid_21626563 = header.getOrDefault("X-Amz-Credential")
  valid_21626563 = validateParameter(valid_21626563, JString, required = false,
                                   default = nil)
  if valid_21626563 != nil:
    section.add "X-Amz-Credential", valid_21626563
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListEndpointsByPlatformApplication action to retrieve additional records that are available after the first page results.
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  section = newJObject()
  var valid_21626564 = formData.getOrDefault("NextToken")
  valid_21626564 = validateParameter(valid_21626564, JString, required = false,
                                   default = nil)
  if valid_21626564 != nil:
    section.add "NextToken", valid_21626564
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_21626565 = formData.getOrDefault("PlatformApplicationArn")
  valid_21626565 = validateParameter(valid_21626565, JString, required = true,
                                   default = nil)
  if valid_21626565 != nil:
    section.add "PlatformApplicationArn", valid_21626565
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626566: Call_PostListEndpointsByPlatformApplication_21626552;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as FCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_21626566.validator(path, query, header, formData, body, _)
  let scheme = call_21626566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626566.makeUrl(scheme.get, call_21626566.host, call_21626566.base,
                               call_21626566.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626566, uri, valid, _)

proc call*(call_21626567: Call_PostListEndpointsByPlatformApplication_21626552;
          PlatformApplicationArn: string; NextToken: string = "";
          Action: string = "ListEndpointsByPlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## postListEndpointsByPlatformApplication
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as FCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListEndpointsByPlatformApplication action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  ##   Version: string (required)
  var query_21626568 = newJObject()
  var formData_21626569 = newJObject()
  add(formData_21626569, "NextToken", newJString(NextToken))
  add(query_21626568, "Action", newJString(Action))
  add(formData_21626569, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(query_21626568, "Version", newJString(Version))
  result = call_21626567.call(nil, query_21626568, nil, formData_21626569, nil)

var postListEndpointsByPlatformApplication* = Call_PostListEndpointsByPlatformApplication_21626552(
    name: "postListEndpointsByPlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com",
    route: "/#Action=ListEndpointsByPlatformApplication",
    validator: validate_PostListEndpointsByPlatformApplication_21626553,
    base: "/", makeUrl: url_PostListEndpointsByPlatformApplication_21626554,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListEndpointsByPlatformApplication_21626535 = ref object of OpenApiRestCall_21625435
proc url_GetListEndpointsByPlatformApplication_21626537(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListEndpointsByPlatformApplication_21626536(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as FCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
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
  var valid_21626538 = query.getOrDefault("NextToken")
  valid_21626538 = validateParameter(valid_21626538, JString, required = false,
                                   default = nil)
  if valid_21626538 != nil:
    section.add "NextToken", valid_21626538
  var valid_21626539 = query.getOrDefault("Action")
  valid_21626539 = validateParameter(valid_21626539, JString, required = true, default = newJString(
      "ListEndpointsByPlatformApplication"))
  if valid_21626539 != nil:
    section.add "Action", valid_21626539
  var valid_21626540 = query.getOrDefault("Version")
  valid_21626540 = validateParameter(valid_21626540, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626540 != nil:
    section.add "Version", valid_21626540
  var valid_21626541 = query.getOrDefault("PlatformApplicationArn")
  valid_21626541 = validateParameter(valid_21626541, JString, required = true,
                                   default = nil)
  if valid_21626541 != nil:
    section.add "PlatformApplicationArn", valid_21626541
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626542 = header.getOrDefault("X-Amz-Date")
  valid_21626542 = validateParameter(valid_21626542, JString, required = false,
                                   default = nil)
  if valid_21626542 != nil:
    section.add "X-Amz-Date", valid_21626542
  var valid_21626543 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626543 = validateParameter(valid_21626543, JString, required = false,
                                   default = nil)
  if valid_21626543 != nil:
    section.add "X-Amz-Security-Token", valid_21626543
  var valid_21626544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626544 = validateParameter(valid_21626544, JString, required = false,
                                   default = nil)
  if valid_21626544 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626544
  var valid_21626545 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626545 = validateParameter(valid_21626545, JString, required = false,
                                   default = nil)
  if valid_21626545 != nil:
    section.add "X-Amz-Algorithm", valid_21626545
  var valid_21626546 = header.getOrDefault("X-Amz-Signature")
  valid_21626546 = validateParameter(valid_21626546, JString, required = false,
                                   default = nil)
  if valid_21626546 != nil:
    section.add "X-Amz-Signature", valid_21626546
  var valid_21626547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626547 = validateParameter(valid_21626547, JString, required = false,
                                   default = nil)
  if valid_21626547 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626547
  var valid_21626548 = header.getOrDefault("X-Amz-Credential")
  valid_21626548 = validateParameter(valid_21626548, JString, required = false,
                                   default = nil)
  if valid_21626548 != nil:
    section.add "X-Amz-Credential", valid_21626548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626549: Call_GetListEndpointsByPlatformApplication_21626535;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as FCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_21626549.validator(path, query, header, formData, body, _)
  let scheme = call_21626549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626549.makeUrl(scheme.get, call_21626549.host, call_21626549.base,
                               call_21626549.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626549, uri, valid, _)

proc call*(call_21626550: Call_GetListEndpointsByPlatformApplication_21626535;
          PlatformApplicationArn: string; NextToken: string = "";
          Action: string = "ListEndpointsByPlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## getListEndpointsByPlatformApplication
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as FCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListEndpointsByPlatformApplication action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  var query_21626551 = newJObject()
  add(query_21626551, "NextToken", newJString(NextToken))
  add(query_21626551, "Action", newJString(Action))
  add(query_21626551, "Version", newJString(Version))
  add(query_21626551, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_21626550.call(nil, query_21626551, nil, nil, nil)

var getListEndpointsByPlatformApplication* = Call_GetListEndpointsByPlatformApplication_21626535(
    name: "getListEndpointsByPlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com",
    route: "/#Action=ListEndpointsByPlatformApplication",
    validator: validate_GetListEndpointsByPlatformApplication_21626536, base: "/",
    makeUrl: url_GetListEndpointsByPlatformApplication_21626537,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPhoneNumbersOptedOut_21626586 = ref object of OpenApiRestCall_21625435
proc url_PostListPhoneNumbersOptedOut_21626588(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListPhoneNumbersOptedOut_21626587(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626589 = query.getOrDefault("Action")
  valid_21626589 = validateParameter(valid_21626589, JString, required = true, default = newJString(
      "ListPhoneNumbersOptedOut"))
  if valid_21626589 != nil:
    section.add "Action", valid_21626589
  var valid_21626590 = query.getOrDefault("Version")
  valid_21626590 = validateParameter(valid_21626590, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626590 != nil:
    section.add "Version", valid_21626590
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626591 = header.getOrDefault("X-Amz-Date")
  valid_21626591 = validateParameter(valid_21626591, JString, required = false,
                                   default = nil)
  if valid_21626591 != nil:
    section.add "X-Amz-Date", valid_21626591
  var valid_21626592 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626592 = validateParameter(valid_21626592, JString, required = false,
                                   default = nil)
  if valid_21626592 != nil:
    section.add "X-Amz-Security-Token", valid_21626592
  var valid_21626593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626593 = validateParameter(valid_21626593, JString, required = false,
                                   default = nil)
  if valid_21626593 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626593
  var valid_21626594 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626594 = validateParameter(valid_21626594, JString, required = false,
                                   default = nil)
  if valid_21626594 != nil:
    section.add "X-Amz-Algorithm", valid_21626594
  var valid_21626595 = header.getOrDefault("X-Amz-Signature")
  valid_21626595 = validateParameter(valid_21626595, JString, required = false,
                                   default = nil)
  if valid_21626595 != nil:
    section.add "X-Amz-Signature", valid_21626595
  var valid_21626596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626596 = validateParameter(valid_21626596, JString, required = false,
                                   default = nil)
  if valid_21626596 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626596
  var valid_21626597 = header.getOrDefault("X-Amz-Credential")
  valid_21626597 = validateParameter(valid_21626597, JString, required = false,
                                   default = nil)
  if valid_21626597 != nil:
    section.add "X-Amz-Credential", valid_21626597
  result.add "header", section
  ## parameters in `formData` object:
  ##   nextToken: JString
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  section = newJObject()
  var valid_21626598 = formData.getOrDefault("nextToken")
  valid_21626598 = validateParameter(valid_21626598, JString, required = false,
                                   default = nil)
  if valid_21626598 != nil:
    section.add "nextToken", valid_21626598
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626599: Call_PostListPhoneNumbersOptedOut_21626586;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ## 
  let valid = call_21626599.validator(path, query, header, formData, body, _)
  let scheme = call_21626599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626599.makeUrl(scheme.get, call_21626599.host, call_21626599.base,
                               call_21626599.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626599, uri, valid, _)

proc call*(call_21626600: Call_PostListPhoneNumbersOptedOut_21626586;
          Action: string = "ListPhoneNumbersOptedOut"; nextToken: string = "";
          Version: string = "2010-03-31"): Recallable =
  ## postListPhoneNumbersOptedOut
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ##   Action: string (required)
  ##   nextToken: string
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  ##   Version: string (required)
  var query_21626601 = newJObject()
  var formData_21626602 = newJObject()
  add(query_21626601, "Action", newJString(Action))
  add(formData_21626602, "nextToken", newJString(nextToken))
  add(query_21626601, "Version", newJString(Version))
  result = call_21626600.call(nil, query_21626601, nil, formData_21626602, nil)

var postListPhoneNumbersOptedOut* = Call_PostListPhoneNumbersOptedOut_21626586(
    name: "postListPhoneNumbersOptedOut", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListPhoneNumbersOptedOut",
    validator: validate_PostListPhoneNumbersOptedOut_21626587, base: "/",
    makeUrl: url_PostListPhoneNumbersOptedOut_21626588,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPhoneNumbersOptedOut_21626570 = ref object of OpenApiRestCall_21625435
proc url_GetListPhoneNumbersOptedOut_21626572(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListPhoneNumbersOptedOut_21626571(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626573 = query.getOrDefault("nextToken")
  valid_21626573 = validateParameter(valid_21626573, JString, required = false,
                                   default = nil)
  if valid_21626573 != nil:
    section.add "nextToken", valid_21626573
  var valid_21626574 = query.getOrDefault("Action")
  valid_21626574 = validateParameter(valid_21626574, JString, required = true, default = newJString(
      "ListPhoneNumbersOptedOut"))
  if valid_21626574 != nil:
    section.add "Action", valid_21626574
  var valid_21626575 = query.getOrDefault("Version")
  valid_21626575 = validateParameter(valid_21626575, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626575 != nil:
    section.add "Version", valid_21626575
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626576 = header.getOrDefault("X-Amz-Date")
  valid_21626576 = validateParameter(valid_21626576, JString, required = false,
                                   default = nil)
  if valid_21626576 != nil:
    section.add "X-Amz-Date", valid_21626576
  var valid_21626577 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626577 = validateParameter(valid_21626577, JString, required = false,
                                   default = nil)
  if valid_21626577 != nil:
    section.add "X-Amz-Security-Token", valid_21626577
  var valid_21626578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626578 = validateParameter(valid_21626578, JString, required = false,
                                   default = nil)
  if valid_21626578 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626578
  var valid_21626579 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626579 = validateParameter(valid_21626579, JString, required = false,
                                   default = nil)
  if valid_21626579 != nil:
    section.add "X-Amz-Algorithm", valid_21626579
  var valid_21626580 = header.getOrDefault("X-Amz-Signature")
  valid_21626580 = validateParameter(valid_21626580, JString, required = false,
                                   default = nil)
  if valid_21626580 != nil:
    section.add "X-Amz-Signature", valid_21626580
  var valid_21626581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626581 = validateParameter(valid_21626581, JString, required = false,
                                   default = nil)
  if valid_21626581 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626581
  var valid_21626582 = header.getOrDefault("X-Amz-Credential")
  valid_21626582 = validateParameter(valid_21626582, JString, required = false,
                                   default = nil)
  if valid_21626582 != nil:
    section.add "X-Amz-Credential", valid_21626582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626583: Call_GetListPhoneNumbersOptedOut_21626570;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ## 
  let valid = call_21626583.validator(path, query, header, formData, body, _)
  let scheme = call_21626583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626583.makeUrl(scheme.get, call_21626583.host, call_21626583.base,
                               call_21626583.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626583, uri, valid, _)

proc call*(call_21626584: Call_GetListPhoneNumbersOptedOut_21626570;
          nextToken: string = ""; Action: string = "ListPhoneNumbersOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## getListPhoneNumbersOptedOut
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ##   nextToken: string
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626585 = newJObject()
  add(query_21626585, "nextToken", newJString(nextToken))
  add(query_21626585, "Action", newJString(Action))
  add(query_21626585, "Version", newJString(Version))
  result = call_21626584.call(nil, query_21626585, nil, nil, nil)

var getListPhoneNumbersOptedOut* = Call_GetListPhoneNumbersOptedOut_21626570(
    name: "getListPhoneNumbersOptedOut", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListPhoneNumbersOptedOut",
    validator: validate_GetListPhoneNumbersOptedOut_21626571, base: "/",
    makeUrl: url_GetListPhoneNumbersOptedOut_21626572,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPlatformApplications_21626619 = ref object of OpenApiRestCall_21625435
proc url_PostListPlatformApplications_21626621(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListPlatformApplications_21626620(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and FCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626622 = query.getOrDefault("Action")
  valid_21626622 = validateParameter(valid_21626622, JString, required = true, default = newJString(
      "ListPlatformApplications"))
  if valid_21626622 != nil:
    section.add "Action", valid_21626622
  var valid_21626623 = query.getOrDefault("Version")
  valid_21626623 = validateParameter(valid_21626623, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626623 != nil:
    section.add "Version", valid_21626623
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626624 = header.getOrDefault("X-Amz-Date")
  valid_21626624 = validateParameter(valid_21626624, JString, required = false,
                                   default = nil)
  if valid_21626624 != nil:
    section.add "X-Amz-Date", valid_21626624
  var valid_21626625 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626625 = validateParameter(valid_21626625, JString, required = false,
                                   default = nil)
  if valid_21626625 != nil:
    section.add "X-Amz-Security-Token", valid_21626625
  var valid_21626626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626626 = validateParameter(valid_21626626, JString, required = false,
                                   default = nil)
  if valid_21626626 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626626
  var valid_21626627 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626627 = validateParameter(valid_21626627, JString, required = false,
                                   default = nil)
  if valid_21626627 != nil:
    section.add "X-Amz-Algorithm", valid_21626627
  var valid_21626628 = header.getOrDefault("X-Amz-Signature")
  valid_21626628 = validateParameter(valid_21626628, JString, required = false,
                                   default = nil)
  if valid_21626628 != nil:
    section.add "X-Amz-Signature", valid_21626628
  var valid_21626629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626629 = validateParameter(valid_21626629, JString, required = false,
                                   default = nil)
  if valid_21626629 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626629
  var valid_21626630 = header.getOrDefault("X-Amz-Credential")
  valid_21626630 = validateParameter(valid_21626630, JString, required = false,
                                   default = nil)
  if valid_21626630 != nil:
    section.add "X-Amz-Credential", valid_21626630
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  section = newJObject()
  var valid_21626631 = formData.getOrDefault("NextToken")
  valid_21626631 = validateParameter(valid_21626631, JString, required = false,
                                   default = nil)
  if valid_21626631 != nil:
    section.add "NextToken", valid_21626631
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626632: Call_PostListPlatformApplications_21626619;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and FCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  let valid = call_21626632.validator(path, query, header, formData, body, _)
  let scheme = call_21626632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626632.makeUrl(scheme.get, call_21626632.host, call_21626632.base,
                               call_21626632.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626632, uri, valid, _)

proc call*(call_21626633: Call_PostListPlatformApplications_21626619;
          NextToken: string = ""; Action: string = "ListPlatformApplications";
          Version: string = "2010-03-31"): Recallable =
  ## postListPlatformApplications
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and FCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626634 = newJObject()
  var formData_21626635 = newJObject()
  add(formData_21626635, "NextToken", newJString(NextToken))
  add(query_21626634, "Action", newJString(Action))
  add(query_21626634, "Version", newJString(Version))
  result = call_21626633.call(nil, query_21626634, nil, formData_21626635, nil)

var postListPlatformApplications* = Call_PostListPlatformApplications_21626619(
    name: "postListPlatformApplications", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListPlatformApplications",
    validator: validate_PostListPlatformApplications_21626620, base: "/",
    makeUrl: url_PostListPlatformApplications_21626621,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPlatformApplications_21626603 = ref object of OpenApiRestCall_21625435
proc url_GetListPlatformApplications_21626605(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListPlatformApplications_21626604(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and FCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
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
  var valid_21626606 = query.getOrDefault("NextToken")
  valid_21626606 = validateParameter(valid_21626606, JString, required = false,
                                   default = nil)
  if valid_21626606 != nil:
    section.add "NextToken", valid_21626606
  var valid_21626607 = query.getOrDefault("Action")
  valid_21626607 = validateParameter(valid_21626607, JString, required = true, default = newJString(
      "ListPlatformApplications"))
  if valid_21626607 != nil:
    section.add "Action", valid_21626607
  var valid_21626608 = query.getOrDefault("Version")
  valid_21626608 = validateParameter(valid_21626608, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626608 != nil:
    section.add "Version", valid_21626608
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626609 = header.getOrDefault("X-Amz-Date")
  valid_21626609 = validateParameter(valid_21626609, JString, required = false,
                                   default = nil)
  if valid_21626609 != nil:
    section.add "X-Amz-Date", valid_21626609
  var valid_21626610 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626610 = validateParameter(valid_21626610, JString, required = false,
                                   default = nil)
  if valid_21626610 != nil:
    section.add "X-Amz-Security-Token", valid_21626610
  var valid_21626611 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626611 = validateParameter(valid_21626611, JString, required = false,
                                   default = nil)
  if valid_21626611 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626611
  var valid_21626612 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626612 = validateParameter(valid_21626612, JString, required = false,
                                   default = nil)
  if valid_21626612 != nil:
    section.add "X-Amz-Algorithm", valid_21626612
  var valid_21626613 = header.getOrDefault("X-Amz-Signature")
  valid_21626613 = validateParameter(valid_21626613, JString, required = false,
                                   default = nil)
  if valid_21626613 != nil:
    section.add "X-Amz-Signature", valid_21626613
  var valid_21626614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626614 = validateParameter(valid_21626614, JString, required = false,
                                   default = nil)
  if valid_21626614 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626614
  var valid_21626615 = header.getOrDefault("X-Amz-Credential")
  valid_21626615 = validateParameter(valid_21626615, JString, required = false,
                                   default = nil)
  if valid_21626615 != nil:
    section.add "X-Amz-Credential", valid_21626615
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626616: Call_GetListPlatformApplications_21626603;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and FCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  let valid = call_21626616.validator(path, query, header, formData, body, _)
  let scheme = call_21626616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626616.makeUrl(scheme.get, call_21626616.host, call_21626616.base,
                               call_21626616.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626616, uri, valid, _)

proc call*(call_21626617: Call_GetListPlatformApplications_21626603;
          NextToken: string = ""; Action: string = "ListPlatformApplications";
          Version: string = "2010-03-31"): Recallable =
  ## getListPlatformApplications
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and FCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626618 = newJObject()
  add(query_21626618, "NextToken", newJString(NextToken))
  add(query_21626618, "Action", newJString(Action))
  add(query_21626618, "Version", newJString(Version))
  result = call_21626617.call(nil, query_21626618, nil, nil, nil)

var getListPlatformApplications* = Call_GetListPlatformApplications_21626603(
    name: "getListPlatformApplications", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListPlatformApplications",
    validator: validate_GetListPlatformApplications_21626604, base: "/",
    makeUrl: url_GetListPlatformApplications_21626605,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListSubscriptions_21626652 = ref object of OpenApiRestCall_21625435
proc url_PostListSubscriptions_21626654(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListSubscriptions_21626653(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626655 = query.getOrDefault("Action")
  valid_21626655 = validateParameter(valid_21626655, JString, required = true,
                                   default = newJString("ListSubscriptions"))
  if valid_21626655 != nil:
    section.add "Action", valid_21626655
  var valid_21626656 = query.getOrDefault("Version")
  valid_21626656 = validateParameter(valid_21626656, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626656 != nil:
    section.add "Version", valid_21626656
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626657 = header.getOrDefault("X-Amz-Date")
  valid_21626657 = validateParameter(valid_21626657, JString, required = false,
                                   default = nil)
  if valid_21626657 != nil:
    section.add "X-Amz-Date", valid_21626657
  var valid_21626658 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626658 = validateParameter(valid_21626658, JString, required = false,
                                   default = nil)
  if valid_21626658 != nil:
    section.add "X-Amz-Security-Token", valid_21626658
  var valid_21626659 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626659 = validateParameter(valid_21626659, JString, required = false,
                                   default = nil)
  if valid_21626659 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626659
  var valid_21626660 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626660 = validateParameter(valid_21626660, JString, required = false,
                                   default = nil)
  if valid_21626660 != nil:
    section.add "X-Amz-Algorithm", valid_21626660
  var valid_21626661 = header.getOrDefault("X-Amz-Signature")
  valid_21626661 = validateParameter(valid_21626661, JString, required = false,
                                   default = nil)
  if valid_21626661 != nil:
    section.add "X-Amz-Signature", valid_21626661
  var valid_21626662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626662 = validateParameter(valid_21626662, JString, required = false,
                                   default = nil)
  if valid_21626662 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626662
  var valid_21626663 = header.getOrDefault("X-Amz-Credential")
  valid_21626663 = validateParameter(valid_21626663, JString, required = false,
                                   default = nil)
  if valid_21626663 != nil:
    section.add "X-Amz-Credential", valid_21626663
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  section = newJObject()
  var valid_21626664 = formData.getOrDefault("NextToken")
  valid_21626664 = validateParameter(valid_21626664, JString, required = false,
                                   default = nil)
  if valid_21626664 != nil:
    section.add "NextToken", valid_21626664
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626665: Call_PostListSubscriptions_21626652;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_21626665.validator(path, query, header, formData, body, _)
  let scheme = call_21626665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626665.makeUrl(scheme.get, call_21626665.host, call_21626665.base,
                               call_21626665.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626665, uri, valid, _)

proc call*(call_21626666: Call_PostListSubscriptions_21626652;
          NextToken: string = ""; Action: string = "ListSubscriptions";
          Version: string = "2010-03-31"): Recallable =
  ## postListSubscriptions
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626667 = newJObject()
  var formData_21626668 = newJObject()
  add(formData_21626668, "NextToken", newJString(NextToken))
  add(query_21626667, "Action", newJString(Action))
  add(query_21626667, "Version", newJString(Version))
  result = call_21626666.call(nil, query_21626667, nil, formData_21626668, nil)

var postListSubscriptions* = Call_PostListSubscriptions_21626652(
    name: "postListSubscriptions", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptions",
    validator: validate_PostListSubscriptions_21626653, base: "/",
    makeUrl: url_PostListSubscriptions_21626654,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListSubscriptions_21626636 = ref object of OpenApiRestCall_21625435
proc url_GetListSubscriptions_21626638(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListSubscriptions_21626637(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626639 = query.getOrDefault("NextToken")
  valid_21626639 = validateParameter(valid_21626639, JString, required = false,
                                   default = nil)
  if valid_21626639 != nil:
    section.add "NextToken", valid_21626639
  var valid_21626640 = query.getOrDefault("Action")
  valid_21626640 = validateParameter(valid_21626640, JString, required = true,
                                   default = newJString("ListSubscriptions"))
  if valid_21626640 != nil:
    section.add "Action", valid_21626640
  var valid_21626641 = query.getOrDefault("Version")
  valid_21626641 = validateParameter(valid_21626641, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626641 != nil:
    section.add "Version", valid_21626641
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626642 = header.getOrDefault("X-Amz-Date")
  valid_21626642 = validateParameter(valid_21626642, JString, required = false,
                                   default = nil)
  if valid_21626642 != nil:
    section.add "X-Amz-Date", valid_21626642
  var valid_21626643 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626643 = validateParameter(valid_21626643, JString, required = false,
                                   default = nil)
  if valid_21626643 != nil:
    section.add "X-Amz-Security-Token", valid_21626643
  var valid_21626644 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626644 = validateParameter(valid_21626644, JString, required = false,
                                   default = nil)
  if valid_21626644 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626644
  var valid_21626645 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626645 = validateParameter(valid_21626645, JString, required = false,
                                   default = nil)
  if valid_21626645 != nil:
    section.add "X-Amz-Algorithm", valid_21626645
  var valid_21626646 = header.getOrDefault("X-Amz-Signature")
  valid_21626646 = validateParameter(valid_21626646, JString, required = false,
                                   default = nil)
  if valid_21626646 != nil:
    section.add "X-Amz-Signature", valid_21626646
  var valid_21626647 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626647 = validateParameter(valid_21626647, JString, required = false,
                                   default = nil)
  if valid_21626647 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626647
  var valid_21626648 = header.getOrDefault("X-Amz-Credential")
  valid_21626648 = validateParameter(valid_21626648, JString, required = false,
                                   default = nil)
  if valid_21626648 != nil:
    section.add "X-Amz-Credential", valid_21626648
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626649: Call_GetListSubscriptions_21626636; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_21626649.validator(path, query, header, formData, body, _)
  let scheme = call_21626649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626649.makeUrl(scheme.get, call_21626649.host, call_21626649.base,
                               call_21626649.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626649, uri, valid, _)

proc call*(call_21626650: Call_GetListSubscriptions_21626636;
          NextToken: string = ""; Action: string = "ListSubscriptions";
          Version: string = "2010-03-31"): Recallable =
  ## getListSubscriptions
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626651 = newJObject()
  add(query_21626651, "NextToken", newJString(NextToken))
  add(query_21626651, "Action", newJString(Action))
  add(query_21626651, "Version", newJString(Version))
  result = call_21626650.call(nil, query_21626651, nil, nil, nil)

var getListSubscriptions* = Call_GetListSubscriptions_21626636(
    name: "getListSubscriptions", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptions",
    validator: validate_GetListSubscriptions_21626637, base: "/",
    makeUrl: url_GetListSubscriptions_21626638,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListSubscriptionsByTopic_21626686 = ref object of OpenApiRestCall_21625435
proc url_PostListSubscriptionsByTopic_21626688(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListSubscriptionsByTopic_21626687(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626689 = query.getOrDefault("Action")
  valid_21626689 = validateParameter(valid_21626689, JString, required = true, default = newJString(
      "ListSubscriptionsByTopic"))
  if valid_21626689 != nil:
    section.add "Action", valid_21626689
  var valid_21626690 = query.getOrDefault("Version")
  valid_21626690 = validateParameter(valid_21626690, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626690 != nil:
    section.add "Version", valid_21626690
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626691 = header.getOrDefault("X-Amz-Date")
  valid_21626691 = validateParameter(valid_21626691, JString, required = false,
                                   default = nil)
  if valid_21626691 != nil:
    section.add "X-Amz-Date", valid_21626691
  var valid_21626692 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626692 = validateParameter(valid_21626692, JString, required = false,
                                   default = nil)
  if valid_21626692 != nil:
    section.add "X-Amz-Security-Token", valid_21626692
  var valid_21626693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626693 = validateParameter(valid_21626693, JString, required = false,
                                   default = nil)
  if valid_21626693 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626693
  var valid_21626694 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626694 = validateParameter(valid_21626694, JString, required = false,
                                   default = nil)
  if valid_21626694 != nil:
    section.add "X-Amz-Algorithm", valid_21626694
  var valid_21626695 = header.getOrDefault("X-Amz-Signature")
  valid_21626695 = validateParameter(valid_21626695, JString, required = false,
                                   default = nil)
  if valid_21626695 != nil:
    section.add "X-Amz-Signature", valid_21626695
  var valid_21626696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626696 = validateParameter(valid_21626696, JString, required = false,
                                   default = nil)
  if valid_21626696 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626696
  var valid_21626697 = header.getOrDefault("X-Amz-Credential")
  valid_21626697 = validateParameter(valid_21626697, JString, required = false,
                                   default = nil)
  if valid_21626697 != nil:
    section.add "X-Amz-Credential", valid_21626697
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListSubscriptionsByTopic</code> request.
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic for which you wish to find subscriptions.
  section = newJObject()
  var valid_21626698 = formData.getOrDefault("NextToken")
  valid_21626698 = validateParameter(valid_21626698, JString, required = false,
                                   default = nil)
  if valid_21626698 != nil:
    section.add "NextToken", valid_21626698
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_21626699 = formData.getOrDefault("TopicArn")
  valid_21626699 = validateParameter(valid_21626699, JString, required = true,
                                   default = nil)
  if valid_21626699 != nil:
    section.add "TopicArn", valid_21626699
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626700: Call_PostListSubscriptionsByTopic_21626686;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_21626700.validator(path, query, header, formData, body, _)
  let scheme = call_21626700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626700.makeUrl(scheme.get, call_21626700.host, call_21626700.base,
                               call_21626700.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626700, uri, valid, _)

proc call*(call_21626701: Call_PostListSubscriptionsByTopic_21626686;
          TopicArn: string; NextToken: string = "";
          Action: string = "ListSubscriptionsByTopic";
          Version: string = "2010-03-31"): Recallable =
  ## postListSubscriptionsByTopic
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptionsByTopic</code> request.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic for which you wish to find subscriptions.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626702 = newJObject()
  var formData_21626703 = newJObject()
  add(formData_21626703, "NextToken", newJString(NextToken))
  add(formData_21626703, "TopicArn", newJString(TopicArn))
  add(query_21626702, "Action", newJString(Action))
  add(query_21626702, "Version", newJString(Version))
  result = call_21626701.call(nil, query_21626702, nil, formData_21626703, nil)

var postListSubscriptionsByTopic* = Call_PostListSubscriptionsByTopic_21626686(
    name: "postListSubscriptionsByTopic", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptionsByTopic",
    validator: validate_PostListSubscriptionsByTopic_21626687, base: "/",
    makeUrl: url_PostListSubscriptionsByTopic_21626688,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListSubscriptionsByTopic_21626669 = ref object of OpenApiRestCall_21625435
proc url_GetListSubscriptionsByTopic_21626671(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListSubscriptionsByTopic_21626670(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626672 = query.getOrDefault("NextToken")
  valid_21626672 = validateParameter(valid_21626672, JString, required = false,
                                   default = nil)
  if valid_21626672 != nil:
    section.add "NextToken", valid_21626672
  var valid_21626673 = query.getOrDefault("Action")
  valid_21626673 = validateParameter(valid_21626673, JString, required = true, default = newJString(
      "ListSubscriptionsByTopic"))
  if valid_21626673 != nil:
    section.add "Action", valid_21626673
  var valid_21626674 = query.getOrDefault("TopicArn")
  valid_21626674 = validateParameter(valid_21626674, JString, required = true,
                                   default = nil)
  if valid_21626674 != nil:
    section.add "TopicArn", valid_21626674
  var valid_21626675 = query.getOrDefault("Version")
  valid_21626675 = validateParameter(valid_21626675, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626675 != nil:
    section.add "Version", valid_21626675
  result.add "query", section
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

proc call*(call_21626683: Call_GetListSubscriptionsByTopic_21626669;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_21626683.validator(path, query, header, formData, body, _)
  let scheme = call_21626683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626683.makeUrl(scheme.get, call_21626683.host, call_21626683.base,
                               call_21626683.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626683, uri, valid, _)

proc call*(call_21626684: Call_GetListSubscriptionsByTopic_21626669;
          TopicArn: string; NextToken: string = "";
          Action: string = "ListSubscriptionsByTopic";
          Version: string = "2010-03-31"): Recallable =
  ## getListSubscriptionsByTopic
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptionsByTopic</code> request.
  ##   Action: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic for which you wish to find subscriptions.
  ##   Version: string (required)
  var query_21626685 = newJObject()
  add(query_21626685, "NextToken", newJString(NextToken))
  add(query_21626685, "Action", newJString(Action))
  add(query_21626685, "TopicArn", newJString(TopicArn))
  add(query_21626685, "Version", newJString(Version))
  result = call_21626684.call(nil, query_21626685, nil, nil, nil)

var getListSubscriptionsByTopic* = Call_GetListSubscriptionsByTopic_21626669(
    name: "getListSubscriptionsByTopic", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptionsByTopic",
    validator: validate_GetListSubscriptionsByTopic_21626670, base: "/",
    makeUrl: url_GetListSubscriptionsByTopic_21626671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_21626720 = ref object of OpenApiRestCall_21625435
proc url_PostListTagsForResource_21626722(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListTagsForResource_21626721(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626723 = query.getOrDefault("Action")
  valid_21626723 = validateParameter(valid_21626723, JString, required = true,
                                   default = newJString("ListTagsForResource"))
  if valid_21626723 != nil:
    section.add "Action", valid_21626723
  var valid_21626724 = query.getOrDefault("Version")
  valid_21626724 = validateParameter(valid_21626724, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626724 != nil:
    section.add "Version", valid_21626724
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626725 = header.getOrDefault("X-Amz-Date")
  valid_21626725 = validateParameter(valid_21626725, JString, required = false,
                                   default = nil)
  if valid_21626725 != nil:
    section.add "X-Amz-Date", valid_21626725
  var valid_21626726 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626726 = validateParameter(valid_21626726, JString, required = false,
                                   default = nil)
  if valid_21626726 != nil:
    section.add "X-Amz-Security-Token", valid_21626726
  var valid_21626727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626727 = validateParameter(valid_21626727, JString, required = false,
                                   default = nil)
  if valid_21626727 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626727
  var valid_21626728 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626728 = validateParameter(valid_21626728, JString, required = false,
                                   default = nil)
  if valid_21626728 != nil:
    section.add "X-Amz-Algorithm", valid_21626728
  var valid_21626729 = header.getOrDefault("X-Amz-Signature")
  valid_21626729 = validateParameter(valid_21626729, JString, required = false,
                                   default = nil)
  if valid_21626729 != nil:
    section.add "X-Amz-Signature", valid_21626729
  var valid_21626730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626730 = validateParameter(valid_21626730, JString, required = false,
                                   default = nil)
  if valid_21626730 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626730
  var valid_21626731 = header.getOrDefault("X-Amz-Credential")
  valid_21626731 = validateParameter(valid_21626731, JString, required = false,
                                   default = nil)
  if valid_21626731 != nil:
    section.add "X-Amz-Credential", valid_21626731
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic for which to list tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_21626732 = formData.getOrDefault("ResourceArn")
  valid_21626732 = validateParameter(valid_21626732, JString, required = true,
                                   default = nil)
  if valid_21626732 != nil:
    section.add "ResourceArn", valid_21626732
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626733: Call_PostListTagsForResource_21626720;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ## 
  let valid = call_21626733.validator(path, query, header, formData, body, _)
  let scheme = call_21626733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626733.makeUrl(scheme.get, call_21626733.host, call_21626733.base,
                               call_21626733.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626733, uri, valid, _)

proc call*(call_21626734: Call_PostListTagsForResource_21626720;
          ResourceArn: string; Action: string = "ListTagsForResource";
          Version: string = "2010-03-31"): Recallable =
  ## postListTagsForResource
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ##   Action: string (required)
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic for which to list tags.
  ##   Version: string (required)
  var query_21626735 = newJObject()
  var formData_21626736 = newJObject()
  add(query_21626735, "Action", newJString(Action))
  add(formData_21626736, "ResourceArn", newJString(ResourceArn))
  add(query_21626735, "Version", newJString(Version))
  result = call_21626734.call(nil, query_21626735, nil, formData_21626736, nil)

var postListTagsForResource* = Call_PostListTagsForResource_21626720(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_21626721, base: "/",
    makeUrl: url_PostListTagsForResource_21626722,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_21626704 = ref object of OpenApiRestCall_21625435
proc url_GetListTagsForResource_21626706(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListTagsForResource_21626705(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626707 = query.getOrDefault("ResourceArn")
  valid_21626707 = validateParameter(valid_21626707, JString, required = true,
                                   default = nil)
  if valid_21626707 != nil:
    section.add "ResourceArn", valid_21626707
  var valid_21626708 = query.getOrDefault("Action")
  valid_21626708 = validateParameter(valid_21626708, JString, required = true,
                                   default = newJString("ListTagsForResource"))
  if valid_21626708 != nil:
    section.add "Action", valid_21626708
  var valid_21626709 = query.getOrDefault("Version")
  valid_21626709 = validateParameter(valid_21626709, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626709 != nil:
    section.add "Version", valid_21626709
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626710 = header.getOrDefault("X-Amz-Date")
  valid_21626710 = validateParameter(valid_21626710, JString, required = false,
                                   default = nil)
  if valid_21626710 != nil:
    section.add "X-Amz-Date", valid_21626710
  var valid_21626711 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626711 = validateParameter(valid_21626711, JString, required = false,
                                   default = nil)
  if valid_21626711 != nil:
    section.add "X-Amz-Security-Token", valid_21626711
  var valid_21626712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626712 = validateParameter(valid_21626712, JString, required = false,
                                   default = nil)
  if valid_21626712 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626712
  var valid_21626713 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626713 = validateParameter(valid_21626713, JString, required = false,
                                   default = nil)
  if valid_21626713 != nil:
    section.add "X-Amz-Algorithm", valid_21626713
  var valid_21626714 = header.getOrDefault("X-Amz-Signature")
  valid_21626714 = validateParameter(valid_21626714, JString, required = false,
                                   default = nil)
  if valid_21626714 != nil:
    section.add "X-Amz-Signature", valid_21626714
  var valid_21626715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626715 = validateParameter(valid_21626715, JString, required = false,
                                   default = nil)
  if valid_21626715 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626715
  var valid_21626716 = header.getOrDefault("X-Amz-Credential")
  valid_21626716 = validateParameter(valid_21626716, JString, required = false,
                                   default = nil)
  if valid_21626716 != nil:
    section.add "X-Amz-Credential", valid_21626716
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626717: Call_GetListTagsForResource_21626704;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ## 
  let valid = call_21626717.validator(path, query, header, formData, body, _)
  let scheme = call_21626717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626717.makeUrl(scheme.get, call_21626717.host, call_21626717.base,
                               call_21626717.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626717, uri, valid, _)

proc call*(call_21626718: Call_GetListTagsForResource_21626704;
          ResourceArn: string; Action: string = "ListTagsForResource";
          Version: string = "2010-03-31"): Recallable =
  ## getListTagsForResource
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic for which to list tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626719 = newJObject()
  add(query_21626719, "ResourceArn", newJString(ResourceArn))
  add(query_21626719, "Action", newJString(Action))
  add(query_21626719, "Version", newJString(Version))
  result = call_21626718.call(nil, query_21626719, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_21626704(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_21626705, base: "/",
    makeUrl: url_GetListTagsForResource_21626706,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTopics_21626753 = ref object of OpenApiRestCall_21625435
proc url_PostListTopics_21626755(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListTopics_21626754(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626756 = query.getOrDefault("Action")
  valid_21626756 = validateParameter(valid_21626756, JString, required = true,
                                   default = newJString("ListTopics"))
  if valid_21626756 != nil:
    section.add "Action", valid_21626756
  var valid_21626757 = query.getOrDefault("Version")
  valid_21626757 = validateParameter(valid_21626757, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626757 != nil:
    section.add "Version", valid_21626757
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626758 = header.getOrDefault("X-Amz-Date")
  valid_21626758 = validateParameter(valid_21626758, JString, required = false,
                                   default = nil)
  if valid_21626758 != nil:
    section.add "X-Amz-Date", valid_21626758
  var valid_21626759 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626759 = validateParameter(valid_21626759, JString, required = false,
                                   default = nil)
  if valid_21626759 != nil:
    section.add "X-Amz-Security-Token", valid_21626759
  var valid_21626760 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626760 = validateParameter(valid_21626760, JString, required = false,
                                   default = nil)
  if valid_21626760 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626760
  var valid_21626761 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626761 = validateParameter(valid_21626761, JString, required = false,
                                   default = nil)
  if valid_21626761 != nil:
    section.add "X-Amz-Algorithm", valid_21626761
  var valid_21626762 = header.getOrDefault("X-Amz-Signature")
  valid_21626762 = validateParameter(valid_21626762, JString, required = false,
                                   default = nil)
  if valid_21626762 != nil:
    section.add "X-Amz-Signature", valid_21626762
  var valid_21626763 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626763 = validateParameter(valid_21626763, JString, required = false,
                                   default = nil)
  if valid_21626763 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626763
  var valid_21626764 = header.getOrDefault("X-Amz-Credential")
  valid_21626764 = validateParameter(valid_21626764, JString, required = false,
                                   default = nil)
  if valid_21626764 != nil:
    section.add "X-Amz-Credential", valid_21626764
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListTopics</code> request.
  section = newJObject()
  var valid_21626765 = formData.getOrDefault("NextToken")
  valid_21626765 = validateParameter(valid_21626765, JString, required = false,
                                   default = nil)
  if valid_21626765 != nil:
    section.add "NextToken", valid_21626765
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626766: Call_PostListTopics_21626753; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_21626766.validator(path, query, header, formData, body, _)
  let scheme = call_21626766.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626766.makeUrl(scheme.get, call_21626766.host, call_21626766.base,
                               call_21626766.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626766, uri, valid, _)

proc call*(call_21626767: Call_PostListTopics_21626753; NextToken: string = "";
          Action: string = "ListTopics"; Version: string = "2010-03-31"): Recallable =
  ## postListTopics
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListTopics</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626768 = newJObject()
  var formData_21626769 = newJObject()
  add(formData_21626769, "NextToken", newJString(NextToken))
  add(query_21626768, "Action", newJString(Action))
  add(query_21626768, "Version", newJString(Version))
  result = call_21626767.call(nil, query_21626768, nil, formData_21626769, nil)

var postListTopics* = Call_PostListTopics_21626753(name: "postListTopics",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=ListTopics", validator: validate_PostListTopics_21626754,
    base: "/", makeUrl: url_PostListTopics_21626755,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTopics_21626737 = ref object of OpenApiRestCall_21625435
proc url_GetListTopics_21626739(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListTopics_21626738(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626740 = query.getOrDefault("NextToken")
  valid_21626740 = validateParameter(valid_21626740, JString, required = false,
                                   default = nil)
  if valid_21626740 != nil:
    section.add "NextToken", valid_21626740
  var valid_21626741 = query.getOrDefault("Action")
  valid_21626741 = validateParameter(valid_21626741, JString, required = true,
                                   default = newJString("ListTopics"))
  if valid_21626741 != nil:
    section.add "Action", valid_21626741
  var valid_21626742 = query.getOrDefault("Version")
  valid_21626742 = validateParameter(valid_21626742, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626742 != nil:
    section.add "Version", valid_21626742
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626743 = header.getOrDefault("X-Amz-Date")
  valid_21626743 = validateParameter(valid_21626743, JString, required = false,
                                   default = nil)
  if valid_21626743 != nil:
    section.add "X-Amz-Date", valid_21626743
  var valid_21626744 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626744 = validateParameter(valid_21626744, JString, required = false,
                                   default = nil)
  if valid_21626744 != nil:
    section.add "X-Amz-Security-Token", valid_21626744
  var valid_21626745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626745 = validateParameter(valid_21626745, JString, required = false,
                                   default = nil)
  if valid_21626745 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626745
  var valid_21626746 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626746 = validateParameter(valid_21626746, JString, required = false,
                                   default = nil)
  if valid_21626746 != nil:
    section.add "X-Amz-Algorithm", valid_21626746
  var valid_21626747 = header.getOrDefault("X-Amz-Signature")
  valid_21626747 = validateParameter(valid_21626747, JString, required = false,
                                   default = nil)
  if valid_21626747 != nil:
    section.add "X-Amz-Signature", valid_21626747
  var valid_21626748 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626748 = validateParameter(valid_21626748, JString, required = false,
                                   default = nil)
  if valid_21626748 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626748
  var valid_21626749 = header.getOrDefault("X-Amz-Credential")
  valid_21626749 = validateParameter(valid_21626749, JString, required = false,
                                   default = nil)
  if valid_21626749 != nil:
    section.add "X-Amz-Credential", valid_21626749
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626750: Call_GetListTopics_21626737; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_21626750.validator(path, query, header, formData, body, _)
  let scheme = call_21626750.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626750.makeUrl(scheme.get, call_21626750.host, call_21626750.base,
                               call_21626750.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626750, uri, valid, _)

proc call*(call_21626751: Call_GetListTopics_21626737; NextToken: string = "";
          Action: string = "ListTopics"; Version: string = "2010-03-31"): Recallable =
  ## getListTopics
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListTopics</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626752 = newJObject()
  add(query_21626752, "NextToken", newJString(NextToken))
  add(query_21626752, "Action", newJString(Action))
  add(query_21626752, "Version", newJString(Version))
  result = call_21626751.call(nil, query_21626752, nil, nil, nil)

var getListTopics* = Call_GetListTopics_21626737(name: "getListTopics",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=ListTopics", validator: validate_GetListTopics_21626738,
    base: "/", makeUrl: url_GetListTopics_21626739,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostOptInPhoneNumber_21626786 = ref object of OpenApiRestCall_21625435
proc url_PostOptInPhoneNumber_21626788(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostOptInPhoneNumber_21626787(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626789 = query.getOrDefault("Action")
  valid_21626789 = validateParameter(valid_21626789, JString, required = true,
                                   default = newJString("OptInPhoneNumber"))
  if valid_21626789 != nil:
    section.add "Action", valid_21626789
  var valid_21626790 = query.getOrDefault("Version")
  valid_21626790 = validateParameter(valid_21626790, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626790 != nil:
    section.add "Version", valid_21626790
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626791 = header.getOrDefault("X-Amz-Date")
  valid_21626791 = validateParameter(valid_21626791, JString, required = false,
                                   default = nil)
  if valid_21626791 != nil:
    section.add "X-Amz-Date", valid_21626791
  var valid_21626792 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626792 = validateParameter(valid_21626792, JString, required = false,
                                   default = nil)
  if valid_21626792 != nil:
    section.add "X-Amz-Security-Token", valid_21626792
  var valid_21626793 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626793 = validateParameter(valid_21626793, JString, required = false,
                                   default = nil)
  if valid_21626793 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626793
  var valid_21626794 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626794 = validateParameter(valid_21626794, JString, required = false,
                                   default = nil)
  if valid_21626794 != nil:
    section.add "X-Amz-Algorithm", valid_21626794
  var valid_21626795 = header.getOrDefault("X-Amz-Signature")
  valid_21626795 = validateParameter(valid_21626795, JString, required = false,
                                   default = nil)
  if valid_21626795 != nil:
    section.add "X-Amz-Signature", valid_21626795
  var valid_21626796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626796 = validateParameter(valid_21626796, JString, required = false,
                                   default = nil)
  if valid_21626796 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626796
  var valid_21626797 = header.getOrDefault("X-Amz-Credential")
  valid_21626797 = validateParameter(valid_21626797, JString, required = false,
                                   default = nil)
  if valid_21626797 != nil:
    section.add "X-Amz-Credential", valid_21626797
  result.add "header", section
  ## parameters in `formData` object:
  ##   phoneNumber: JString (required)
  ##              : The phone number to opt in.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `phoneNumber` field"
  var valid_21626798 = formData.getOrDefault("phoneNumber")
  valid_21626798 = validateParameter(valid_21626798, JString, required = true,
                                   default = nil)
  if valid_21626798 != nil:
    section.add "phoneNumber", valid_21626798
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626799: Call_PostOptInPhoneNumber_21626786; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ## 
  let valid = call_21626799.validator(path, query, header, formData, body, _)
  let scheme = call_21626799.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626799.makeUrl(scheme.get, call_21626799.host, call_21626799.base,
                               call_21626799.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626799, uri, valid, _)

proc call*(call_21626800: Call_PostOptInPhoneNumber_21626786; phoneNumber: string;
          Action: string = "OptInPhoneNumber"; Version: string = "2010-03-31"): Recallable =
  ## postOptInPhoneNumber
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ##   Action: string (required)
  ##   phoneNumber: string (required)
  ##              : The phone number to opt in.
  ##   Version: string (required)
  var query_21626801 = newJObject()
  var formData_21626802 = newJObject()
  add(query_21626801, "Action", newJString(Action))
  add(formData_21626802, "phoneNumber", newJString(phoneNumber))
  add(query_21626801, "Version", newJString(Version))
  result = call_21626800.call(nil, query_21626801, nil, formData_21626802, nil)

var postOptInPhoneNumber* = Call_PostOptInPhoneNumber_21626786(
    name: "postOptInPhoneNumber", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=OptInPhoneNumber",
    validator: validate_PostOptInPhoneNumber_21626787, base: "/",
    makeUrl: url_PostOptInPhoneNumber_21626788,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOptInPhoneNumber_21626770 = ref object of OpenApiRestCall_21625435
proc url_GetOptInPhoneNumber_21626772(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetOptInPhoneNumber_21626771(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626773 = query.getOrDefault("phoneNumber")
  valid_21626773 = validateParameter(valid_21626773, JString, required = true,
                                   default = nil)
  if valid_21626773 != nil:
    section.add "phoneNumber", valid_21626773
  var valid_21626774 = query.getOrDefault("Action")
  valid_21626774 = validateParameter(valid_21626774, JString, required = true,
                                   default = newJString("OptInPhoneNumber"))
  if valid_21626774 != nil:
    section.add "Action", valid_21626774
  var valid_21626775 = query.getOrDefault("Version")
  valid_21626775 = validateParameter(valid_21626775, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626775 != nil:
    section.add "Version", valid_21626775
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626776 = header.getOrDefault("X-Amz-Date")
  valid_21626776 = validateParameter(valid_21626776, JString, required = false,
                                   default = nil)
  if valid_21626776 != nil:
    section.add "X-Amz-Date", valid_21626776
  var valid_21626777 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626777 = validateParameter(valid_21626777, JString, required = false,
                                   default = nil)
  if valid_21626777 != nil:
    section.add "X-Amz-Security-Token", valid_21626777
  var valid_21626778 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626778 = validateParameter(valid_21626778, JString, required = false,
                                   default = nil)
  if valid_21626778 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626778
  var valid_21626779 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626779 = validateParameter(valid_21626779, JString, required = false,
                                   default = nil)
  if valid_21626779 != nil:
    section.add "X-Amz-Algorithm", valid_21626779
  var valid_21626780 = header.getOrDefault("X-Amz-Signature")
  valid_21626780 = validateParameter(valid_21626780, JString, required = false,
                                   default = nil)
  if valid_21626780 != nil:
    section.add "X-Amz-Signature", valid_21626780
  var valid_21626781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626781 = validateParameter(valid_21626781, JString, required = false,
                                   default = nil)
  if valid_21626781 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626781
  var valid_21626782 = header.getOrDefault("X-Amz-Credential")
  valid_21626782 = validateParameter(valid_21626782, JString, required = false,
                                   default = nil)
  if valid_21626782 != nil:
    section.add "X-Amz-Credential", valid_21626782
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626783: Call_GetOptInPhoneNumber_21626770; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ## 
  let valid = call_21626783.validator(path, query, header, formData, body, _)
  let scheme = call_21626783.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626783.makeUrl(scheme.get, call_21626783.host, call_21626783.base,
                               call_21626783.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626783, uri, valid, _)

proc call*(call_21626784: Call_GetOptInPhoneNumber_21626770; phoneNumber: string;
          Action: string = "OptInPhoneNumber"; Version: string = "2010-03-31"): Recallable =
  ## getOptInPhoneNumber
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number to opt in.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626785 = newJObject()
  add(query_21626785, "phoneNumber", newJString(phoneNumber))
  add(query_21626785, "Action", newJString(Action))
  add(query_21626785, "Version", newJString(Version))
  result = call_21626784.call(nil, query_21626785, nil, nil, nil)

var getOptInPhoneNumber* = Call_GetOptInPhoneNumber_21626770(
    name: "getOptInPhoneNumber", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=OptInPhoneNumber",
    validator: validate_GetOptInPhoneNumber_21626771, base: "/",
    makeUrl: url_GetOptInPhoneNumber_21626772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPublish_21626830 = ref object of OpenApiRestCall_21625435
proc url_PostPublish_21626832(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPublish_21626831(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626833 = query.getOrDefault("Action")
  valid_21626833 = validateParameter(valid_21626833, JString, required = true,
                                   default = newJString("Publish"))
  if valid_21626833 != nil:
    section.add "Action", valid_21626833
  var valid_21626834 = query.getOrDefault("Version")
  valid_21626834 = validateParameter(valid_21626834, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626834 != nil:
    section.add "Version", valid_21626834
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626835 = header.getOrDefault("X-Amz-Date")
  valid_21626835 = validateParameter(valid_21626835, JString, required = false,
                                   default = nil)
  if valid_21626835 != nil:
    section.add "X-Amz-Date", valid_21626835
  var valid_21626836 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626836 = validateParameter(valid_21626836, JString, required = false,
                                   default = nil)
  if valid_21626836 != nil:
    section.add "X-Amz-Security-Token", valid_21626836
  var valid_21626837 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626837 = validateParameter(valid_21626837, JString, required = false,
                                   default = nil)
  if valid_21626837 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626837
  var valid_21626838 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626838 = validateParameter(valid_21626838, JString, required = false,
                                   default = nil)
  if valid_21626838 != nil:
    section.add "X-Amz-Algorithm", valid_21626838
  var valid_21626839 = header.getOrDefault("X-Amz-Signature")
  valid_21626839 = validateParameter(valid_21626839, JString, required = false,
                                   default = nil)
  if valid_21626839 != nil:
    section.add "X-Amz-Signature", valid_21626839
  var valid_21626840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626840 = validateParameter(valid_21626840, JString, required = false,
                                   default = nil)
  if valid_21626840 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626840
  var valid_21626841 = header.getOrDefault("X-Amz-Credential")
  valid_21626841 = validateParameter(valid_21626841, JString, required = false,
                                   default = nil)
  if valid_21626841 != nil:
    section.add "X-Amz-Credential", valid_21626841
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
  ##          : <p>The message you want to send.</p> <p>If you are publishing to a topic and you want to send the same message to all transport protocols, include the text of the message as a String value. If you want to send different messages for each transport protocol, set the value of the <code>MessageStructure</code> parameter to <code>json</code> and use a JSON object for the <code>Message</code> parameter. </p> <p/> <p>Constraints:</p> <ul> <li> <p>With the exception of SMS, messages must be UTF-8 encoded strings and at most 256 KB in size (262,144 bytes, not 262,144 characters).</p> </li> <li> <p>For SMS, each message can contain up to 140 characters. This character limit depends on the encoding schema. For example, an SMS message can contain 160 GSM characters, 140 ASCII characters, or 70 UCS-2 characters.</p> <p>If you publish a message that exceeds this size limit, Amazon SNS sends the message as multiple messages, each fitting within the size limit. Messages aren't truncated mid-word but are cut off at whole-word boundaries.</p> <p>The total size limit for a single SMS <code>Publish</code> action is 1,600 characters.</p> </li> </ul> <p>JSON-specific constraints:</p> <ul> <li> <p>Keys in the JSON object that correspond to supported transport protocols must have simple JSON string values.</p> </li> <li> <p>The values will be parsed (unescaped) before they are used in outgoing messages.</p> </li> <li> <p>Outbound notifications are JSON encoded (meaning that the characters will be reescaped for sending).</p> </li> <li> <p>Values have a minimum length of 0 (the empty string, "", is allowed).</p> </li> <li> <p>Values have a maximum length bounded by the overall message size (so, including multiple protocols may limit message sizes).</p> </li> <li> <p>Non-string values will cause the key to be ignored.</p> </li> <li> <p>Keys that do not correspond to supported transport protocols are ignored.</p> </li> <li> <p>Duplicate keys are not allowed.</p> </li> <li> <p>Failure to parse or validate any key or value in the message will cause the <code>Publish</code> call to return an error (no partial delivery).</p> </li> </ul>
  ##   MessageStructure: JString
  ##                   : <p>Set <code>MessageStructure</code> to <code>json</code> if you want to send a different message for each protocol. For example, using one publish action, you can send a short message to your SMS subscribers and a longer message to your email subscribers. If you set <code>MessageStructure</code> to <code>json</code>, the value of the <code>Message</code> parameter must: </p> <ul> <li> <p>be a syntactically valid JSON object; and</p> </li> <li> <p>contain at least a top-level JSON key of "default" with a value that is a string.</p> </li> </ul> <p>You can define other top-level keys that define the message you want to send to a specific transport protocol (e.g., "http").</p> <p>Valid value: <code>json</code> </p>
  ##   MessageAttributes.2.key: JString
  ##   MessageAttributes.2.value: JString
  section = newJObject()
  var valid_21626842 = formData.getOrDefault("TopicArn")
  valid_21626842 = validateParameter(valid_21626842, JString, required = false,
                                   default = nil)
  if valid_21626842 != nil:
    section.add "TopicArn", valid_21626842
  var valid_21626843 = formData.getOrDefault("Subject")
  valid_21626843 = validateParameter(valid_21626843, JString, required = false,
                                   default = nil)
  if valid_21626843 != nil:
    section.add "Subject", valid_21626843
  var valid_21626844 = formData.getOrDefault("MessageAttributes.1.key")
  valid_21626844 = validateParameter(valid_21626844, JString, required = false,
                                   default = nil)
  if valid_21626844 != nil:
    section.add "MessageAttributes.1.key", valid_21626844
  var valid_21626845 = formData.getOrDefault("TargetArn")
  valid_21626845 = validateParameter(valid_21626845, JString, required = false,
                                   default = nil)
  if valid_21626845 != nil:
    section.add "TargetArn", valid_21626845
  var valid_21626846 = formData.getOrDefault("PhoneNumber")
  valid_21626846 = validateParameter(valid_21626846, JString, required = false,
                                   default = nil)
  if valid_21626846 != nil:
    section.add "PhoneNumber", valid_21626846
  var valid_21626847 = formData.getOrDefault("MessageAttributes.0.value")
  valid_21626847 = validateParameter(valid_21626847, JString, required = false,
                                   default = nil)
  if valid_21626847 != nil:
    section.add "MessageAttributes.0.value", valid_21626847
  var valid_21626848 = formData.getOrDefault("MessageAttributes.1.value")
  valid_21626848 = validateParameter(valid_21626848, JString, required = false,
                                   default = nil)
  if valid_21626848 != nil:
    section.add "MessageAttributes.1.value", valid_21626848
  var valid_21626849 = formData.getOrDefault("MessageAttributes.0.key")
  valid_21626849 = validateParameter(valid_21626849, JString, required = false,
                                   default = nil)
  if valid_21626849 != nil:
    section.add "MessageAttributes.0.key", valid_21626849
  assert formData != nil,
        "formData argument is necessary due to required `Message` field"
  var valid_21626850 = formData.getOrDefault("Message")
  valid_21626850 = validateParameter(valid_21626850, JString, required = true,
                                   default = nil)
  if valid_21626850 != nil:
    section.add "Message", valid_21626850
  var valid_21626851 = formData.getOrDefault("MessageStructure")
  valid_21626851 = validateParameter(valid_21626851, JString, required = false,
                                   default = nil)
  if valid_21626851 != nil:
    section.add "MessageStructure", valid_21626851
  var valid_21626852 = formData.getOrDefault("MessageAttributes.2.key")
  valid_21626852 = validateParameter(valid_21626852, JString, required = false,
                                   default = nil)
  if valid_21626852 != nil:
    section.add "MessageAttributes.2.key", valid_21626852
  var valid_21626853 = formData.getOrDefault("MessageAttributes.2.value")
  valid_21626853 = validateParameter(valid_21626853, JString, required = false,
                                   default = nil)
  if valid_21626853 != nil:
    section.add "MessageAttributes.2.value", valid_21626853
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626854: Call_PostPublish_21626830; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  let valid = call_21626854.validator(path, query, header, formData, body, _)
  let scheme = call_21626854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626854.makeUrl(scheme.get, call_21626854.host, call_21626854.base,
                               call_21626854.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626854, uri, valid, _)

proc call*(call_21626855: Call_PostPublish_21626830; Message: string;
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
  ##          : <p>The message you want to send.</p> <p>If you are publishing to a topic and you want to send the same message to all transport protocols, include the text of the message as a String value. If you want to send different messages for each transport protocol, set the value of the <code>MessageStructure</code> parameter to <code>json</code> and use a JSON object for the <code>Message</code> parameter. </p> <p/> <p>Constraints:</p> <ul> <li> <p>With the exception of SMS, messages must be UTF-8 encoded strings and at most 256 KB in size (262,144 bytes, not 262,144 characters).</p> </li> <li> <p>For SMS, each message can contain up to 140 characters. This character limit depends on the encoding schema. For example, an SMS message can contain 160 GSM characters, 140 ASCII characters, or 70 UCS-2 characters.</p> <p>If you publish a message that exceeds this size limit, Amazon SNS sends the message as multiple messages, each fitting within the size limit. Messages aren't truncated mid-word but are cut off at whole-word boundaries.</p> <p>The total size limit for a single SMS <code>Publish</code> action is 1,600 characters.</p> </li> </ul> <p>JSON-specific constraints:</p> <ul> <li> <p>Keys in the JSON object that correspond to supported transport protocols must have simple JSON string values.</p> </li> <li> <p>The values will be parsed (unescaped) before they are used in outgoing messages.</p> </li> <li> <p>Outbound notifications are JSON encoded (meaning that the characters will be reescaped for sending).</p> </li> <li> <p>Values have a minimum length of 0 (the empty string, "", is allowed).</p> </li> <li> <p>Values have a maximum length bounded by the overall message size (so, including multiple protocols may limit message sizes).</p> </li> <li> <p>Non-string values will cause the key to be ignored.</p> </li> <li> <p>Keys that do not correspond to supported transport protocols are ignored.</p> </li> <li> <p>Duplicate keys are not allowed.</p> </li> <li> <p>Failure to parse or validate any key or value in the message will cause the <code>Publish</code> call to return an error (no partial delivery).</p> </li> </ul>
  ##   Action: string (required)
  ##   MessageStructure: string
  ##                   : <p>Set <code>MessageStructure</code> to <code>json</code> if you want to send a different message for each protocol. For example, using one publish action, you can send a short message to your SMS subscribers and a longer message to your email subscribers. If you set <code>MessageStructure</code> to <code>json</code>, the value of the <code>Message</code> parameter must: </p> <ul> <li> <p>be a syntactically valid JSON object; and</p> </li> <li> <p>contain at least a top-level JSON key of "default" with a value that is a string.</p> </li> </ul> <p>You can define other top-level keys that define the message you want to send to a specific transport protocol (e.g., "http").</p> <p>Valid value: <code>json</code> </p>
  ##   MessageAttributes2Key: string
  ##   Version: string (required)
  ##   MessageAttributes2Value: string
  var query_21626856 = newJObject()
  var formData_21626857 = newJObject()
  add(formData_21626857, "TopicArn", newJString(TopicArn))
  add(formData_21626857, "Subject", newJString(Subject))
  add(formData_21626857, "MessageAttributes.1.key",
      newJString(MessageAttributes1Key))
  add(formData_21626857, "TargetArn", newJString(TargetArn))
  add(formData_21626857, "PhoneNumber", newJString(PhoneNumber))
  add(formData_21626857, "MessageAttributes.0.value",
      newJString(MessageAttributes0Value))
  add(formData_21626857, "MessageAttributes.1.value",
      newJString(MessageAttributes1Value))
  add(formData_21626857, "MessageAttributes.0.key",
      newJString(MessageAttributes0Key))
  add(formData_21626857, "Message", newJString(Message))
  add(query_21626856, "Action", newJString(Action))
  add(formData_21626857, "MessageStructure", newJString(MessageStructure))
  add(formData_21626857, "MessageAttributes.2.key",
      newJString(MessageAttributes2Key))
  add(query_21626856, "Version", newJString(Version))
  add(formData_21626857, "MessageAttributes.2.value",
      newJString(MessageAttributes2Value))
  result = call_21626855.call(nil, query_21626856, nil, formData_21626857, nil)

var postPublish* = Call_PostPublish_21626830(name: "postPublish",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com", route: "/#Action=Publish",
    validator: validate_PostPublish_21626831, base: "/", makeUrl: url_PostPublish_21626832,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublish_21626803 = ref object of OpenApiRestCall_21625435
proc url_GetPublish_21626805(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPublish_21626804(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##          : <p>The message you want to send.</p> <p>If you are publishing to a topic and you want to send the same message to all transport protocols, include the text of the message as a String value. If you want to send different messages for each transport protocol, set the value of the <code>MessageStructure</code> parameter to <code>json</code> and use a JSON object for the <code>Message</code> parameter. </p> <p/> <p>Constraints:</p> <ul> <li> <p>With the exception of SMS, messages must be UTF-8 encoded strings and at most 256 KB in size (262,144 bytes, not 262,144 characters).</p> </li> <li> <p>For SMS, each message can contain up to 140 characters. This character limit depends on the encoding schema. For example, an SMS message can contain 160 GSM characters, 140 ASCII characters, or 70 UCS-2 characters.</p> <p>If you publish a message that exceeds this size limit, Amazon SNS sends the message as multiple messages, each fitting within the size limit. Messages aren't truncated mid-word but are cut off at whole-word boundaries.</p> <p>The total size limit for a single SMS <code>Publish</code> action is 1,600 characters.</p> </li> </ul> <p>JSON-specific constraints:</p> <ul> <li> <p>Keys in the JSON object that correspond to supported transport protocols must have simple JSON string values.</p> </li> <li> <p>The values will be parsed (unescaped) before they are used in outgoing messages.</p> </li> <li> <p>Outbound notifications are JSON encoded (meaning that the characters will be reescaped for sending).</p> </li> <li> <p>Values have a minimum length of 0 (the empty string, "", is allowed).</p> </li> <li> <p>Values have a maximum length bounded by the overall message size (so, including multiple protocols may limit message sizes).</p> </li> <li> <p>Non-string values will cause the key to be ignored.</p> </li> <li> <p>Keys that do not correspond to supported transport protocols are ignored.</p> </li> <li> <p>Duplicate keys are not allowed.</p> </li> <li> <p>Failure to parse or validate any key or value in the message will cause the <code>Publish</code> call to return an error (no partial delivery).</p> </li> </ul>
  ##   Subject: JString
  ##          : <p>Optional parameter to be used as the "Subject" line when the message is delivered to email endpoints. This field will also be included, if present, in the standard JSON messages delivered to other endpoints.</p> <p>Constraints: Subjects must be ASCII text that begins with a letter, number, or punctuation mark; must not include line breaks or control characters; and must be less than 100 characters long.</p>
  ##   Action: JString (required)
  ##   MessageAttributes.2.value: JString
  ##   MessageStructure: JString
  ##                   : <p>Set <code>MessageStructure</code> to <code>json</code> if you want to send a different message for each protocol. For example, using one publish action, you can send a short message to your SMS subscribers and a longer message to your email subscribers. If you set <code>MessageStructure</code> to <code>json</code>, the value of the <code>Message</code> parameter must: </p> <ul> <li> <p>be a syntactically valid JSON object; and</p> </li> <li> <p>contain at least a top-level JSON key of "default" with a value that is a string.</p> </li> </ul> <p>You can define other top-level keys that define the message you want to send to a specific transport protocol (e.g., "http").</p> <p>Valid value: <code>json</code> </p>
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
  var valid_21626806 = query.getOrDefault("MessageAttributes.0.value")
  valid_21626806 = validateParameter(valid_21626806, JString, required = false,
                                   default = nil)
  if valid_21626806 != nil:
    section.add "MessageAttributes.0.value", valid_21626806
  var valid_21626807 = query.getOrDefault("MessageAttributes.0.key")
  valid_21626807 = validateParameter(valid_21626807, JString, required = false,
                                   default = nil)
  if valid_21626807 != nil:
    section.add "MessageAttributes.0.key", valid_21626807
  var valid_21626808 = query.getOrDefault("MessageAttributes.1.value")
  valid_21626808 = validateParameter(valid_21626808, JString, required = false,
                                   default = nil)
  if valid_21626808 != nil:
    section.add "MessageAttributes.1.value", valid_21626808
  assert query != nil, "query argument is necessary due to required `Message` field"
  var valid_21626809 = query.getOrDefault("Message")
  valid_21626809 = validateParameter(valid_21626809, JString, required = true,
                                   default = nil)
  if valid_21626809 != nil:
    section.add "Message", valid_21626809
  var valid_21626810 = query.getOrDefault("Subject")
  valid_21626810 = validateParameter(valid_21626810, JString, required = false,
                                   default = nil)
  if valid_21626810 != nil:
    section.add "Subject", valid_21626810
  var valid_21626811 = query.getOrDefault("Action")
  valid_21626811 = validateParameter(valid_21626811, JString, required = true,
                                   default = newJString("Publish"))
  if valid_21626811 != nil:
    section.add "Action", valid_21626811
  var valid_21626812 = query.getOrDefault("MessageAttributes.2.value")
  valid_21626812 = validateParameter(valid_21626812, JString, required = false,
                                   default = nil)
  if valid_21626812 != nil:
    section.add "MessageAttributes.2.value", valid_21626812
  var valid_21626813 = query.getOrDefault("MessageStructure")
  valid_21626813 = validateParameter(valid_21626813, JString, required = false,
                                   default = nil)
  if valid_21626813 != nil:
    section.add "MessageStructure", valid_21626813
  var valid_21626814 = query.getOrDefault("TopicArn")
  valid_21626814 = validateParameter(valid_21626814, JString, required = false,
                                   default = nil)
  if valid_21626814 != nil:
    section.add "TopicArn", valid_21626814
  var valid_21626815 = query.getOrDefault("PhoneNumber")
  valid_21626815 = validateParameter(valid_21626815, JString, required = false,
                                   default = nil)
  if valid_21626815 != nil:
    section.add "PhoneNumber", valid_21626815
  var valid_21626816 = query.getOrDefault("MessageAttributes.1.key")
  valid_21626816 = validateParameter(valid_21626816, JString, required = false,
                                   default = nil)
  if valid_21626816 != nil:
    section.add "MessageAttributes.1.key", valid_21626816
  var valid_21626817 = query.getOrDefault("MessageAttributes.2.key")
  valid_21626817 = validateParameter(valid_21626817, JString, required = false,
                                   default = nil)
  if valid_21626817 != nil:
    section.add "MessageAttributes.2.key", valid_21626817
  var valid_21626818 = query.getOrDefault("TargetArn")
  valid_21626818 = validateParameter(valid_21626818, JString, required = false,
                                   default = nil)
  if valid_21626818 != nil:
    section.add "TargetArn", valid_21626818
  var valid_21626819 = query.getOrDefault("Version")
  valid_21626819 = validateParameter(valid_21626819, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626819 != nil:
    section.add "Version", valid_21626819
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626820 = header.getOrDefault("X-Amz-Date")
  valid_21626820 = validateParameter(valid_21626820, JString, required = false,
                                   default = nil)
  if valid_21626820 != nil:
    section.add "X-Amz-Date", valid_21626820
  var valid_21626821 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626821 = validateParameter(valid_21626821, JString, required = false,
                                   default = nil)
  if valid_21626821 != nil:
    section.add "X-Amz-Security-Token", valid_21626821
  var valid_21626822 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626822 = validateParameter(valid_21626822, JString, required = false,
                                   default = nil)
  if valid_21626822 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626822
  var valid_21626823 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626823 = validateParameter(valid_21626823, JString, required = false,
                                   default = nil)
  if valid_21626823 != nil:
    section.add "X-Amz-Algorithm", valid_21626823
  var valid_21626824 = header.getOrDefault("X-Amz-Signature")
  valid_21626824 = validateParameter(valid_21626824, JString, required = false,
                                   default = nil)
  if valid_21626824 != nil:
    section.add "X-Amz-Signature", valid_21626824
  var valid_21626825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626825 = validateParameter(valid_21626825, JString, required = false,
                                   default = nil)
  if valid_21626825 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626825
  var valid_21626826 = header.getOrDefault("X-Amz-Credential")
  valid_21626826 = validateParameter(valid_21626826, JString, required = false,
                                   default = nil)
  if valid_21626826 != nil:
    section.add "X-Amz-Credential", valid_21626826
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626827: Call_GetPublish_21626803; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  let valid = call_21626827.validator(path, query, header, formData, body, _)
  let scheme = call_21626827.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626827.makeUrl(scheme.get, call_21626827.host, call_21626827.base,
                               call_21626827.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626827, uri, valid, _)

proc call*(call_21626828: Call_GetPublish_21626803; Message: string;
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
  ##          : <p>The message you want to send.</p> <p>If you are publishing to a topic and you want to send the same message to all transport protocols, include the text of the message as a String value. If you want to send different messages for each transport protocol, set the value of the <code>MessageStructure</code> parameter to <code>json</code> and use a JSON object for the <code>Message</code> parameter. </p> <p/> <p>Constraints:</p> <ul> <li> <p>With the exception of SMS, messages must be UTF-8 encoded strings and at most 256 KB in size (262,144 bytes, not 262,144 characters).</p> </li> <li> <p>For SMS, each message can contain up to 140 characters. This character limit depends on the encoding schema. For example, an SMS message can contain 160 GSM characters, 140 ASCII characters, or 70 UCS-2 characters.</p> <p>If you publish a message that exceeds this size limit, Amazon SNS sends the message as multiple messages, each fitting within the size limit. Messages aren't truncated mid-word but are cut off at whole-word boundaries.</p> <p>The total size limit for a single SMS <code>Publish</code> action is 1,600 characters.</p> </li> </ul> <p>JSON-specific constraints:</p> <ul> <li> <p>Keys in the JSON object that correspond to supported transport protocols must have simple JSON string values.</p> </li> <li> <p>The values will be parsed (unescaped) before they are used in outgoing messages.</p> </li> <li> <p>Outbound notifications are JSON encoded (meaning that the characters will be reescaped for sending).</p> </li> <li> <p>Values have a minimum length of 0 (the empty string, "", is allowed).</p> </li> <li> <p>Values have a maximum length bounded by the overall message size (so, including multiple protocols may limit message sizes).</p> </li> <li> <p>Non-string values will cause the key to be ignored.</p> </li> <li> <p>Keys that do not correspond to supported transport protocols are ignored.</p> </li> <li> <p>Duplicate keys are not allowed.</p> </li> <li> <p>Failure to parse or validate any key or value in the message will cause the <code>Publish</code> call to return an error (no partial delivery).</p> </li> </ul>
  ##   Subject: string
  ##          : <p>Optional parameter to be used as the "Subject" line when the message is delivered to email endpoints. This field will also be included, if present, in the standard JSON messages delivered to other endpoints.</p> <p>Constraints: Subjects must be ASCII text that begins with a letter, number, or punctuation mark; must not include line breaks or control characters; and must be less than 100 characters long.</p>
  ##   Action: string (required)
  ##   MessageAttributes2Value: string
  ##   MessageStructure: string
  ##                   : <p>Set <code>MessageStructure</code> to <code>json</code> if you want to send a different message for each protocol. For example, using one publish action, you can send a short message to your SMS subscribers and a longer message to your email subscribers. If you set <code>MessageStructure</code> to <code>json</code>, the value of the <code>Message</code> parameter must: </p> <ul> <li> <p>be a syntactically valid JSON object; and</p> </li> <li> <p>contain at least a top-level JSON key of "default" with a value that is a string.</p> </li> </ul> <p>You can define other top-level keys that define the message you want to send to a specific transport protocol (e.g., "http").</p> <p>Valid value: <code>json</code> </p>
  ##   TopicArn: string
  ##           : <p>The topic you want to publish to.</p> <p>If you don't specify a value for the <code>TopicArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TargetArn</code> parameters.</p>
  ##   PhoneNumber: string
  ##              : <p>The phone number to which you want to deliver an SMS message. Use E.164 format.</p> <p>If you don't specify a value for the <code>PhoneNumber</code> parameter, you must specify a value for the <code>TargetArn</code> or <code>TopicArn</code> parameters.</p>
  ##   MessageAttributes1Key: string
  ##   MessageAttributes2Key: string
  ##   TargetArn: string
  ##            : If you don't specify a value for the <code>TargetArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TopicArn</code> parameters.
  ##   Version: string (required)
  var query_21626829 = newJObject()
  add(query_21626829, "MessageAttributes.0.value",
      newJString(MessageAttributes0Value))
  add(query_21626829, "MessageAttributes.0.key", newJString(MessageAttributes0Key))
  add(query_21626829, "MessageAttributes.1.value",
      newJString(MessageAttributes1Value))
  add(query_21626829, "Message", newJString(Message))
  add(query_21626829, "Subject", newJString(Subject))
  add(query_21626829, "Action", newJString(Action))
  add(query_21626829, "MessageAttributes.2.value",
      newJString(MessageAttributes2Value))
  add(query_21626829, "MessageStructure", newJString(MessageStructure))
  add(query_21626829, "TopicArn", newJString(TopicArn))
  add(query_21626829, "PhoneNumber", newJString(PhoneNumber))
  add(query_21626829, "MessageAttributes.1.key", newJString(MessageAttributes1Key))
  add(query_21626829, "MessageAttributes.2.key", newJString(MessageAttributes2Key))
  add(query_21626829, "TargetArn", newJString(TargetArn))
  add(query_21626829, "Version", newJString(Version))
  result = call_21626828.call(nil, query_21626829, nil, nil, nil)

var getPublish* = Call_GetPublish_21626803(name: "getPublish",
                                        meth: HttpMethod.HttpGet,
                                        host: "sns.amazonaws.com",
                                        route: "/#Action=Publish",
                                        validator: validate_GetPublish_21626804,
                                        base: "/", makeUrl: url_GetPublish_21626805,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemovePermission_21626875 = ref object of OpenApiRestCall_21625435
proc url_PostRemovePermission_21626877(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemovePermission_21626876(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626878 = query.getOrDefault("Action")
  valid_21626878 = validateParameter(valid_21626878, JString, required = true,
                                   default = newJString("RemovePermission"))
  if valid_21626878 != nil:
    section.add "Action", valid_21626878
  var valid_21626879 = query.getOrDefault("Version")
  valid_21626879 = validateParameter(valid_21626879, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626879 != nil:
    section.add "Version", valid_21626879
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626880 = header.getOrDefault("X-Amz-Date")
  valid_21626880 = validateParameter(valid_21626880, JString, required = false,
                                   default = nil)
  if valid_21626880 != nil:
    section.add "X-Amz-Date", valid_21626880
  var valid_21626881 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626881 = validateParameter(valid_21626881, JString, required = false,
                                   default = nil)
  if valid_21626881 != nil:
    section.add "X-Amz-Security-Token", valid_21626881
  var valid_21626882 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626882 = validateParameter(valid_21626882, JString, required = false,
                                   default = nil)
  if valid_21626882 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626882
  var valid_21626883 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626883 = validateParameter(valid_21626883, JString, required = false,
                                   default = nil)
  if valid_21626883 != nil:
    section.add "X-Amz-Algorithm", valid_21626883
  var valid_21626884 = header.getOrDefault("X-Amz-Signature")
  valid_21626884 = validateParameter(valid_21626884, JString, required = false,
                                   default = nil)
  if valid_21626884 != nil:
    section.add "X-Amz-Signature", valid_21626884
  var valid_21626885 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626885 = validateParameter(valid_21626885, JString, required = false,
                                   default = nil)
  if valid_21626885 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626885
  var valid_21626886 = header.getOrDefault("X-Amz-Credential")
  valid_21626886 = validateParameter(valid_21626886, JString, required = false,
                                   default = nil)
  if valid_21626886 != nil:
    section.add "X-Amz-Credential", valid_21626886
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Label: JString (required)
  ##        : The unique label of the statement you want to remove.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_21626887 = formData.getOrDefault("TopicArn")
  valid_21626887 = validateParameter(valid_21626887, JString, required = true,
                                   default = nil)
  if valid_21626887 != nil:
    section.add "TopicArn", valid_21626887
  var valid_21626888 = formData.getOrDefault("Label")
  valid_21626888 = validateParameter(valid_21626888, JString, required = true,
                                   default = nil)
  if valid_21626888 != nil:
    section.add "Label", valid_21626888
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626889: Call_PostRemovePermission_21626875; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a statement from a topic's access control policy.
  ## 
  let valid = call_21626889.validator(path, query, header, formData, body, _)
  let scheme = call_21626889.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626889.makeUrl(scheme.get, call_21626889.host, call_21626889.base,
                               call_21626889.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626889, uri, valid, _)

proc call*(call_21626890: Call_PostRemovePermission_21626875; TopicArn: string;
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
  var query_21626891 = newJObject()
  var formData_21626892 = newJObject()
  add(formData_21626892, "TopicArn", newJString(TopicArn))
  add(formData_21626892, "Label", newJString(Label))
  add(query_21626891, "Action", newJString(Action))
  add(query_21626891, "Version", newJString(Version))
  result = call_21626890.call(nil, query_21626891, nil, formData_21626892, nil)

var postRemovePermission* = Call_PostRemovePermission_21626875(
    name: "postRemovePermission", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=RemovePermission",
    validator: validate_PostRemovePermission_21626876, base: "/",
    makeUrl: url_PostRemovePermission_21626877,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemovePermission_21626858 = ref object of OpenApiRestCall_21625435
proc url_GetRemovePermission_21626860(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemovePermission_21626859(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626861 = query.getOrDefault("Action")
  valid_21626861 = validateParameter(valid_21626861, JString, required = true,
                                   default = newJString("RemovePermission"))
  if valid_21626861 != nil:
    section.add "Action", valid_21626861
  var valid_21626862 = query.getOrDefault("TopicArn")
  valid_21626862 = validateParameter(valid_21626862, JString, required = true,
                                   default = nil)
  if valid_21626862 != nil:
    section.add "TopicArn", valid_21626862
  var valid_21626863 = query.getOrDefault("Version")
  valid_21626863 = validateParameter(valid_21626863, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626863 != nil:
    section.add "Version", valid_21626863
  var valid_21626864 = query.getOrDefault("Label")
  valid_21626864 = validateParameter(valid_21626864, JString, required = true,
                                   default = nil)
  if valid_21626864 != nil:
    section.add "Label", valid_21626864
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626865 = header.getOrDefault("X-Amz-Date")
  valid_21626865 = validateParameter(valid_21626865, JString, required = false,
                                   default = nil)
  if valid_21626865 != nil:
    section.add "X-Amz-Date", valid_21626865
  var valid_21626866 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626866 = validateParameter(valid_21626866, JString, required = false,
                                   default = nil)
  if valid_21626866 != nil:
    section.add "X-Amz-Security-Token", valid_21626866
  var valid_21626867 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626867 = validateParameter(valid_21626867, JString, required = false,
                                   default = nil)
  if valid_21626867 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626867
  var valid_21626868 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626868 = validateParameter(valid_21626868, JString, required = false,
                                   default = nil)
  if valid_21626868 != nil:
    section.add "X-Amz-Algorithm", valid_21626868
  var valid_21626869 = header.getOrDefault("X-Amz-Signature")
  valid_21626869 = validateParameter(valid_21626869, JString, required = false,
                                   default = nil)
  if valid_21626869 != nil:
    section.add "X-Amz-Signature", valid_21626869
  var valid_21626870 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626870 = validateParameter(valid_21626870, JString, required = false,
                                   default = nil)
  if valid_21626870 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626870
  var valid_21626871 = header.getOrDefault("X-Amz-Credential")
  valid_21626871 = validateParameter(valid_21626871, JString, required = false,
                                   default = nil)
  if valid_21626871 != nil:
    section.add "X-Amz-Credential", valid_21626871
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626872: Call_GetRemovePermission_21626858; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a statement from a topic's access control policy.
  ## 
  let valid = call_21626872.validator(path, query, header, formData, body, _)
  let scheme = call_21626872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626872.makeUrl(scheme.get, call_21626872.host, call_21626872.base,
                               call_21626872.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626872, uri, valid, _)

proc call*(call_21626873: Call_GetRemovePermission_21626858; TopicArn: string;
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
  var query_21626874 = newJObject()
  add(query_21626874, "Action", newJString(Action))
  add(query_21626874, "TopicArn", newJString(TopicArn))
  add(query_21626874, "Version", newJString(Version))
  add(query_21626874, "Label", newJString(Label))
  result = call_21626873.call(nil, query_21626874, nil, nil, nil)

var getRemovePermission* = Call_GetRemovePermission_21626858(
    name: "getRemovePermission", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=RemovePermission",
    validator: validate_GetRemovePermission_21626859, base: "/",
    makeUrl: url_GetRemovePermission_21626860,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetEndpointAttributes_21626915 = ref object of OpenApiRestCall_21625435
proc url_PostSetEndpointAttributes_21626917(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetEndpointAttributes_21626916(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626918 = query.getOrDefault("Action")
  valid_21626918 = validateParameter(valid_21626918, JString, required = true, default = newJString(
      "SetEndpointAttributes"))
  if valid_21626918 != nil:
    section.add "Action", valid_21626918
  var valid_21626919 = query.getOrDefault("Version")
  valid_21626919 = validateParameter(valid_21626919, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626919 != nil:
    section.add "Version", valid_21626919
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626920 = header.getOrDefault("X-Amz-Date")
  valid_21626920 = validateParameter(valid_21626920, JString, required = false,
                                   default = nil)
  if valid_21626920 != nil:
    section.add "X-Amz-Date", valid_21626920
  var valid_21626921 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626921 = validateParameter(valid_21626921, JString, required = false,
                                   default = nil)
  if valid_21626921 != nil:
    section.add "X-Amz-Security-Token", valid_21626921
  var valid_21626922 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626922 = validateParameter(valid_21626922, JString, required = false,
                                   default = nil)
  if valid_21626922 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626922
  var valid_21626923 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626923 = validateParameter(valid_21626923, JString, required = false,
                                   default = nil)
  if valid_21626923 != nil:
    section.add "X-Amz-Algorithm", valid_21626923
  var valid_21626924 = header.getOrDefault("X-Amz-Signature")
  valid_21626924 = validateParameter(valid_21626924, JString, required = false,
                                   default = nil)
  if valid_21626924 != nil:
    section.add "X-Amz-Signature", valid_21626924
  var valid_21626925 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626925 = validateParameter(valid_21626925, JString, required = false,
                                   default = nil)
  if valid_21626925 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626925
  var valid_21626926 = header.getOrDefault("X-Amz-Credential")
  valid_21626926 = validateParameter(valid_21626926, JString, required = false,
                                   default = nil)
  if valid_21626926 != nil:
    section.add "X-Amz-Credential", valid_21626926
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
  var valid_21626927 = formData.getOrDefault("Attributes.0.value")
  valid_21626927 = validateParameter(valid_21626927, JString, required = false,
                                   default = nil)
  if valid_21626927 != nil:
    section.add "Attributes.0.value", valid_21626927
  var valid_21626928 = formData.getOrDefault("Attributes.0.key")
  valid_21626928 = validateParameter(valid_21626928, JString, required = false,
                                   default = nil)
  if valid_21626928 != nil:
    section.add "Attributes.0.key", valid_21626928
  var valid_21626929 = formData.getOrDefault("Attributes.1.key")
  valid_21626929 = validateParameter(valid_21626929, JString, required = false,
                                   default = nil)
  if valid_21626929 != nil:
    section.add "Attributes.1.key", valid_21626929
  var valid_21626930 = formData.getOrDefault("Attributes.2.value")
  valid_21626930 = validateParameter(valid_21626930, JString, required = false,
                                   default = nil)
  if valid_21626930 != nil:
    section.add "Attributes.2.value", valid_21626930
  var valid_21626931 = formData.getOrDefault("Attributes.2.key")
  valid_21626931 = validateParameter(valid_21626931, JString, required = false,
                                   default = nil)
  if valid_21626931 != nil:
    section.add "Attributes.2.key", valid_21626931
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_21626932 = formData.getOrDefault("EndpointArn")
  valid_21626932 = validateParameter(valid_21626932, JString, required = true,
                                   default = nil)
  if valid_21626932 != nil:
    section.add "EndpointArn", valid_21626932
  var valid_21626933 = formData.getOrDefault("Attributes.1.value")
  valid_21626933 = validateParameter(valid_21626933, JString, required = false,
                                   default = nil)
  if valid_21626933 != nil:
    section.add "Attributes.1.value", valid_21626933
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626934: Call_PostSetEndpointAttributes_21626915;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_21626934.validator(path, query, header, formData, body, _)
  let scheme = call_21626934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626934.makeUrl(scheme.get, call_21626934.host, call_21626934.base,
                               call_21626934.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626934, uri, valid, _)

proc call*(call_21626935: Call_PostSetEndpointAttributes_21626915;
          EndpointArn: string; Attributes0Value: string = "";
          Attributes0Key: string = ""; Attributes1Key: string = "";
          Action: string = "SetEndpointAttributes"; Attributes2Value: string = "";
          Attributes2Key: string = ""; Version: string = "2010-03-31";
          Attributes1Value: string = ""): Recallable =
  ## postSetEndpointAttributes
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
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
  var query_21626936 = newJObject()
  var formData_21626937 = newJObject()
  add(formData_21626937, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_21626937, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_21626937, "Attributes.1.key", newJString(Attributes1Key))
  add(query_21626936, "Action", newJString(Action))
  add(formData_21626937, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_21626937, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_21626937, "EndpointArn", newJString(EndpointArn))
  add(query_21626936, "Version", newJString(Version))
  add(formData_21626937, "Attributes.1.value", newJString(Attributes1Value))
  result = call_21626935.call(nil, query_21626936, nil, formData_21626937, nil)

var postSetEndpointAttributes* = Call_PostSetEndpointAttributes_21626915(
    name: "postSetEndpointAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetEndpointAttributes",
    validator: validate_PostSetEndpointAttributes_21626916, base: "/",
    makeUrl: url_PostSetEndpointAttributes_21626917,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetEndpointAttributes_21626893 = ref object of OpenApiRestCall_21625435
proc url_GetSetEndpointAttributes_21626895(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetEndpointAttributes_21626894(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
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
  var valid_21626896 = query.getOrDefault("EndpointArn")
  valid_21626896 = validateParameter(valid_21626896, JString, required = true,
                                   default = nil)
  if valid_21626896 != nil:
    section.add "EndpointArn", valid_21626896
  var valid_21626897 = query.getOrDefault("Attributes.2.key")
  valid_21626897 = validateParameter(valid_21626897, JString, required = false,
                                   default = nil)
  if valid_21626897 != nil:
    section.add "Attributes.2.key", valid_21626897
  var valid_21626898 = query.getOrDefault("Attributes.1.value")
  valid_21626898 = validateParameter(valid_21626898, JString, required = false,
                                   default = nil)
  if valid_21626898 != nil:
    section.add "Attributes.1.value", valid_21626898
  var valid_21626899 = query.getOrDefault("Attributes.0.value")
  valid_21626899 = validateParameter(valid_21626899, JString, required = false,
                                   default = nil)
  if valid_21626899 != nil:
    section.add "Attributes.0.value", valid_21626899
  var valid_21626900 = query.getOrDefault("Action")
  valid_21626900 = validateParameter(valid_21626900, JString, required = true, default = newJString(
      "SetEndpointAttributes"))
  if valid_21626900 != nil:
    section.add "Action", valid_21626900
  var valid_21626901 = query.getOrDefault("Attributes.1.key")
  valid_21626901 = validateParameter(valid_21626901, JString, required = false,
                                   default = nil)
  if valid_21626901 != nil:
    section.add "Attributes.1.key", valid_21626901
  var valid_21626902 = query.getOrDefault("Attributes.2.value")
  valid_21626902 = validateParameter(valid_21626902, JString, required = false,
                                   default = nil)
  if valid_21626902 != nil:
    section.add "Attributes.2.value", valid_21626902
  var valid_21626903 = query.getOrDefault("Attributes.0.key")
  valid_21626903 = validateParameter(valid_21626903, JString, required = false,
                                   default = nil)
  if valid_21626903 != nil:
    section.add "Attributes.0.key", valid_21626903
  var valid_21626904 = query.getOrDefault("Version")
  valid_21626904 = validateParameter(valid_21626904, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626904 != nil:
    section.add "Version", valid_21626904
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626905 = header.getOrDefault("X-Amz-Date")
  valid_21626905 = validateParameter(valid_21626905, JString, required = false,
                                   default = nil)
  if valid_21626905 != nil:
    section.add "X-Amz-Date", valid_21626905
  var valid_21626906 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626906 = validateParameter(valid_21626906, JString, required = false,
                                   default = nil)
  if valid_21626906 != nil:
    section.add "X-Amz-Security-Token", valid_21626906
  var valid_21626907 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626907 = validateParameter(valid_21626907, JString, required = false,
                                   default = nil)
  if valid_21626907 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626907
  var valid_21626908 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626908 = validateParameter(valid_21626908, JString, required = false,
                                   default = nil)
  if valid_21626908 != nil:
    section.add "X-Amz-Algorithm", valid_21626908
  var valid_21626909 = header.getOrDefault("X-Amz-Signature")
  valid_21626909 = validateParameter(valid_21626909, JString, required = false,
                                   default = nil)
  if valid_21626909 != nil:
    section.add "X-Amz-Signature", valid_21626909
  var valid_21626910 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626910 = validateParameter(valid_21626910, JString, required = false,
                                   default = nil)
  if valid_21626910 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626910
  var valid_21626911 = header.getOrDefault("X-Amz-Credential")
  valid_21626911 = validateParameter(valid_21626911, JString, required = false,
                                   default = nil)
  if valid_21626911 != nil:
    section.add "X-Amz-Credential", valid_21626911
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626912: Call_GetSetEndpointAttributes_21626893;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_21626912.validator(path, query, header, formData, body, _)
  let scheme = call_21626912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626912.makeUrl(scheme.get, call_21626912.host, call_21626912.base,
                               call_21626912.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626912, uri, valid, _)

proc call*(call_21626913: Call_GetSetEndpointAttributes_21626893;
          EndpointArn: string; Attributes2Key: string = "";
          Attributes1Value: string = ""; Attributes0Value: string = "";
          Action: string = "SetEndpointAttributes"; Attributes1Key: string = "";
          Attributes2Value: string = ""; Attributes0Key: string = "";
          Version: string = "2010-03-31"): Recallable =
  ## getSetEndpointAttributes
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
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
  var query_21626914 = newJObject()
  add(query_21626914, "EndpointArn", newJString(EndpointArn))
  add(query_21626914, "Attributes.2.key", newJString(Attributes2Key))
  add(query_21626914, "Attributes.1.value", newJString(Attributes1Value))
  add(query_21626914, "Attributes.0.value", newJString(Attributes0Value))
  add(query_21626914, "Action", newJString(Action))
  add(query_21626914, "Attributes.1.key", newJString(Attributes1Key))
  add(query_21626914, "Attributes.2.value", newJString(Attributes2Value))
  add(query_21626914, "Attributes.0.key", newJString(Attributes0Key))
  add(query_21626914, "Version", newJString(Version))
  result = call_21626913.call(nil, query_21626914, nil, nil, nil)

var getSetEndpointAttributes* = Call_GetSetEndpointAttributes_21626893(
    name: "getSetEndpointAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetEndpointAttributes",
    validator: validate_GetSetEndpointAttributes_21626894, base: "/",
    makeUrl: url_GetSetEndpointAttributes_21626895,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetPlatformApplicationAttributes_21626960 = ref object of OpenApiRestCall_21625435
proc url_PostSetPlatformApplicationAttributes_21626962(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetPlatformApplicationAttributes_21626961(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626963 = query.getOrDefault("Action")
  valid_21626963 = validateParameter(valid_21626963, JString, required = true, default = newJString(
      "SetPlatformApplicationAttributes"))
  if valid_21626963 != nil:
    section.add "Action", valid_21626963
  var valid_21626964 = query.getOrDefault("Version")
  valid_21626964 = validateParameter(valid_21626964, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626964 != nil:
    section.add "Version", valid_21626964
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626965 = header.getOrDefault("X-Amz-Date")
  valid_21626965 = validateParameter(valid_21626965, JString, required = false,
                                   default = nil)
  if valid_21626965 != nil:
    section.add "X-Amz-Date", valid_21626965
  var valid_21626966 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626966 = validateParameter(valid_21626966, JString, required = false,
                                   default = nil)
  if valid_21626966 != nil:
    section.add "X-Amz-Security-Token", valid_21626966
  var valid_21626967 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626967 = validateParameter(valid_21626967, JString, required = false,
                                   default = nil)
  if valid_21626967 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626967
  var valid_21626968 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626968 = validateParameter(valid_21626968, JString, required = false,
                                   default = nil)
  if valid_21626968 != nil:
    section.add "X-Amz-Algorithm", valid_21626968
  var valid_21626969 = header.getOrDefault("X-Amz-Signature")
  valid_21626969 = validateParameter(valid_21626969, JString, required = false,
                                   default = nil)
  if valid_21626969 != nil:
    section.add "X-Amz-Signature", valid_21626969
  var valid_21626970 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626970 = validateParameter(valid_21626970, JString, required = false,
                                   default = nil)
  if valid_21626970 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626970
  var valid_21626971 = header.getOrDefault("X-Amz-Credential")
  valid_21626971 = validateParameter(valid_21626971, JString, required = false,
                                   default = nil)
  if valid_21626971 != nil:
    section.add "X-Amz-Credential", valid_21626971
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
  var valid_21626972 = formData.getOrDefault("Attributes.0.value")
  valid_21626972 = validateParameter(valid_21626972, JString, required = false,
                                   default = nil)
  if valid_21626972 != nil:
    section.add "Attributes.0.value", valid_21626972
  var valid_21626973 = formData.getOrDefault("Attributes.0.key")
  valid_21626973 = validateParameter(valid_21626973, JString, required = false,
                                   default = nil)
  if valid_21626973 != nil:
    section.add "Attributes.0.key", valid_21626973
  var valid_21626974 = formData.getOrDefault("Attributes.1.key")
  valid_21626974 = validateParameter(valid_21626974, JString, required = false,
                                   default = nil)
  if valid_21626974 != nil:
    section.add "Attributes.1.key", valid_21626974
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_21626975 = formData.getOrDefault("PlatformApplicationArn")
  valid_21626975 = validateParameter(valid_21626975, JString, required = true,
                                   default = nil)
  if valid_21626975 != nil:
    section.add "PlatformApplicationArn", valid_21626975
  var valid_21626976 = formData.getOrDefault("Attributes.2.value")
  valid_21626976 = validateParameter(valid_21626976, JString, required = false,
                                   default = nil)
  if valid_21626976 != nil:
    section.add "Attributes.2.value", valid_21626976
  var valid_21626977 = formData.getOrDefault("Attributes.2.key")
  valid_21626977 = validateParameter(valid_21626977, JString, required = false,
                                   default = nil)
  if valid_21626977 != nil:
    section.add "Attributes.2.key", valid_21626977
  var valid_21626978 = formData.getOrDefault("Attributes.1.value")
  valid_21626978 = validateParameter(valid_21626978, JString, required = false,
                                   default = nil)
  if valid_21626978 != nil:
    section.add "Attributes.1.value", valid_21626978
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626979: Call_PostSetPlatformApplicationAttributes_21626960;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  let valid = call_21626979.validator(path, query, header, formData, body, _)
  let scheme = call_21626979.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626979.makeUrl(scheme.get, call_21626979.host, call_21626979.base,
                               call_21626979.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626979, uri, valid, _)

proc call*(call_21626980: Call_PostSetPlatformApplicationAttributes_21626960;
          PlatformApplicationArn: string; Attributes0Value: string = "";
          Attributes0Key: string = ""; Attributes1Key: string = "";
          Action: string = "SetPlatformApplicationAttributes";
          Attributes2Value: string = ""; Attributes2Key: string = "";
          Version: string = "2010-03-31"; Attributes1Value: string = ""): Recallable =
  ## postSetPlatformApplicationAttributes
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
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
  var query_21626981 = newJObject()
  var formData_21626982 = newJObject()
  add(formData_21626982, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_21626982, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_21626982, "Attributes.1.key", newJString(Attributes1Key))
  add(query_21626981, "Action", newJString(Action))
  add(formData_21626982, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(formData_21626982, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_21626982, "Attributes.2.key", newJString(Attributes2Key))
  add(query_21626981, "Version", newJString(Version))
  add(formData_21626982, "Attributes.1.value", newJString(Attributes1Value))
  result = call_21626980.call(nil, query_21626981, nil, formData_21626982, nil)

var postSetPlatformApplicationAttributes* = Call_PostSetPlatformApplicationAttributes_21626960(
    name: "postSetPlatformApplicationAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetPlatformApplicationAttributes",
    validator: validate_PostSetPlatformApplicationAttributes_21626961, base: "/",
    makeUrl: url_PostSetPlatformApplicationAttributes_21626962,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetPlatformApplicationAttributes_21626938 = ref object of OpenApiRestCall_21625435
proc url_GetSetPlatformApplicationAttributes_21626940(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetPlatformApplicationAttributes_21626939(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
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
  var valid_21626941 = query.getOrDefault("Attributes.2.key")
  valid_21626941 = validateParameter(valid_21626941, JString, required = false,
                                   default = nil)
  if valid_21626941 != nil:
    section.add "Attributes.2.key", valid_21626941
  var valid_21626942 = query.getOrDefault("Attributes.1.value")
  valid_21626942 = validateParameter(valid_21626942, JString, required = false,
                                   default = nil)
  if valid_21626942 != nil:
    section.add "Attributes.1.value", valid_21626942
  var valid_21626943 = query.getOrDefault("Attributes.0.value")
  valid_21626943 = validateParameter(valid_21626943, JString, required = false,
                                   default = nil)
  if valid_21626943 != nil:
    section.add "Attributes.0.value", valid_21626943
  var valid_21626944 = query.getOrDefault("Action")
  valid_21626944 = validateParameter(valid_21626944, JString, required = true, default = newJString(
      "SetPlatformApplicationAttributes"))
  if valid_21626944 != nil:
    section.add "Action", valid_21626944
  var valid_21626945 = query.getOrDefault("Attributes.1.key")
  valid_21626945 = validateParameter(valid_21626945, JString, required = false,
                                   default = nil)
  if valid_21626945 != nil:
    section.add "Attributes.1.key", valid_21626945
  var valid_21626946 = query.getOrDefault("Attributes.2.value")
  valid_21626946 = validateParameter(valid_21626946, JString, required = false,
                                   default = nil)
  if valid_21626946 != nil:
    section.add "Attributes.2.value", valid_21626946
  var valid_21626947 = query.getOrDefault("Attributes.0.key")
  valid_21626947 = validateParameter(valid_21626947, JString, required = false,
                                   default = nil)
  if valid_21626947 != nil:
    section.add "Attributes.0.key", valid_21626947
  var valid_21626948 = query.getOrDefault("Version")
  valid_21626948 = validateParameter(valid_21626948, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626948 != nil:
    section.add "Version", valid_21626948
  var valid_21626949 = query.getOrDefault("PlatformApplicationArn")
  valid_21626949 = validateParameter(valid_21626949, JString, required = true,
                                   default = nil)
  if valid_21626949 != nil:
    section.add "PlatformApplicationArn", valid_21626949
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626950 = header.getOrDefault("X-Amz-Date")
  valid_21626950 = validateParameter(valid_21626950, JString, required = false,
                                   default = nil)
  if valid_21626950 != nil:
    section.add "X-Amz-Date", valid_21626950
  var valid_21626951 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626951 = validateParameter(valid_21626951, JString, required = false,
                                   default = nil)
  if valid_21626951 != nil:
    section.add "X-Amz-Security-Token", valid_21626951
  var valid_21626952 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626952 = validateParameter(valid_21626952, JString, required = false,
                                   default = nil)
  if valid_21626952 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626952
  var valid_21626953 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626953 = validateParameter(valid_21626953, JString, required = false,
                                   default = nil)
  if valid_21626953 != nil:
    section.add "X-Amz-Algorithm", valid_21626953
  var valid_21626954 = header.getOrDefault("X-Amz-Signature")
  valid_21626954 = validateParameter(valid_21626954, JString, required = false,
                                   default = nil)
  if valid_21626954 != nil:
    section.add "X-Amz-Signature", valid_21626954
  var valid_21626955 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626955 = validateParameter(valid_21626955, JString, required = false,
                                   default = nil)
  if valid_21626955 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626955
  var valid_21626956 = header.getOrDefault("X-Amz-Credential")
  valid_21626956 = validateParameter(valid_21626956, JString, required = false,
                                   default = nil)
  if valid_21626956 != nil:
    section.add "X-Amz-Credential", valid_21626956
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626957: Call_GetSetPlatformApplicationAttributes_21626938;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  let valid = call_21626957.validator(path, query, header, formData, body, _)
  let scheme = call_21626957.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626957.makeUrl(scheme.get, call_21626957.host, call_21626957.base,
                               call_21626957.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626957, uri, valid, _)

proc call*(call_21626958: Call_GetSetPlatformApplicationAttributes_21626938;
          PlatformApplicationArn: string; Attributes2Key: string = "";
          Attributes1Value: string = ""; Attributes0Value: string = "";
          Action: string = "SetPlatformApplicationAttributes";
          Attributes1Key: string = ""; Attributes2Value: string = "";
          Attributes0Key: string = ""; Version: string = "2010-03-31"): Recallable =
  ## getSetPlatformApplicationAttributes
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
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
  var query_21626959 = newJObject()
  add(query_21626959, "Attributes.2.key", newJString(Attributes2Key))
  add(query_21626959, "Attributes.1.value", newJString(Attributes1Value))
  add(query_21626959, "Attributes.0.value", newJString(Attributes0Value))
  add(query_21626959, "Action", newJString(Action))
  add(query_21626959, "Attributes.1.key", newJString(Attributes1Key))
  add(query_21626959, "Attributes.2.value", newJString(Attributes2Value))
  add(query_21626959, "Attributes.0.key", newJString(Attributes0Key))
  add(query_21626959, "Version", newJString(Version))
  add(query_21626959, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_21626958.call(nil, query_21626959, nil, nil, nil)

var getSetPlatformApplicationAttributes* = Call_GetSetPlatformApplicationAttributes_21626938(
    name: "getSetPlatformApplicationAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetPlatformApplicationAttributes",
    validator: validate_GetSetPlatformApplicationAttributes_21626939, base: "/",
    makeUrl: url_GetSetPlatformApplicationAttributes_21626940,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSMSAttributes_21627004 = ref object of OpenApiRestCall_21625435
proc url_PostSetSMSAttributes_21627006(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetSMSAttributes_21627005(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627007 = query.getOrDefault("Action")
  valid_21627007 = validateParameter(valid_21627007, JString, required = true,
                                   default = newJString("SetSMSAttributes"))
  if valid_21627007 != nil:
    section.add "Action", valid_21627007
  var valid_21627008 = query.getOrDefault("Version")
  valid_21627008 = validateParameter(valid_21627008, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21627008 != nil:
    section.add "Version", valid_21627008
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627009 = header.getOrDefault("X-Amz-Date")
  valid_21627009 = validateParameter(valid_21627009, JString, required = false,
                                   default = nil)
  if valid_21627009 != nil:
    section.add "X-Amz-Date", valid_21627009
  var valid_21627010 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627010 = validateParameter(valid_21627010, JString, required = false,
                                   default = nil)
  if valid_21627010 != nil:
    section.add "X-Amz-Security-Token", valid_21627010
  var valid_21627011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627011 = validateParameter(valid_21627011, JString, required = false,
                                   default = nil)
  if valid_21627011 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627011
  var valid_21627012 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627012 = validateParameter(valid_21627012, JString, required = false,
                                   default = nil)
  if valid_21627012 != nil:
    section.add "X-Amz-Algorithm", valid_21627012
  var valid_21627013 = header.getOrDefault("X-Amz-Signature")
  valid_21627013 = validateParameter(valid_21627013, JString, required = false,
                                   default = nil)
  if valid_21627013 != nil:
    section.add "X-Amz-Signature", valid_21627013
  var valid_21627014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627014 = validateParameter(valid_21627014, JString, required = false,
                                   default = nil)
  if valid_21627014 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627014
  var valid_21627015 = header.getOrDefault("X-Amz-Credential")
  valid_21627015 = validateParameter(valid_21627015, JString, required = false,
                                   default = nil)
  if valid_21627015 != nil:
    section.add "X-Amz-Credential", valid_21627015
  result.add "header", section
  ## parameters in `formData` object:
  ##   attributes.2.value: JString
  ##   attributes.2.key: JString
  ##   attributes.1.value: JString
  ##   attributes.1.key: JString
  ##   attributes.0.key: JString
  ##   attributes.0.value: JString
  section = newJObject()
  var valid_21627016 = formData.getOrDefault("attributes.2.value")
  valid_21627016 = validateParameter(valid_21627016, JString, required = false,
                                   default = nil)
  if valid_21627016 != nil:
    section.add "attributes.2.value", valid_21627016
  var valid_21627017 = formData.getOrDefault("attributes.2.key")
  valid_21627017 = validateParameter(valid_21627017, JString, required = false,
                                   default = nil)
  if valid_21627017 != nil:
    section.add "attributes.2.key", valid_21627017
  var valid_21627018 = formData.getOrDefault("attributes.1.value")
  valid_21627018 = validateParameter(valid_21627018, JString, required = false,
                                   default = nil)
  if valid_21627018 != nil:
    section.add "attributes.1.value", valid_21627018
  var valid_21627019 = formData.getOrDefault("attributes.1.key")
  valid_21627019 = validateParameter(valid_21627019, JString, required = false,
                                   default = nil)
  if valid_21627019 != nil:
    section.add "attributes.1.key", valid_21627019
  var valid_21627020 = formData.getOrDefault("attributes.0.key")
  valid_21627020 = validateParameter(valid_21627020, JString, required = false,
                                   default = nil)
  if valid_21627020 != nil:
    section.add "attributes.0.key", valid_21627020
  var valid_21627021 = formData.getOrDefault("attributes.0.value")
  valid_21627021 = validateParameter(valid_21627021, JString, required = false,
                                   default = nil)
  if valid_21627021 != nil:
    section.add "attributes.0.value", valid_21627021
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627022: Call_PostSetSMSAttributes_21627004; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_21627022.validator(path, query, header, formData, body, _)
  let scheme = call_21627022.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627022.makeUrl(scheme.get, call_21627022.host, call_21627022.base,
                               call_21627022.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627022, uri, valid, _)

proc call*(call_21627023: Call_PostSetSMSAttributes_21627004;
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
  var query_21627024 = newJObject()
  var formData_21627025 = newJObject()
  add(formData_21627025, "attributes.2.value", newJString(attributes2Value))
  add(formData_21627025, "attributes.2.key", newJString(attributes2Key))
  add(query_21627024, "Action", newJString(Action))
  add(formData_21627025, "attributes.1.value", newJString(attributes1Value))
  add(formData_21627025, "attributes.1.key", newJString(attributes1Key))
  add(formData_21627025, "attributes.0.key", newJString(attributes0Key))
  add(query_21627024, "Version", newJString(Version))
  add(formData_21627025, "attributes.0.value", newJString(attributes0Value))
  result = call_21627023.call(nil, query_21627024, nil, formData_21627025, nil)

var postSetSMSAttributes* = Call_PostSetSMSAttributes_21627004(
    name: "postSetSMSAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetSMSAttributes",
    validator: validate_PostSetSMSAttributes_21627005, base: "/",
    makeUrl: url_PostSetSMSAttributes_21627006,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSMSAttributes_21626983 = ref object of OpenApiRestCall_21625435
proc url_GetSetSMSAttributes_21626985(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetSMSAttributes_21626984(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626986 = query.getOrDefault("attributes.2.key")
  valid_21626986 = validateParameter(valid_21626986, JString, required = false,
                                   default = nil)
  if valid_21626986 != nil:
    section.add "attributes.2.key", valid_21626986
  var valid_21626987 = query.getOrDefault("attributes.1.key")
  valid_21626987 = validateParameter(valid_21626987, JString, required = false,
                                   default = nil)
  if valid_21626987 != nil:
    section.add "attributes.1.key", valid_21626987
  var valid_21626988 = query.getOrDefault("Action")
  valid_21626988 = validateParameter(valid_21626988, JString, required = true,
                                   default = newJString("SetSMSAttributes"))
  if valid_21626988 != nil:
    section.add "Action", valid_21626988
  var valid_21626989 = query.getOrDefault("attributes.1.value")
  valid_21626989 = validateParameter(valid_21626989, JString, required = false,
                                   default = nil)
  if valid_21626989 != nil:
    section.add "attributes.1.value", valid_21626989
  var valid_21626990 = query.getOrDefault("attributes.0.value")
  valid_21626990 = validateParameter(valid_21626990, JString, required = false,
                                   default = nil)
  if valid_21626990 != nil:
    section.add "attributes.0.value", valid_21626990
  var valid_21626991 = query.getOrDefault("attributes.2.value")
  valid_21626991 = validateParameter(valid_21626991, JString, required = false,
                                   default = nil)
  if valid_21626991 != nil:
    section.add "attributes.2.value", valid_21626991
  var valid_21626992 = query.getOrDefault("attributes.0.key")
  valid_21626992 = validateParameter(valid_21626992, JString, required = false,
                                   default = nil)
  if valid_21626992 != nil:
    section.add "attributes.0.key", valid_21626992
  var valid_21626993 = query.getOrDefault("Version")
  valid_21626993 = validateParameter(valid_21626993, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21626993 != nil:
    section.add "Version", valid_21626993
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626994 = header.getOrDefault("X-Amz-Date")
  valid_21626994 = validateParameter(valid_21626994, JString, required = false,
                                   default = nil)
  if valid_21626994 != nil:
    section.add "X-Amz-Date", valid_21626994
  var valid_21626995 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626995 = validateParameter(valid_21626995, JString, required = false,
                                   default = nil)
  if valid_21626995 != nil:
    section.add "X-Amz-Security-Token", valid_21626995
  var valid_21626996 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626996 = validateParameter(valid_21626996, JString, required = false,
                                   default = nil)
  if valid_21626996 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626996
  var valid_21626997 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626997 = validateParameter(valid_21626997, JString, required = false,
                                   default = nil)
  if valid_21626997 != nil:
    section.add "X-Amz-Algorithm", valid_21626997
  var valid_21626998 = header.getOrDefault("X-Amz-Signature")
  valid_21626998 = validateParameter(valid_21626998, JString, required = false,
                                   default = nil)
  if valid_21626998 != nil:
    section.add "X-Amz-Signature", valid_21626998
  var valid_21626999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626999 = validateParameter(valid_21626999, JString, required = false,
                                   default = nil)
  if valid_21626999 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626999
  var valid_21627000 = header.getOrDefault("X-Amz-Credential")
  valid_21627000 = validateParameter(valid_21627000, JString, required = false,
                                   default = nil)
  if valid_21627000 != nil:
    section.add "X-Amz-Credential", valid_21627000
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627001: Call_GetSetSMSAttributes_21626983; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_21627001.validator(path, query, header, formData, body, _)
  let scheme = call_21627001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627001.makeUrl(scheme.get, call_21627001.host, call_21627001.base,
                               call_21627001.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627001, uri, valid, _)

proc call*(call_21627002: Call_GetSetSMSAttributes_21626983;
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
  var query_21627003 = newJObject()
  add(query_21627003, "attributes.2.key", newJString(attributes2Key))
  add(query_21627003, "attributes.1.key", newJString(attributes1Key))
  add(query_21627003, "Action", newJString(Action))
  add(query_21627003, "attributes.1.value", newJString(attributes1Value))
  add(query_21627003, "attributes.0.value", newJString(attributes0Value))
  add(query_21627003, "attributes.2.value", newJString(attributes2Value))
  add(query_21627003, "attributes.0.key", newJString(attributes0Key))
  add(query_21627003, "Version", newJString(Version))
  result = call_21627002.call(nil, query_21627003, nil, nil, nil)

var getSetSMSAttributes* = Call_GetSetSMSAttributes_21626983(
    name: "getSetSMSAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetSMSAttributes",
    validator: validate_GetSetSMSAttributes_21626984, base: "/",
    makeUrl: url_GetSetSMSAttributes_21626985,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSubscriptionAttributes_21627044 = ref object of OpenApiRestCall_21625435
proc url_PostSetSubscriptionAttributes_21627046(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetSubscriptionAttributes_21627045(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627047 = query.getOrDefault("Action")
  valid_21627047 = validateParameter(valid_21627047, JString, required = true, default = newJString(
      "SetSubscriptionAttributes"))
  if valid_21627047 != nil:
    section.add "Action", valid_21627047
  var valid_21627048 = query.getOrDefault("Version")
  valid_21627048 = validateParameter(valid_21627048, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21627048 != nil:
    section.add "Version", valid_21627048
  result.add "query", section
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
  ## parameters in `formData` object:
  ##   AttributeName: JString (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>FilterPolicy</code> – The simple JSON object that lets your subscriber receive only a subset of messages, rather than receiving every message published to the topic.</p> </li> <li> <p> <code>RawMessageDelivery</code> – When set to <code>true</code>, enables raw message delivery to Amazon SQS or HTTP/S endpoints. This eliminates the need for the endpoints to process JSON formatting, which is otherwise created for Amazon SNS metadata.</p> </li> <li> <p> <code>RedrivePolicy</code> – When specified, sends undeliverable messages to the specified Amazon SQS dead-letter queue. Messages that can't be delivered due to client errors (for example, when the subscribed endpoint is unreachable) or server errors (for example, when the service that powers the subscribed endpoint becomes unavailable) are held in the dead-letter queue for further analysis or reprocessing.</p> </li> </ul>
  ##   AttributeValue: JString
  ##                 : The new value for the attribute in JSON format.
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription to modify.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AttributeName` field"
  var valid_21627056 = formData.getOrDefault("AttributeName")
  valid_21627056 = validateParameter(valid_21627056, JString, required = true,
                                   default = nil)
  if valid_21627056 != nil:
    section.add "AttributeName", valid_21627056
  var valid_21627057 = formData.getOrDefault("AttributeValue")
  valid_21627057 = validateParameter(valid_21627057, JString, required = false,
                                   default = nil)
  if valid_21627057 != nil:
    section.add "AttributeValue", valid_21627057
  var valid_21627058 = formData.getOrDefault("SubscriptionArn")
  valid_21627058 = validateParameter(valid_21627058, JString, required = true,
                                   default = nil)
  if valid_21627058 != nil:
    section.add "SubscriptionArn", valid_21627058
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627059: Call_PostSetSubscriptionAttributes_21627044;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ## 
  let valid = call_21627059.validator(path, query, header, formData, body, _)
  let scheme = call_21627059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627059.makeUrl(scheme.get, call_21627059.host, call_21627059.base,
                               call_21627059.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627059, uri, valid, _)

proc call*(call_21627060: Call_PostSetSubscriptionAttributes_21627044;
          AttributeName: string; SubscriptionArn: string;
          AttributeValue: string = ""; Action: string = "SetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postSetSubscriptionAttributes
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ##   AttributeName: string (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>FilterPolicy</code> – The simple JSON object that lets your subscriber receive only a subset of messages, rather than receiving every message published to the topic.</p> </li> <li> <p> <code>RawMessageDelivery</code> – When set to <code>true</code>, enables raw message delivery to Amazon SQS or HTTP/S endpoints. This eliminates the need for the endpoints to process JSON formatting, which is otherwise created for Amazon SNS metadata.</p> </li> <li> <p> <code>RedrivePolicy</code> – When specified, sends undeliverable messages to the specified Amazon SQS dead-letter queue. Messages that can't be delivered due to client errors (for example, when the subscribed endpoint is unreachable) or server errors (for example, when the service that powers the subscribed endpoint becomes unavailable) are held in the dead-letter queue for further analysis or reprocessing.</p> </li> </ul>
  ##   AttributeValue: string
  ##                 : The new value for the attribute in JSON format.
  ##   Action: string (required)
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to modify.
  ##   Version: string (required)
  var query_21627061 = newJObject()
  var formData_21627062 = newJObject()
  add(formData_21627062, "AttributeName", newJString(AttributeName))
  add(formData_21627062, "AttributeValue", newJString(AttributeValue))
  add(query_21627061, "Action", newJString(Action))
  add(formData_21627062, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_21627061, "Version", newJString(Version))
  result = call_21627060.call(nil, query_21627061, nil, formData_21627062, nil)

var postSetSubscriptionAttributes* = Call_PostSetSubscriptionAttributes_21627044(
    name: "postSetSubscriptionAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetSubscriptionAttributes",
    validator: validate_PostSetSubscriptionAttributes_21627045, base: "/",
    makeUrl: url_PostSetSubscriptionAttributes_21627046,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSubscriptionAttributes_21627026 = ref object of OpenApiRestCall_21625435
proc url_GetSetSubscriptionAttributes_21627028(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetSubscriptionAttributes_21627027(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>FilterPolicy</code> – The simple JSON object that lets your subscriber receive only a subset of messages, rather than receiving every message published to the topic.</p> </li> <li> <p> <code>RawMessageDelivery</code> – When set to <code>true</code>, enables raw message delivery to Amazon SQS or HTTP/S endpoints. This eliminates the need for the endpoints to process JSON formatting, which is otherwise created for Amazon SNS metadata.</p> </li> <li> <p> <code>RedrivePolicy</code> – When specified, sends undeliverable messages to the specified Amazon SQS dead-letter queue. Messages that can't be delivered due to client errors (for example, when the subscribed endpoint is unreachable) or server errors (for example, when the service that powers the subscribed endpoint becomes unavailable) are held in the dead-letter queue for further analysis or reprocessing.</p> </li> </ul>
  ##   Action: JString (required)
  ##   AttributeValue: JString
  ##                 : The new value for the attribute in JSON format.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SubscriptionArn` field"
  var valid_21627029 = query.getOrDefault("SubscriptionArn")
  valid_21627029 = validateParameter(valid_21627029, JString, required = true,
                                   default = nil)
  if valid_21627029 != nil:
    section.add "SubscriptionArn", valid_21627029
  var valid_21627030 = query.getOrDefault("AttributeName")
  valid_21627030 = validateParameter(valid_21627030, JString, required = true,
                                   default = nil)
  if valid_21627030 != nil:
    section.add "AttributeName", valid_21627030
  var valid_21627031 = query.getOrDefault("Action")
  valid_21627031 = validateParameter(valid_21627031, JString, required = true, default = newJString(
      "SetSubscriptionAttributes"))
  if valid_21627031 != nil:
    section.add "Action", valid_21627031
  var valid_21627032 = query.getOrDefault("AttributeValue")
  valid_21627032 = validateParameter(valid_21627032, JString, required = false,
                                   default = nil)
  if valid_21627032 != nil:
    section.add "AttributeValue", valid_21627032
  var valid_21627033 = query.getOrDefault("Version")
  valid_21627033 = validateParameter(valid_21627033, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21627033 != nil:
    section.add "Version", valid_21627033
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627034 = header.getOrDefault("X-Amz-Date")
  valid_21627034 = validateParameter(valid_21627034, JString, required = false,
                                   default = nil)
  if valid_21627034 != nil:
    section.add "X-Amz-Date", valid_21627034
  var valid_21627035 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627035 = validateParameter(valid_21627035, JString, required = false,
                                   default = nil)
  if valid_21627035 != nil:
    section.add "X-Amz-Security-Token", valid_21627035
  var valid_21627036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627036 = validateParameter(valid_21627036, JString, required = false,
                                   default = nil)
  if valid_21627036 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627036
  var valid_21627037 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627037 = validateParameter(valid_21627037, JString, required = false,
                                   default = nil)
  if valid_21627037 != nil:
    section.add "X-Amz-Algorithm", valid_21627037
  var valid_21627038 = header.getOrDefault("X-Amz-Signature")
  valid_21627038 = validateParameter(valid_21627038, JString, required = false,
                                   default = nil)
  if valid_21627038 != nil:
    section.add "X-Amz-Signature", valid_21627038
  var valid_21627039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627039 = validateParameter(valid_21627039, JString, required = false,
                                   default = nil)
  if valid_21627039 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627039
  var valid_21627040 = header.getOrDefault("X-Amz-Credential")
  valid_21627040 = validateParameter(valid_21627040, JString, required = false,
                                   default = nil)
  if valid_21627040 != nil:
    section.add "X-Amz-Credential", valid_21627040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627041: Call_GetSetSubscriptionAttributes_21627026;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ## 
  let valid = call_21627041.validator(path, query, header, formData, body, _)
  let scheme = call_21627041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627041.makeUrl(scheme.get, call_21627041.host, call_21627041.base,
                               call_21627041.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627041, uri, valid, _)

proc call*(call_21627042: Call_GetSetSubscriptionAttributes_21627026;
          SubscriptionArn: string; AttributeName: string;
          Action: string = "SetSubscriptionAttributes"; AttributeValue: string = "";
          Version: string = "2010-03-31"): Recallable =
  ## getSetSubscriptionAttributes
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to modify.
  ##   AttributeName: string (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>FilterPolicy</code> – The simple JSON object that lets your subscriber receive only a subset of messages, rather than receiving every message published to the topic.</p> </li> <li> <p> <code>RawMessageDelivery</code> – When set to <code>true</code>, enables raw message delivery to Amazon SQS or HTTP/S endpoints. This eliminates the need for the endpoints to process JSON formatting, which is otherwise created for Amazon SNS metadata.</p> </li> <li> <p> <code>RedrivePolicy</code> – When specified, sends undeliverable messages to the specified Amazon SQS dead-letter queue. Messages that can't be delivered due to client errors (for example, when the subscribed endpoint is unreachable) or server errors (for example, when the service that powers the subscribed endpoint becomes unavailable) are held in the dead-letter queue for further analysis or reprocessing.</p> </li> </ul>
  ##   Action: string (required)
  ##   AttributeValue: string
  ##                 : The new value for the attribute in JSON format.
  ##   Version: string (required)
  var query_21627043 = newJObject()
  add(query_21627043, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_21627043, "AttributeName", newJString(AttributeName))
  add(query_21627043, "Action", newJString(Action))
  add(query_21627043, "AttributeValue", newJString(AttributeValue))
  add(query_21627043, "Version", newJString(Version))
  result = call_21627042.call(nil, query_21627043, nil, nil, nil)

var getSetSubscriptionAttributes* = Call_GetSetSubscriptionAttributes_21627026(
    name: "getSetSubscriptionAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetSubscriptionAttributes",
    validator: validate_GetSetSubscriptionAttributes_21627027, base: "/",
    makeUrl: url_GetSetSubscriptionAttributes_21627028,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetTopicAttributes_21627081 = ref object of OpenApiRestCall_21625435
proc url_PostSetTopicAttributes_21627083(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetTopicAttributes_21627082(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627084 = query.getOrDefault("Action")
  valid_21627084 = validateParameter(valid_21627084, JString, required = true,
                                   default = newJString("SetTopicAttributes"))
  if valid_21627084 != nil:
    section.add "Action", valid_21627084
  var valid_21627085 = query.getOrDefault("Version")
  valid_21627085 = validateParameter(valid_21627085, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21627085 != nil:
    section.add "Version", valid_21627085
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627086 = header.getOrDefault("X-Amz-Date")
  valid_21627086 = validateParameter(valid_21627086, JString, required = false,
                                   default = nil)
  if valid_21627086 != nil:
    section.add "X-Amz-Date", valid_21627086
  var valid_21627087 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627087 = validateParameter(valid_21627087, JString, required = false,
                                   default = nil)
  if valid_21627087 != nil:
    section.add "X-Amz-Security-Token", valid_21627087
  var valid_21627088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627088 = validateParameter(valid_21627088, JString, required = false,
                                   default = nil)
  if valid_21627088 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627088
  var valid_21627089 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627089 = validateParameter(valid_21627089, JString, required = false,
                                   default = nil)
  if valid_21627089 != nil:
    section.add "X-Amz-Algorithm", valid_21627089
  var valid_21627090 = header.getOrDefault("X-Amz-Signature")
  valid_21627090 = validateParameter(valid_21627090, JString, required = false,
                                   default = nil)
  if valid_21627090 != nil:
    section.add "X-Amz-Signature", valid_21627090
  var valid_21627091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627091 = validateParameter(valid_21627091, JString, required = false,
                                   default = nil)
  if valid_21627091 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627091
  var valid_21627092 = header.getOrDefault("X-Amz-Credential")
  valid_21627092 = validateParameter(valid_21627092, JString, required = false,
                                   default = nil)
  if valid_21627092 != nil:
    section.add "X-Amz-Credential", valid_21627092
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
  var valid_21627093 = formData.getOrDefault("TopicArn")
  valid_21627093 = validateParameter(valid_21627093, JString, required = true,
                                   default = nil)
  if valid_21627093 != nil:
    section.add "TopicArn", valid_21627093
  var valid_21627094 = formData.getOrDefault("AttributeName")
  valid_21627094 = validateParameter(valid_21627094, JString, required = true,
                                   default = nil)
  if valid_21627094 != nil:
    section.add "AttributeName", valid_21627094
  var valid_21627095 = formData.getOrDefault("AttributeValue")
  valid_21627095 = validateParameter(valid_21627095, JString, required = false,
                                   default = nil)
  if valid_21627095 != nil:
    section.add "AttributeValue", valid_21627095
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627096: Call_PostSetTopicAttributes_21627081;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  let valid = call_21627096.validator(path, query, header, formData, body, _)
  let scheme = call_21627096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627096.makeUrl(scheme.get, call_21627096.host, call_21627096.base,
                               call_21627096.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627096, uri, valid, _)

proc call*(call_21627097: Call_PostSetTopicAttributes_21627081; TopicArn: string;
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
  var query_21627098 = newJObject()
  var formData_21627099 = newJObject()
  add(formData_21627099, "TopicArn", newJString(TopicArn))
  add(formData_21627099, "AttributeName", newJString(AttributeName))
  add(formData_21627099, "AttributeValue", newJString(AttributeValue))
  add(query_21627098, "Action", newJString(Action))
  add(query_21627098, "Version", newJString(Version))
  result = call_21627097.call(nil, query_21627098, nil, formData_21627099, nil)

var postSetTopicAttributes* = Call_PostSetTopicAttributes_21627081(
    name: "postSetTopicAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetTopicAttributes",
    validator: validate_PostSetTopicAttributes_21627082, base: "/",
    makeUrl: url_PostSetTopicAttributes_21627083,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetTopicAttributes_21627063 = ref object of OpenApiRestCall_21625435
proc url_GetSetTopicAttributes_21627065(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetTopicAttributes_21627064(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627066 = query.getOrDefault("AttributeName")
  valid_21627066 = validateParameter(valid_21627066, JString, required = true,
                                   default = nil)
  if valid_21627066 != nil:
    section.add "AttributeName", valid_21627066
  var valid_21627067 = query.getOrDefault("Action")
  valid_21627067 = validateParameter(valid_21627067, JString, required = true,
                                   default = newJString("SetTopicAttributes"))
  if valid_21627067 != nil:
    section.add "Action", valid_21627067
  var valid_21627068 = query.getOrDefault("AttributeValue")
  valid_21627068 = validateParameter(valid_21627068, JString, required = false,
                                   default = nil)
  if valid_21627068 != nil:
    section.add "AttributeValue", valid_21627068
  var valid_21627069 = query.getOrDefault("TopicArn")
  valid_21627069 = validateParameter(valid_21627069, JString, required = true,
                                   default = nil)
  if valid_21627069 != nil:
    section.add "TopicArn", valid_21627069
  var valid_21627070 = query.getOrDefault("Version")
  valid_21627070 = validateParameter(valid_21627070, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21627070 != nil:
    section.add "Version", valid_21627070
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627071 = header.getOrDefault("X-Amz-Date")
  valid_21627071 = validateParameter(valid_21627071, JString, required = false,
                                   default = nil)
  if valid_21627071 != nil:
    section.add "X-Amz-Date", valid_21627071
  var valid_21627072 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627072 = validateParameter(valid_21627072, JString, required = false,
                                   default = nil)
  if valid_21627072 != nil:
    section.add "X-Amz-Security-Token", valid_21627072
  var valid_21627073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627073 = validateParameter(valid_21627073, JString, required = false,
                                   default = nil)
  if valid_21627073 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627073
  var valid_21627074 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627074 = validateParameter(valid_21627074, JString, required = false,
                                   default = nil)
  if valid_21627074 != nil:
    section.add "X-Amz-Algorithm", valid_21627074
  var valid_21627075 = header.getOrDefault("X-Amz-Signature")
  valid_21627075 = validateParameter(valid_21627075, JString, required = false,
                                   default = nil)
  if valid_21627075 != nil:
    section.add "X-Amz-Signature", valid_21627075
  var valid_21627076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627076 = validateParameter(valid_21627076, JString, required = false,
                                   default = nil)
  if valid_21627076 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627076
  var valid_21627077 = header.getOrDefault("X-Amz-Credential")
  valid_21627077 = validateParameter(valid_21627077, JString, required = false,
                                   default = nil)
  if valid_21627077 != nil:
    section.add "X-Amz-Credential", valid_21627077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627078: Call_GetSetTopicAttributes_21627063;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  let valid = call_21627078.validator(path, query, header, formData, body, _)
  let scheme = call_21627078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627078.makeUrl(scheme.get, call_21627078.host, call_21627078.base,
                               call_21627078.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627078, uri, valid, _)

proc call*(call_21627079: Call_GetSetTopicAttributes_21627063;
          AttributeName: string; TopicArn: string;
          Action: string = "SetTopicAttributes"; AttributeValue: string = "";
          Version: string = "2010-03-31"): Recallable =
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
  var query_21627080 = newJObject()
  add(query_21627080, "AttributeName", newJString(AttributeName))
  add(query_21627080, "Action", newJString(Action))
  add(query_21627080, "AttributeValue", newJString(AttributeValue))
  add(query_21627080, "TopicArn", newJString(TopicArn))
  add(query_21627080, "Version", newJString(Version))
  result = call_21627079.call(nil, query_21627080, nil, nil, nil)

var getSetTopicAttributes* = Call_GetSetTopicAttributes_21627063(
    name: "getSetTopicAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetTopicAttributes",
    validator: validate_GetSetTopicAttributes_21627064, base: "/",
    makeUrl: url_GetSetTopicAttributes_21627065,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSubscribe_21627125 = ref object of OpenApiRestCall_21625435
proc url_PostSubscribe_21627127(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSubscribe_21627126(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627128 = query.getOrDefault("Action")
  valid_21627128 = validateParameter(valid_21627128, JString, required = true,
                                   default = newJString("Subscribe"))
  if valid_21627128 != nil:
    section.add "Action", valid_21627128
  var valid_21627129 = query.getOrDefault("Version")
  valid_21627129 = validateParameter(valid_21627129, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21627129 != nil:
    section.add "Version", valid_21627129
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627130 = header.getOrDefault("X-Amz-Date")
  valid_21627130 = validateParameter(valid_21627130, JString, required = false,
                                   default = nil)
  if valid_21627130 != nil:
    section.add "X-Amz-Date", valid_21627130
  var valid_21627131 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627131 = validateParameter(valid_21627131, JString, required = false,
                                   default = nil)
  if valid_21627131 != nil:
    section.add "X-Amz-Security-Token", valid_21627131
  var valid_21627132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627132 = validateParameter(valid_21627132, JString, required = false,
                                   default = nil)
  if valid_21627132 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627132
  var valid_21627133 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627133 = validateParameter(valid_21627133, JString, required = false,
                                   default = nil)
  if valid_21627133 != nil:
    section.add "X-Amz-Algorithm", valid_21627133
  var valid_21627134 = header.getOrDefault("X-Amz-Signature")
  valid_21627134 = validateParameter(valid_21627134, JString, required = false,
                                   default = nil)
  if valid_21627134 != nil:
    section.add "X-Amz-Signature", valid_21627134
  var valid_21627135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627135 = validateParameter(valid_21627135, JString, required = false,
                                   default = nil)
  if valid_21627135 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627135
  var valid_21627136 = header.getOrDefault("X-Amz-Credential")
  valid_21627136 = validateParameter(valid_21627136, JString, required = false,
                                   default = nil)
  if valid_21627136 != nil:
    section.add "X-Amz-Credential", valid_21627136
  result.add "header", section
  ## parameters in `formData` object:
  ##   Endpoint: JString
  ##           : <p>The endpoint that you want to receive notifications. Endpoints vary by protocol:</p> <ul> <li> <p>For the <code>http</code> protocol, the endpoint is an URL beginning with <code>http://</code> </p> </li> <li> <p>For the <code>https</code> protocol, the endpoint is a URL beginning with <code>https://</code> </p> </li> <li> <p>For the <code>email</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>email-json</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>sms</code> protocol, the endpoint is a phone number of an SMS-enabled device</p> </li> <li> <p>For the <code>sqs</code> protocol, the endpoint is the ARN of an Amazon SQS queue</p> </li> <li> <p>For the <code>application</code> protocol, the endpoint is the EndpointArn of a mobile app and device.</p> </li> <li> <p>For the <code>lambda</code> protocol, the endpoint is the ARN of an Amazon Lambda function.</p> </li> </ul>
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic you want to subscribe to.
  ##   Attributes.0.value: JString
  ##   Protocol: JString (required)
  ##           : <p>The protocol you want to use. Supported protocols include:</p> <ul> <li> <p> <code>http</code> – delivery of JSON-encoded message via HTTP POST</p> </li> <li> <p> <code>https</code> – delivery of JSON-encoded message via HTTPS POST</p> </li> <li> <p> <code>email</code> – delivery of message via SMTP</p> </li> <li> <p> <code>email-json</code> – delivery of JSON-encoded message via SMTP</p> </li> <li> <p> <code>sms</code> – delivery of message via SMS</p> </li> <li> <p> <code>sqs</code> – delivery of JSON-encoded message to an Amazon SQS queue</p> </li> <li> <p> <code>application</code> – delivery of JSON-encoded message to an EndpointArn for a mobile app and device.</p> </li> <li> <p> <code>lambda</code> – delivery of JSON-encoded message to an Amazon Lambda function.</p> </li> </ul>
  ##   Attributes.0.key: JString
  ##   Attributes.1.key: JString
  ##   ReturnSubscriptionArn: JBool
  ##                        : <p>Sets whether the response from the <code>Subscribe</code> request includes the subscription ARN, even if the subscription is not yet confirmed.</p> <ul> <li> <p>If you have the subscription ARN returned, the response includes the ARN in all cases, even if the subscription is not yet confirmed.</p> </li> <li> <p>If you don't have the subscription ARN returned, in addition to the ARN for confirmed subscriptions, the response also includes the <code>pending subscription</code> ARN value for subscriptions that aren't yet confirmed. A subscription becomes confirmed when the subscriber calls the <code>ConfirmSubscription</code> action with a confirmation token.</p> </li> </ul> <p>If you set this parameter to <code>true</code>, .</p> <p>The default value is <code>false</code>.</p>
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   Attributes.1.value: JString
  section = newJObject()
  var valid_21627137 = formData.getOrDefault("Endpoint")
  valid_21627137 = validateParameter(valid_21627137, JString, required = false,
                                   default = nil)
  if valid_21627137 != nil:
    section.add "Endpoint", valid_21627137
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_21627138 = formData.getOrDefault("TopicArn")
  valid_21627138 = validateParameter(valid_21627138, JString, required = true,
                                   default = nil)
  if valid_21627138 != nil:
    section.add "TopicArn", valid_21627138
  var valid_21627139 = formData.getOrDefault("Attributes.0.value")
  valid_21627139 = validateParameter(valid_21627139, JString, required = false,
                                   default = nil)
  if valid_21627139 != nil:
    section.add "Attributes.0.value", valid_21627139
  var valid_21627140 = formData.getOrDefault("Protocol")
  valid_21627140 = validateParameter(valid_21627140, JString, required = true,
                                   default = nil)
  if valid_21627140 != nil:
    section.add "Protocol", valid_21627140
  var valid_21627141 = formData.getOrDefault("Attributes.0.key")
  valid_21627141 = validateParameter(valid_21627141, JString, required = false,
                                   default = nil)
  if valid_21627141 != nil:
    section.add "Attributes.0.key", valid_21627141
  var valid_21627142 = formData.getOrDefault("Attributes.1.key")
  valid_21627142 = validateParameter(valid_21627142, JString, required = false,
                                   default = nil)
  if valid_21627142 != nil:
    section.add "Attributes.1.key", valid_21627142
  var valid_21627143 = formData.getOrDefault("ReturnSubscriptionArn")
  valid_21627143 = validateParameter(valid_21627143, JBool, required = false,
                                   default = nil)
  if valid_21627143 != nil:
    section.add "ReturnSubscriptionArn", valid_21627143
  var valid_21627144 = formData.getOrDefault("Attributes.2.value")
  valid_21627144 = validateParameter(valid_21627144, JString, required = false,
                                   default = nil)
  if valid_21627144 != nil:
    section.add "Attributes.2.value", valid_21627144
  var valid_21627145 = formData.getOrDefault("Attributes.2.key")
  valid_21627145 = validateParameter(valid_21627145, JString, required = false,
                                   default = nil)
  if valid_21627145 != nil:
    section.add "Attributes.2.key", valid_21627145
  var valid_21627146 = formData.getOrDefault("Attributes.1.value")
  valid_21627146 = validateParameter(valid_21627146, JString, required = false,
                                   default = nil)
  if valid_21627146 != nil:
    section.add "Attributes.1.value", valid_21627146
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627147: Call_PostSubscribe_21627125; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_21627147.validator(path, query, header, formData, body, _)
  let scheme = call_21627147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627147.makeUrl(scheme.get, call_21627147.host, call_21627147.base,
                               call_21627147.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627147, uri, valid, _)

proc call*(call_21627148: Call_PostSubscribe_21627125; TopicArn: string;
          Protocol: string; Endpoint: string = ""; Attributes0Value: string = "";
          Attributes0Key: string = ""; Attributes1Key: string = "";
          ReturnSubscriptionArn: bool = false; Action: string = "Subscribe";
          Attributes2Value: string = ""; Attributes2Key: string = "";
          Version: string = "2010-03-31"; Attributes1Value: string = ""): Recallable =
  ## postSubscribe
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   Endpoint: string
  ##           : <p>The endpoint that you want to receive notifications. Endpoints vary by protocol:</p> <ul> <li> <p>For the <code>http</code> protocol, the endpoint is an URL beginning with <code>http://</code> </p> </li> <li> <p>For the <code>https</code> protocol, the endpoint is a URL beginning with <code>https://</code> </p> </li> <li> <p>For the <code>email</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>email-json</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>sms</code> protocol, the endpoint is a phone number of an SMS-enabled device</p> </li> <li> <p>For the <code>sqs</code> protocol, the endpoint is the ARN of an Amazon SQS queue</p> </li> <li> <p>For the <code>application</code> protocol, the endpoint is the EndpointArn of a mobile app and device.</p> </li> <li> <p>For the <code>lambda</code> protocol, the endpoint is the ARN of an Amazon Lambda function.</p> </li> </ul>
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to subscribe to.
  ##   Attributes0Value: string
  ##   Protocol: string (required)
  ##           : <p>The protocol you want to use. Supported protocols include:</p> <ul> <li> <p> <code>http</code> – delivery of JSON-encoded message via HTTP POST</p> </li> <li> <p> <code>https</code> – delivery of JSON-encoded message via HTTPS POST</p> </li> <li> <p> <code>email</code> – delivery of message via SMTP</p> </li> <li> <p> <code>email-json</code> – delivery of JSON-encoded message via SMTP</p> </li> <li> <p> <code>sms</code> – delivery of message via SMS</p> </li> <li> <p> <code>sqs</code> – delivery of JSON-encoded message to an Amazon SQS queue</p> </li> <li> <p> <code>application</code> – delivery of JSON-encoded message to an EndpointArn for a mobile app and device.</p> </li> <li> <p> <code>lambda</code> – delivery of JSON-encoded message to an Amazon Lambda function.</p> </li> </ul>
  ##   Attributes0Key: string
  ##   Attributes1Key: string
  ##   ReturnSubscriptionArn: bool
  ##                        : <p>Sets whether the response from the <code>Subscribe</code> request includes the subscription ARN, even if the subscription is not yet confirmed.</p> <ul> <li> <p>If you have the subscription ARN returned, the response includes the ARN in all cases, even if the subscription is not yet confirmed.</p> </li> <li> <p>If you don't have the subscription ARN returned, in addition to the ARN for confirmed subscriptions, the response also includes the <code>pending subscription</code> ARN value for subscriptions that aren't yet confirmed. A subscription becomes confirmed when the subscriber calls the <code>ConfirmSubscription</code> action with a confirmation token.</p> </li> </ul> <p>If you set this parameter to <code>true</code>, .</p> <p>The default value is <code>false</code>.</p>
  ##   Action: string (required)
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_21627149 = newJObject()
  var formData_21627150 = newJObject()
  add(formData_21627150, "Endpoint", newJString(Endpoint))
  add(formData_21627150, "TopicArn", newJString(TopicArn))
  add(formData_21627150, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_21627150, "Protocol", newJString(Protocol))
  add(formData_21627150, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_21627150, "Attributes.1.key", newJString(Attributes1Key))
  add(formData_21627150, "ReturnSubscriptionArn", newJBool(ReturnSubscriptionArn))
  add(query_21627149, "Action", newJString(Action))
  add(formData_21627150, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_21627150, "Attributes.2.key", newJString(Attributes2Key))
  add(query_21627149, "Version", newJString(Version))
  add(formData_21627150, "Attributes.1.value", newJString(Attributes1Value))
  result = call_21627148.call(nil, query_21627149, nil, formData_21627150, nil)

var postSubscribe* = Call_PostSubscribe_21627125(name: "postSubscribe",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=Subscribe", validator: validate_PostSubscribe_21627126,
    base: "/", makeUrl: url_PostSubscribe_21627127,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSubscribe_21627100 = ref object of OpenApiRestCall_21625435
proc url_GetSubscribe_21627102(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSubscribe_21627101(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes.2.key: JString
  ##   Endpoint: JString
  ##           : <p>The endpoint that you want to receive notifications. Endpoints vary by protocol:</p> <ul> <li> <p>For the <code>http</code> protocol, the endpoint is an URL beginning with <code>http://</code> </p> </li> <li> <p>For the <code>https</code> protocol, the endpoint is a URL beginning with <code>https://</code> </p> </li> <li> <p>For the <code>email</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>email-json</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>sms</code> protocol, the endpoint is a phone number of an SMS-enabled device</p> </li> <li> <p>For the <code>sqs</code> protocol, the endpoint is the ARN of an Amazon SQS queue</p> </li> <li> <p>For the <code>application</code> protocol, the endpoint is the EndpointArn of a mobile app and device.</p> </li> <li> <p>For the <code>lambda</code> protocol, the endpoint is the ARN of an Amazon Lambda function.</p> </li> </ul>
  ##   Protocol: JString (required)
  ##           : <p>The protocol you want to use. Supported protocols include:</p> <ul> <li> <p> <code>http</code> – delivery of JSON-encoded message via HTTP POST</p> </li> <li> <p> <code>https</code> – delivery of JSON-encoded message via HTTPS POST</p> </li> <li> <p> <code>email</code> – delivery of message via SMTP</p> </li> <li> <p> <code>email-json</code> – delivery of JSON-encoded message via SMTP</p> </li> <li> <p> <code>sms</code> – delivery of message via SMS</p> </li> <li> <p> <code>sqs</code> – delivery of JSON-encoded message to an Amazon SQS queue</p> </li> <li> <p> <code>application</code> – delivery of JSON-encoded message to an EndpointArn for a mobile app and device.</p> </li> <li> <p> <code>lambda</code> – delivery of JSON-encoded message to an Amazon Lambda function.</p> </li> </ul>
  ##   Attributes.1.value: JString
  ##   Attributes.0.value: JString
  ##   Action: JString (required)
  ##   ReturnSubscriptionArn: JBool
  ##                        : <p>Sets whether the response from the <code>Subscribe</code> request includes the subscription ARN, even if the subscription is not yet confirmed.</p> <ul> <li> <p>If you have the subscription ARN returned, the response includes the ARN in all cases, even if the subscription is not yet confirmed.</p> </li> <li> <p>If you don't have the subscription ARN returned, in addition to the ARN for confirmed subscriptions, the response also includes the <code>pending subscription</code> ARN value for subscriptions that aren't yet confirmed. A subscription becomes confirmed when the subscriber calls the <code>ConfirmSubscription</code> action with a confirmation token.</p> </li> </ul> <p>If you set this parameter to <code>true</code>, .</p> <p>The default value is <code>false</code>.</p>
  ##   Attributes.1.key: JString
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic you want to subscribe to.
  ##   Attributes.2.value: JString
  ##   Attributes.0.key: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627103 = query.getOrDefault("Attributes.2.key")
  valid_21627103 = validateParameter(valid_21627103, JString, required = false,
                                   default = nil)
  if valid_21627103 != nil:
    section.add "Attributes.2.key", valid_21627103
  var valid_21627104 = query.getOrDefault("Endpoint")
  valid_21627104 = validateParameter(valid_21627104, JString, required = false,
                                   default = nil)
  if valid_21627104 != nil:
    section.add "Endpoint", valid_21627104
  assert query != nil,
        "query argument is necessary due to required `Protocol` field"
  var valid_21627105 = query.getOrDefault("Protocol")
  valid_21627105 = validateParameter(valid_21627105, JString, required = true,
                                   default = nil)
  if valid_21627105 != nil:
    section.add "Protocol", valid_21627105
  var valid_21627106 = query.getOrDefault("Attributes.1.value")
  valid_21627106 = validateParameter(valid_21627106, JString, required = false,
                                   default = nil)
  if valid_21627106 != nil:
    section.add "Attributes.1.value", valid_21627106
  var valid_21627107 = query.getOrDefault("Attributes.0.value")
  valid_21627107 = validateParameter(valid_21627107, JString, required = false,
                                   default = nil)
  if valid_21627107 != nil:
    section.add "Attributes.0.value", valid_21627107
  var valid_21627108 = query.getOrDefault("Action")
  valid_21627108 = validateParameter(valid_21627108, JString, required = true,
                                   default = newJString("Subscribe"))
  if valid_21627108 != nil:
    section.add "Action", valid_21627108
  var valid_21627109 = query.getOrDefault("ReturnSubscriptionArn")
  valid_21627109 = validateParameter(valid_21627109, JBool, required = false,
                                   default = nil)
  if valid_21627109 != nil:
    section.add "ReturnSubscriptionArn", valid_21627109
  var valid_21627110 = query.getOrDefault("Attributes.1.key")
  valid_21627110 = validateParameter(valid_21627110, JString, required = false,
                                   default = nil)
  if valid_21627110 != nil:
    section.add "Attributes.1.key", valid_21627110
  var valid_21627111 = query.getOrDefault("TopicArn")
  valid_21627111 = validateParameter(valid_21627111, JString, required = true,
                                   default = nil)
  if valid_21627111 != nil:
    section.add "TopicArn", valid_21627111
  var valid_21627112 = query.getOrDefault("Attributes.2.value")
  valid_21627112 = validateParameter(valid_21627112, JString, required = false,
                                   default = nil)
  if valid_21627112 != nil:
    section.add "Attributes.2.value", valid_21627112
  var valid_21627113 = query.getOrDefault("Attributes.0.key")
  valid_21627113 = validateParameter(valid_21627113, JString, required = false,
                                   default = nil)
  if valid_21627113 != nil:
    section.add "Attributes.0.key", valid_21627113
  var valid_21627114 = query.getOrDefault("Version")
  valid_21627114 = validateParameter(valid_21627114, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21627114 != nil:
    section.add "Version", valid_21627114
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627115 = header.getOrDefault("X-Amz-Date")
  valid_21627115 = validateParameter(valid_21627115, JString, required = false,
                                   default = nil)
  if valid_21627115 != nil:
    section.add "X-Amz-Date", valid_21627115
  var valid_21627116 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627116 = validateParameter(valid_21627116, JString, required = false,
                                   default = nil)
  if valid_21627116 != nil:
    section.add "X-Amz-Security-Token", valid_21627116
  var valid_21627117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627117 = validateParameter(valid_21627117, JString, required = false,
                                   default = nil)
  if valid_21627117 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627117
  var valid_21627118 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627118 = validateParameter(valid_21627118, JString, required = false,
                                   default = nil)
  if valid_21627118 != nil:
    section.add "X-Amz-Algorithm", valid_21627118
  var valid_21627119 = header.getOrDefault("X-Amz-Signature")
  valid_21627119 = validateParameter(valid_21627119, JString, required = false,
                                   default = nil)
  if valid_21627119 != nil:
    section.add "X-Amz-Signature", valid_21627119
  var valid_21627120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627120 = validateParameter(valid_21627120, JString, required = false,
                                   default = nil)
  if valid_21627120 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627120
  var valid_21627121 = header.getOrDefault("X-Amz-Credential")
  valid_21627121 = validateParameter(valid_21627121, JString, required = false,
                                   default = nil)
  if valid_21627121 != nil:
    section.add "X-Amz-Credential", valid_21627121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627122: Call_GetSubscribe_21627100; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_21627122.validator(path, query, header, formData, body, _)
  let scheme = call_21627122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627122.makeUrl(scheme.get, call_21627122.host, call_21627122.base,
                               call_21627122.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627122, uri, valid, _)

proc call*(call_21627123: Call_GetSubscribe_21627100; Protocol: string;
          TopicArn: string; Attributes2Key: string = ""; Endpoint: string = "";
          Attributes1Value: string = ""; Attributes0Value: string = "";
          Action: string = "Subscribe"; ReturnSubscriptionArn: bool = false;
          Attributes1Key: string = ""; Attributes2Value: string = "";
          Attributes0Key: string = ""; Version: string = "2010-03-31"): Recallable =
  ## getSubscribe
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   Attributes2Key: string
  ##   Endpoint: string
  ##           : <p>The endpoint that you want to receive notifications. Endpoints vary by protocol:</p> <ul> <li> <p>For the <code>http</code> protocol, the endpoint is an URL beginning with <code>http://</code> </p> </li> <li> <p>For the <code>https</code> protocol, the endpoint is a URL beginning with <code>https://</code> </p> </li> <li> <p>For the <code>email</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>email-json</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>sms</code> protocol, the endpoint is a phone number of an SMS-enabled device</p> </li> <li> <p>For the <code>sqs</code> protocol, the endpoint is the ARN of an Amazon SQS queue</p> </li> <li> <p>For the <code>application</code> protocol, the endpoint is the EndpointArn of a mobile app and device.</p> </li> <li> <p>For the <code>lambda</code> protocol, the endpoint is the ARN of an Amazon Lambda function.</p> </li> </ul>
  ##   Protocol: string (required)
  ##           : <p>The protocol you want to use. Supported protocols include:</p> <ul> <li> <p> <code>http</code> – delivery of JSON-encoded message via HTTP POST</p> </li> <li> <p> <code>https</code> – delivery of JSON-encoded message via HTTPS POST</p> </li> <li> <p> <code>email</code> – delivery of message via SMTP</p> </li> <li> <p> <code>email-json</code> – delivery of JSON-encoded message via SMTP</p> </li> <li> <p> <code>sms</code> – delivery of message via SMS</p> </li> <li> <p> <code>sqs</code> – delivery of JSON-encoded message to an Amazon SQS queue</p> </li> <li> <p> <code>application</code> – delivery of JSON-encoded message to an EndpointArn for a mobile app and device.</p> </li> <li> <p> <code>lambda</code> – delivery of JSON-encoded message to an Amazon Lambda function.</p> </li> </ul>
  ##   Attributes1Value: string
  ##   Attributes0Value: string
  ##   Action: string (required)
  ##   ReturnSubscriptionArn: bool
  ##                        : <p>Sets whether the response from the <code>Subscribe</code> request includes the subscription ARN, even if the subscription is not yet confirmed.</p> <ul> <li> <p>If you have the subscription ARN returned, the response includes the ARN in all cases, even if the subscription is not yet confirmed.</p> </li> <li> <p>If you don't have the subscription ARN returned, in addition to the ARN for confirmed subscriptions, the response also includes the <code>pending subscription</code> ARN value for subscriptions that aren't yet confirmed. A subscription becomes confirmed when the subscriber calls the <code>ConfirmSubscription</code> action with a confirmation token.</p> </li> </ul> <p>If you set this parameter to <code>true</code>, .</p> <p>The default value is <code>false</code>.</p>
  ##   Attributes1Key: string
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to subscribe to.
  ##   Attributes2Value: string
  ##   Attributes0Key: string
  ##   Version: string (required)
  var query_21627124 = newJObject()
  add(query_21627124, "Attributes.2.key", newJString(Attributes2Key))
  add(query_21627124, "Endpoint", newJString(Endpoint))
  add(query_21627124, "Protocol", newJString(Protocol))
  add(query_21627124, "Attributes.1.value", newJString(Attributes1Value))
  add(query_21627124, "Attributes.0.value", newJString(Attributes0Value))
  add(query_21627124, "Action", newJString(Action))
  add(query_21627124, "ReturnSubscriptionArn", newJBool(ReturnSubscriptionArn))
  add(query_21627124, "Attributes.1.key", newJString(Attributes1Key))
  add(query_21627124, "TopicArn", newJString(TopicArn))
  add(query_21627124, "Attributes.2.value", newJString(Attributes2Value))
  add(query_21627124, "Attributes.0.key", newJString(Attributes0Key))
  add(query_21627124, "Version", newJString(Version))
  result = call_21627123.call(nil, query_21627124, nil, nil, nil)

var getSubscribe* = Call_GetSubscribe_21627100(name: "getSubscribe",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=Subscribe", validator: validate_GetSubscribe_21627101,
    base: "/", makeUrl: url_GetSubscribe_21627102,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTagResource_21627168 = ref object of OpenApiRestCall_21625435
proc url_PostTagResource_21627170(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostTagResource_21627169(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account, per AWS region. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627171 = query.getOrDefault("Action")
  valid_21627171 = validateParameter(valid_21627171, JString, required = true,
                                   default = newJString("TagResource"))
  if valid_21627171 != nil:
    section.add "Action", valid_21627171
  var valid_21627172 = query.getOrDefault("Version")
  valid_21627172 = validateParameter(valid_21627172, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21627172 != nil:
    section.add "Version", valid_21627172
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627173 = header.getOrDefault("X-Amz-Date")
  valid_21627173 = validateParameter(valid_21627173, JString, required = false,
                                   default = nil)
  if valid_21627173 != nil:
    section.add "X-Amz-Date", valid_21627173
  var valid_21627174 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627174 = validateParameter(valid_21627174, JString, required = false,
                                   default = nil)
  if valid_21627174 != nil:
    section.add "X-Amz-Security-Token", valid_21627174
  var valid_21627175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627175 = validateParameter(valid_21627175, JString, required = false,
                                   default = nil)
  if valid_21627175 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627175
  var valid_21627176 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627176 = validateParameter(valid_21627176, JString, required = false,
                                   default = nil)
  if valid_21627176 != nil:
    section.add "X-Amz-Algorithm", valid_21627176
  var valid_21627177 = header.getOrDefault("X-Amz-Signature")
  valid_21627177 = validateParameter(valid_21627177, JString, required = false,
                                   default = nil)
  if valid_21627177 != nil:
    section.add "X-Amz-Signature", valid_21627177
  var valid_21627178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627178 = validateParameter(valid_21627178, JString, required = false,
                                   default = nil)
  if valid_21627178 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627178
  var valid_21627179 = header.getOrDefault("X-Amz-Credential")
  valid_21627179 = validateParameter(valid_21627179, JString, required = false,
                                   default = nil)
  if valid_21627179 != nil:
    section.add "X-Amz-Credential", valid_21627179
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##       : The tags to be added to the specified topic. A tag consists of a required key and an optional value.
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic to which to add tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_21627180 = formData.getOrDefault("Tags")
  valid_21627180 = validateParameter(valid_21627180, JArray, required = true,
                                   default = nil)
  if valid_21627180 != nil:
    section.add "Tags", valid_21627180
  var valid_21627181 = formData.getOrDefault("ResourceArn")
  valid_21627181 = validateParameter(valid_21627181, JString, required = true,
                                   default = nil)
  if valid_21627181 != nil:
    section.add "ResourceArn", valid_21627181
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627182: Call_PostTagResource_21627168; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account, per AWS region. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul>
  ## 
  let valid = call_21627182.validator(path, query, header, formData, body, _)
  let scheme = call_21627182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627182.makeUrl(scheme.get, call_21627182.host, call_21627182.base,
                               call_21627182.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627182, uri, valid, _)

proc call*(call_21627183: Call_PostTagResource_21627168; Tags: JsonNode;
          ResourceArn: string; Action: string = "TagResource";
          Version: string = "2010-03-31"): Recallable =
  ## postTagResource
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account, per AWS region. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul>
  ##   Tags: JArray (required)
  ##       : The tags to be added to the specified topic. A tag consists of a required key and an optional value.
  ##   Action: string (required)
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic to which to add tags.
  ##   Version: string (required)
  var query_21627184 = newJObject()
  var formData_21627185 = newJObject()
  if Tags != nil:
    formData_21627185.add "Tags", Tags
  add(query_21627184, "Action", newJString(Action))
  add(formData_21627185, "ResourceArn", newJString(ResourceArn))
  add(query_21627184, "Version", newJString(Version))
  result = call_21627183.call(nil, query_21627184, nil, formData_21627185, nil)

var postTagResource* = Call_PostTagResource_21627168(name: "postTagResource",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_PostTagResource_21627169,
    base: "/", makeUrl: url_PostTagResource_21627170,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagResource_21627151 = ref object of OpenApiRestCall_21625435
proc url_GetTagResource_21627153(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTagResource_21627152(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account, per AWS region. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul>
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
  var valid_21627154 = query.getOrDefault("ResourceArn")
  valid_21627154 = validateParameter(valid_21627154, JString, required = true,
                                   default = nil)
  if valid_21627154 != nil:
    section.add "ResourceArn", valid_21627154
  var valid_21627155 = query.getOrDefault("Tags")
  valid_21627155 = validateParameter(valid_21627155, JArray, required = true,
                                   default = nil)
  if valid_21627155 != nil:
    section.add "Tags", valid_21627155
  var valid_21627156 = query.getOrDefault("Action")
  valid_21627156 = validateParameter(valid_21627156, JString, required = true,
                                   default = newJString("TagResource"))
  if valid_21627156 != nil:
    section.add "Action", valid_21627156
  var valid_21627157 = query.getOrDefault("Version")
  valid_21627157 = validateParameter(valid_21627157, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21627157 != nil:
    section.add "Version", valid_21627157
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627158 = header.getOrDefault("X-Amz-Date")
  valid_21627158 = validateParameter(valid_21627158, JString, required = false,
                                   default = nil)
  if valid_21627158 != nil:
    section.add "X-Amz-Date", valid_21627158
  var valid_21627159 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627159 = validateParameter(valid_21627159, JString, required = false,
                                   default = nil)
  if valid_21627159 != nil:
    section.add "X-Amz-Security-Token", valid_21627159
  var valid_21627160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627160 = validateParameter(valid_21627160, JString, required = false,
                                   default = nil)
  if valid_21627160 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627160
  var valid_21627161 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627161 = validateParameter(valid_21627161, JString, required = false,
                                   default = nil)
  if valid_21627161 != nil:
    section.add "X-Amz-Algorithm", valid_21627161
  var valid_21627162 = header.getOrDefault("X-Amz-Signature")
  valid_21627162 = validateParameter(valid_21627162, JString, required = false,
                                   default = nil)
  if valid_21627162 != nil:
    section.add "X-Amz-Signature", valid_21627162
  var valid_21627163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627163 = validateParameter(valid_21627163, JString, required = false,
                                   default = nil)
  if valid_21627163 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627163
  var valid_21627164 = header.getOrDefault("X-Amz-Credential")
  valid_21627164 = validateParameter(valid_21627164, JString, required = false,
                                   default = nil)
  if valid_21627164 != nil:
    section.add "X-Amz-Credential", valid_21627164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627165: Call_GetTagResource_21627151; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account, per AWS region. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul>
  ## 
  let valid = call_21627165.validator(path, query, header, formData, body, _)
  let scheme = call_21627165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627165.makeUrl(scheme.get, call_21627165.host, call_21627165.base,
                               call_21627165.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627165, uri, valid, _)

proc call*(call_21627166: Call_GetTagResource_21627151; ResourceArn: string;
          Tags: JsonNode; Action: string = "TagResource";
          Version: string = "2010-03-31"): Recallable =
  ## getTagResource
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account, per AWS region. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul>
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic to which to add tags.
  ##   Tags: JArray (required)
  ##       : The tags to be added to the specified topic. A tag consists of a required key and an optional value.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627167 = newJObject()
  add(query_21627167, "ResourceArn", newJString(ResourceArn))
  if Tags != nil:
    query_21627167.add "Tags", Tags
  add(query_21627167, "Action", newJString(Action))
  add(query_21627167, "Version", newJString(Version))
  result = call_21627166.call(nil, query_21627167, nil, nil, nil)

var getTagResource* = Call_GetTagResource_21627151(name: "getTagResource",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_GetTagResource_21627152,
    base: "/", makeUrl: url_GetTagResource_21627153,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUnsubscribe_21627202 = ref object of OpenApiRestCall_21625435
proc url_PostUnsubscribe_21627204(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUnsubscribe_21627203(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627205 = query.getOrDefault("Action")
  valid_21627205 = validateParameter(valid_21627205, JString, required = true,
                                   default = newJString("Unsubscribe"))
  if valid_21627205 != nil:
    section.add "Action", valid_21627205
  var valid_21627206 = query.getOrDefault("Version")
  valid_21627206 = validateParameter(valid_21627206, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21627206 != nil:
    section.add "Version", valid_21627206
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627207 = header.getOrDefault("X-Amz-Date")
  valid_21627207 = validateParameter(valid_21627207, JString, required = false,
                                   default = nil)
  if valid_21627207 != nil:
    section.add "X-Amz-Date", valid_21627207
  var valid_21627208 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627208 = validateParameter(valid_21627208, JString, required = false,
                                   default = nil)
  if valid_21627208 != nil:
    section.add "X-Amz-Security-Token", valid_21627208
  var valid_21627209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627209 = validateParameter(valid_21627209, JString, required = false,
                                   default = nil)
  if valid_21627209 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627209
  var valid_21627210 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627210 = validateParameter(valid_21627210, JString, required = false,
                                   default = nil)
  if valid_21627210 != nil:
    section.add "X-Amz-Algorithm", valid_21627210
  var valid_21627211 = header.getOrDefault("X-Amz-Signature")
  valid_21627211 = validateParameter(valid_21627211, JString, required = false,
                                   default = nil)
  if valid_21627211 != nil:
    section.add "X-Amz-Signature", valid_21627211
  var valid_21627212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627212 = validateParameter(valid_21627212, JString, required = false,
                                   default = nil)
  if valid_21627212 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627212
  var valid_21627213 = header.getOrDefault("X-Amz-Credential")
  valid_21627213 = validateParameter(valid_21627213, JString, required = false,
                                   default = nil)
  if valid_21627213 != nil:
    section.add "X-Amz-Credential", valid_21627213
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription to be deleted.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionArn` field"
  var valid_21627214 = formData.getOrDefault("SubscriptionArn")
  valid_21627214 = validateParameter(valid_21627214, JString, required = true,
                                   default = nil)
  if valid_21627214 != nil:
    section.add "SubscriptionArn", valid_21627214
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627215: Call_PostUnsubscribe_21627202; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_21627215.validator(path, query, header, formData, body, _)
  let scheme = call_21627215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627215.makeUrl(scheme.get, call_21627215.host, call_21627215.base,
                               call_21627215.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627215, uri, valid, _)

proc call*(call_21627216: Call_PostUnsubscribe_21627202; SubscriptionArn: string;
          Action: string = "Unsubscribe"; Version: string = "2010-03-31"): Recallable =
  ## postUnsubscribe
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   Action: string (required)
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to be deleted.
  ##   Version: string (required)
  var query_21627217 = newJObject()
  var formData_21627218 = newJObject()
  add(query_21627217, "Action", newJString(Action))
  add(formData_21627218, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_21627217, "Version", newJString(Version))
  result = call_21627216.call(nil, query_21627217, nil, formData_21627218, nil)

var postUnsubscribe* = Call_PostUnsubscribe_21627202(name: "postUnsubscribe",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=Unsubscribe", validator: validate_PostUnsubscribe_21627203,
    base: "/", makeUrl: url_PostUnsubscribe_21627204,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUnsubscribe_21627186 = ref object of OpenApiRestCall_21625435
proc url_GetUnsubscribe_21627188(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUnsubscribe_21627187(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627189 = query.getOrDefault("SubscriptionArn")
  valid_21627189 = validateParameter(valid_21627189, JString, required = true,
                                   default = nil)
  if valid_21627189 != nil:
    section.add "SubscriptionArn", valid_21627189
  var valid_21627190 = query.getOrDefault("Action")
  valid_21627190 = validateParameter(valid_21627190, JString, required = true,
                                   default = newJString("Unsubscribe"))
  if valid_21627190 != nil:
    section.add "Action", valid_21627190
  var valid_21627191 = query.getOrDefault("Version")
  valid_21627191 = validateParameter(valid_21627191, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21627191 != nil:
    section.add "Version", valid_21627191
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627192 = header.getOrDefault("X-Amz-Date")
  valid_21627192 = validateParameter(valid_21627192, JString, required = false,
                                   default = nil)
  if valid_21627192 != nil:
    section.add "X-Amz-Date", valid_21627192
  var valid_21627193 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627193 = validateParameter(valid_21627193, JString, required = false,
                                   default = nil)
  if valid_21627193 != nil:
    section.add "X-Amz-Security-Token", valid_21627193
  var valid_21627194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627194 = validateParameter(valid_21627194, JString, required = false,
                                   default = nil)
  if valid_21627194 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627194
  var valid_21627195 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627195 = validateParameter(valid_21627195, JString, required = false,
                                   default = nil)
  if valid_21627195 != nil:
    section.add "X-Amz-Algorithm", valid_21627195
  var valid_21627196 = header.getOrDefault("X-Amz-Signature")
  valid_21627196 = validateParameter(valid_21627196, JString, required = false,
                                   default = nil)
  if valid_21627196 != nil:
    section.add "X-Amz-Signature", valid_21627196
  var valid_21627197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627197 = validateParameter(valid_21627197, JString, required = false,
                                   default = nil)
  if valid_21627197 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627197
  var valid_21627198 = header.getOrDefault("X-Amz-Credential")
  valid_21627198 = validateParameter(valid_21627198, JString, required = false,
                                   default = nil)
  if valid_21627198 != nil:
    section.add "X-Amz-Credential", valid_21627198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627199: Call_GetUnsubscribe_21627186; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_21627199.validator(path, query, header, formData, body, _)
  let scheme = call_21627199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627199.makeUrl(scheme.get, call_21627199.host, call_21627199.base,
                               call_21627199.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627199, uri, valid, _)

proc call*(call_21627200: Call_GetUnsubscribe_21627186; SubscriptionArn: string;
          Action: string = "Unsubscribe"; Version: string = "2010-03-31"): Recallable =
  ## getUnsubscribe
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to be deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627201 = newJObject()
  add(query_21627201, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_21627201, "Action", newJString(Action))
  add(query_21627201, "Version", newJString(Version))
  result = call_21627200.call(nil, query_21627201, nil, nil, nil)

var getUnsubscribe* = Call_GetUnsubscribe_21627186(name: "getUnsubscribe",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=Unsubscribe", validator: validate_GetUnsubscribe_21627187,
    base: "/", makeUrl: url_GetUnsubscribe_21627188,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUntagResource_21627236 = ref object of OpenApiRestCall_21625435
proc url_PostUntagResource_21627238(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUntagResource_21627237(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627239 = query.getOrDefault("Action")
  valid_21627239 = validateParameter(valid_21627239, JString, required = true,
                                   default = newJString("UntagResource"))
  if valid_21627239 != nil:
    section.add "Action", valid_21627239
  var valid_21627240 = query.getOrDefault("Version")
  valid_21627240 = validateParameter(valid_21627240, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21627240 != nil:
    section.add "Version", valid_21627240
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627241 = header.getOrDefault("X-Amz-Date")
  valid_21627241 = validateParameter(valid_21627241, JString, required = false,
                                   default = nil)
  if valid_21627241 != nil:
    section.add "X-Amz-Date", valid_21627241
  var valid_21627242 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627242 = validateParameter(valid_21627242, JString, required = false,
                                   default = nil)
  if valid_21627242 != nil:
    section.add "X-Amz-Security-Token", valid_21627242
  var valid_21627243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627243 = validateParameter(valid_21627243, JString, required = false,
                                   default = nil)
  if valid_21627243 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627243
  var valid_21627244 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627244 = validateParameter(valid_21627244, JString, required = false,
                                   default = nil)
  if valid_21627244 != nil:
    section.add "X-Amz-Algorithm", valid_21627244
  var valid_21627245 = header.getOrDefault("X-Amz-Signature")
  valid_21627245 = validateParameter(valid_21627245, JString, required = false,
                                   default = nil)
  if valid_21627245 != nil:
    section.add "X-Amz-Signature", valid_21627245
  var valid_21627246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627246 = validateParameter(valid_21627246, JString, required = false,
                                   default = nil)
  if valid_21627246 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627246
  var valid_21627247 = header.getOrDefault("X-Amz-Credential")
  valid_21627247 = validateParameter(valid_21627247, JString, required = false,
                                   default = nil)
  if valid_21627247 != nil:
    section.add "X-Amz-Credential", valid_21627247
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the specified topic.
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic from which to remove tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_21627248 = formData.getOrDefault("TagKeys")
  valid_21627248 = validateParameter(valid_21627248, JArray, required = true,
                                   default = nil)
  if valid_21627248 != nil:
    section.add "TagKeys", valid_21627248
  var valid_21627249 = formData.getOrDefault("ResourceArn")
  valid_21627249 = validateParameter(valid_21627249, JString, required = true,
                                   default = nil)
  if valid_21627249 != nil:
    section.add "ResourceArn", valid_21627249
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627250: Call_PostUntagResource_21627236; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  let valid = call_21627250.validator(path, query, header, formData, body, _)
  let scheme = call_21627250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627250.makeUrl(scheme.get, call_21627250.host, call_21627250.base,
                               call_21627250.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627250, uri, valid, _)

proc call*(call_21627251: Call_PostUntagResource_21627236; TagKeys: JsonNode;
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
  var query_21627252 = newJObject()
  var formData_21627253 = newJObject()
  add(query_21627252, "Action", newJString(Action))
  if TagKeys != nil:
    formData_21627253.add "TagKeys", TagKeys
  add(formData_21627253, "ResourceArn", newJString(ResourceArn))
  add(query_21627252, "Version", newJString(Version))
  result = call_21627251.call(nil, query_21627252, nil, formData_21627253, nil)

var postUntagResource* = Call_PostUntagResource_21627236(name: "postUntagResource",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_PostUntagResource_21627237,
    base: "/", makeUrl: url_PostUntagResource_21627238,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUntagResource_21627219 = ref object of OpenApiRestCall_21625435
proc url_GetUntagResource_21627221(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUntagResource_21627220(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627222 = query.getOrDefault("ResourceArn")
  valid_21627222 = validateParameter(valid_21627222, JString, required = true,
                                   default = nil)
  if valid_21627222 != nil:
    section.add "ResourceArn", valid_21627222
  var valid_21627223 = query.getOrDefault("Action")
  valid_21627223 = validateParameter(valid_21627223, JString, required = true,
                                   default = newJString("UntagResource"))
  if valid_21627223 != nil:
    section.add "Action", valid_21627223
  var valid_21627224 = query.getOrDefault("TagKeys")
  valid_21627224 = validateParameter(valid_21627224, JArray, required = true,
                                   default = nil)
  if valid_21627224 != nil:
    section.add "TagKeys", valid_21627224
  var valid_21627225 = query.getOrDefault("Version")
  valid_21627225 = validateParameter(valid_21627225, JString, required = true,
                                   default = newJString("2010-03-31"))
  if valid_21627225 != nil:
    section.add "Version", valid_21627225
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627226 = header.getOrDefault("X-Amz-Date")
  valid_21627226 = validateParameter(valid_21627226, JString, required = false,
                                   default = nil)
  if valid_21627226 != nil:
    section.add "X-Amz-Date", valid_21627226
  var valid_21627227 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627227 = validateParameter(valid_21627227, JString, required = false,
                                   default = nil)
  if valid_21627227 != nil:
    section.add "X-Amz-Security-Token", valid_21627227
  var valid_21627228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627228 = validateParameter(valid_21627228, JString, required = false,
                                   default = nil)
  if valid_21627228 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627228
  var valid_21627229 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627229 = validateParameter(valid_21627229, JString, required = false,
                                   default = nil)
  if valid_21627229 != nil:
    section.add "X-Amz-Algorithm", valid_21627229
  var valid_21627230 = header.getOrDefault("X-Amz-Signature")
  valid_21627230 = validateParameter(valid_21627230, JString, required = false,
                                   default = nil)
  if valid_21627230 != nil:
    section.add "X-Amz-Signature", valid_21627230
  var valid_21627231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627231 = validateParameter(valid_21627231, JString, required = false,
                                   default = nil)
  if valid_21627231 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627231
  var valid_21627232 = header.getOrDefault("X-Amz-Credential")
  valid_21627232 = validateParameter(valid_21627232, JString, required = false,
                                   default = nil)
  if valid_21627232 != nil:
    section.add "X-Amz-Credential", valid_21627232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627233: Call_GetUntagResource_21627219; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  let valid = call_21627233.validator(path, query, header, formData, body, _)
  let scheme = call_21627233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627233.makeUrl(scheme.get, call_21627233.host, call_21627233.base,
                               call_21627233.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627233, uri, valid, _)

proc call*(call_21627234: Call_GetUntagResource_21627219; ResourceArn: string;
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
  var query_21627235 = newJObject()
  add(query_21627235, "ResourceArn", newJString(ResourceArn))
  add(query_21627235, "Action", newJString(Action))
  if TagKeys != nil:
    query_21627235.add "TagKeys", TagKeys
  add(query_21627235, "Version", newJString(Version))
  result = call_21627234.call(nil, query_21627235, nil, nil, nil)

var getUntagResource* = Call_GetUntagResource_21627219(name: "getUntagResource",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_GetUntagResource_21627220,
    base: "/", makeUrl: url_GetUntagResource_21627221,
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