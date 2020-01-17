
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostAddPermission_606201 = ref object of OpenApiRestCall_605589
proc url_PostAddPermission_606203(protocol: Scheme; host: string; base: string;
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

proc validate_PostAddPermission_606202(path: JsonNode; query: JsonNode;
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
  var valid_606204 = query.getOrDefault("Action")
  valid_606204 = validateParameter(valid_606204, JString, required = true,
                                 default = newJString("AddPermission"))
  if valid_606204 != nil:
    section.add "Action", valid_606204
  var valid_606205 = query.getOrDefault("Version")
  valid_606205 = validateParameter(valid_606205, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606205 != nil:
    section.add "Version", valid_606205
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606206 = header.getOrDefault("X-Amz-Signature")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Signature", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-Content-Sha256", valid_606207
  var valid_606208 = header.getOrDefault("X-Amz-Date")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-Date", valid_606208
  var valid_606209 = header.getOrDefault("X-Amz-Credential")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-Credential", valid_606209
  var valid_606210 = header.getOrDefault("X-Amz-Security-Token")
  valid_606210 = validateParameter(valid_606210, JString, required = false,
                                 default = nil)
  if valid_606210 != nil:
    section.add "X-Amz-Security-Token", valid_606210
  var valid_606211 = header.getOrDefault("X-Amz-Algorithm")
  valid_606211 = validateParameter(valid_606211, JString, required = false,
                                 default = nil)
  if valid_606211 != nil:
    section.add "X-Amz-Algorithm", valid_606211
  var valid_606212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606212 = validateParameter(valid_606212, JString, required = false,
                                 default = nil)
  if valid_606212 != nil:
    section.add "X-Amz-SignedHeaders", valid_606212
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
  var valid_606213 = formData.getOrDefault("TopicArn")
  valid_606213 = validateParameter(valid_606213, JString, required = true,
                                 default = nil)
  if valid_606213 != nil:
    section.add "TopicArn", valid_606213
  var valid_606214 = formData.getOrDefault("AWSAccountId")
  valid_606214 = validateParameter(valid_606214, JArray, required = true, default = nil)
  if valid_606214 != nil:
    section.add "AWSAccountId", valid_606214
  var valid_606215 = formData.getOrDefault("Label")
  valid_606215 = validateParameter(valid_606215, JString, required = true,
                                 default = nil)
  if valid_606215 != nil:
    section.add "Label", valid_606215
  var valid_606216 = formData.getOrDefault("ActionName")
  valid_606216 = validateParameter(valid_606216, JArray, required = true, default = nil)
  if valid_606216 != nil:
    section.add "ActionName", valid_606216
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606217: Call_PostAddPermission_606201; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  let valid = call_606217.validator(path, query, header, formData, body)
  let scheme = call_606217.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606217.url(scheme.get, call_606217.host, call_606217.base,
                         call_606217.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606217, url, valid)

proc call*(call_606218: Call_PostAddPermission_606201; TopicArn: string;
          AWSAccountId: JsonNode; Label: string; ActionName: JsonNode;
          Action: string = "AddPermission"; Version: string = "2010-03-31"): Recallable =
  ## postAddPermission
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Action: string (required)
  ##   AWSAccountId: JArray (required)
  ##               : The AWS account IDs of the users (principals) who will be given access to the specified actions. The users must have AWS accounts, but do not need to be signed up for this service.
  ##   Label: string (required)
  ##        : A unique identifier for the new policy statement.
  ##   ActionName: JArray (required)
  ##             : <p>The action you want to allow for the specified principal(s).</p> <p>Valid values: Any Amazon SNS action name, for example <code>Publish</code>.</p>
  ##   Version: string (required)
  var query_606219 = newJObject()
  var formData_606220 = newJObject()
  add(formData_606220, "TopicArn", newJString(TopicArn))
  add(query_606219, "Action", newJString(Action))
  if AWSAccountId != nil:
    formData_606220.add "AWSAccountId", AWSAccountId
  add(formData_606220, "Label", newJString(Label))
  if ActionName != nil:
    formData_606220.add "ActionName", ActionName
  add(query_606219, "Version", newJString(Version))
  result = call_606218.call(nil, query_606219, nil, formData_606220, nil)

var postAddPermission* = Call_PostAddPermission_606201(name: "postAddPermission",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=AddPermission", validator: validate_PostAddPermission_606202,
    base: "/", url: url_PostAddPermission_606203,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddPermission_605927 = ref object of OpenApiRestCall_605589
proc url_GetAddPermission_605929(protocol: Scheme; host: string; base: string;
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

proc validate_GetAddPermission_605928(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Action: JString (required)
  ##   ActionName: JArray (required)
  ##             : <p>The action you want to allow for the specified principal(s).</p> <p>Valid values: Any Amazon SNS action name, for example <code>Publish</code>.</p>
  ##   Version: JString (required)
  ##   AWSAccountId: JArray (required)
  ##               : The AWS account IDs of the users (principals) who will be given access to the specified actions. The users must have AWS accounts, but do not need to be signed up for this service.
  ##   Label: JString (required)
  ##        : A unique identifier for the new policy statement.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `TopicArn` field"
  var valid_606041 = query.getOrDefault("TopicArn")
  valid_606041 = validateParameter(valid_606041, JString, required = true,
                                 default = nil)
  if valid_606041 != nil:
    section.add "TopicArn", valid_606041
  var valid_606055 = query.getOrDefault("Action")
  valid_606055 = validateParameter(valid_606055, JString, required = true,
                                 default = newJString("AddPermission"))
  if valid_606055 != nil:
    section.add "Action", valid_606055
  var valid_606056 = query.getOrDefault("ActionName")
  valid_606056 = validateParameter(valid_606056, JArray, required = true, default = nil)
  if valid_606056 != nil:
    section.add "ActionName", valid_606056
  var valid_606057 = query.getOrDefault("Version")
  valid_606057 = validateParameter(valid_606057, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606057 != nil:
    section.add "Version", valid_606057
  var valid_606058 = query.getOrDefault("AWSAccountId")
  valid_606058 = validateParameter(valid_606058, JArray, required = true, default = nil)
  if valid_606058 != nil:
    section.add "AWSAccountId", valid_606058
  var valid_606059 = query.getOrDefault("Label")
  valid_606059 = validateParameter(valid_606059, JString, required = true,
                                 default = nil)
  if valid_606059 != nil:
    section.add "Label", valid_606059
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606060 = header.getOrDefault("X-Amz-Signature")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Signature", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-Content-Sha256", valid_606061
  var valid_606062 = header.getOrDefault("X-Amz-Date")
  valid_606062 = validateParameter(valid_606062, JString, required = false,
                                 default = nil)
  if valid_606062 != nil:
    section.add "X-Amz-Date", valid_606062
  var valid_606063 = header.getOrDefault("X-Amz-Credential")
  valid_606063 = validateParameter(valid_606063, JString, required = false,
                                 default = nil)
  if valid_606063 != nil:
    section.add "X-Amz-Credential", valid_606063
  var valid_606064 = header.getOrDefault("X-Amz-Security-Token")
  valid_606064 = validateParameter(valid_606064, JString, required = false,
                                 default = nil)
  if valid_606064 != nil:
    section.add "X-Amz-Security-Token", valid_606064
  var valid_606065 = header.getOrDefault("X-Amz-Algorithm")
  valid_606065 = validateParameter(valid_606065, JString, required = false,
                                 default = nil)
  if valid_606065 != nil:
    section.add "X-Amz-Algorithm", valid_606065
  var valid_606066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606066 = validateParameter(valid_606066, JString, required = false,
                                 default = nil)
  if valid_606066 != nil:
    section.add "X-Amz-SignedHeaders", valid_606066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606089: Call_GetAddPermission_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  let valid = call_606089.validator(path, query, header, formData, body)
  let scheme = call_606089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606089.url(scheme.get, call_606089.host, call_606089.base,
                         call_606089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606089, url, valid)

proc call*(call_606160: Call_GetAddPermission_605927; TopicArn: string;
          ActionName: JsonNode; AWSAccountId: JsonNode; Label: string;
          Action: string = "AddPermission"; Version: string = "2010-03-31"): Recallable =
  ## getAddPermission
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Action: string (required)
  ##   ActionName: JArray (required)
  ##             : <p>The action you want to allow for the specified principal(s).</p> <p>Valid values: Any Amazon SNS action name, for example <code>Publish</code>.</p>
  ##   Version: string (required)
  ##   AWSAccountId: JArray (required)
  ##               : The AWS account IDs of the users (principals) who will be given access to the specified actions. The users must have AWS accounts, but do not need to be signed up for this service.
  ##   Label: string (required)
  ##        : A unique identifier for the new policy statement.
  var query_606161 = newJObject()
  add(query_606161, "TopicArn", newJString(TopicArn))
  add(query_606161, "Action", newJString(Action))
  if ActionName != nil:
    query_606161.add "ActionName", ActionName
  add(query_606161, "Version", newJString(Version))
  if AWSAccountId != nil:
    query_606161.add "AWSAccountId", AWSAccountId
  add(query_606161, "Label", newJString(Label))
  result = call_606160.call(nil, query_606161, nil, nil, nil)

var getAddPermission* = Call_GetAddPermission_605927(name: "getAddPermission",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=AddPermission", validator: validate_GetAddPermission_605928,
    base: "/", url: url_GetAddPermission_605929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCheckIfPhoneNumberIsOptedOut_606237 = ref object of OpenApiRestCall_605589
proc url_PostCheckIfPhoneNumberIsOptedOut_606239(protocol: Scheme; host: string;
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

proc validate_PostCheckIfPhoneNumberIsOptedOut_606238(path: JsonNode;
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
  var valid_606240 = query.getOrDefault("Action")
  valid_606240 = validateParameter(valid_606240, JString, required = true, default = newJString(
      "CheckIfPhoneNumberIsOptedOut"))
  if valid_606240 != nil:
    section.add "Action", valid_606240
  var valid_606241 = query.getOrDefault("Version")
  valid_606241 = validateParameter(valid_606241, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606241 != nil:
    section.add "Version", valid_606241
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606242 = header.getOrDefault("X-Amz-Signature")
  valid_606242 = validateParameter(valid_606242, JString, required = false,
                                 default = nil)
  if valid_606242 != nil:
    section.add "X-Amz-Signature", valid_606242
  var valid_606243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606243 = validateParameter(valid_606243, JString, required = false,
                                 default = nil)
  if valid_606243 != nil:
    section.add "X-Amz-Content-Sha256", valid_606243
  var valid_606244 = header.getOrDefault("X-Amz-Date")
  valid_606244 = validateParameter(valid_606244, JString, required = false,
                                 default = nil)
  if valid_606244 != nil:
    section.add "X-Amz-Date", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-Credential")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-Credential", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-Security-Token")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Security-Token", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Algorithm")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Algorithm", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-SignedHeaders", valid_606248
  result.add "header", section
  ## parameters in `formData` object:
  ##   phoneNumber: JString (required)
  ##              : The phone number for which you want to check the opt out status.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `phoneNumber` field"
  var valid_606249 = formData.getOrDefault("phoneNumber")
  valid_606249 = validateParameter(valid_606249, JString, required = true,
                                 default = nil)
  if valid_606249 != nil:
    section.add "phoneNumber", valid_606249
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606250: Call_PostCheckIfPhoneNumberIsOptedOut_606237;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ## 
  let valid = call_606250.validator(path, query, header, formData, body)
  let scheme = call_606250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606250.url(scheme.get, call_606250.host, call_606250.base,
                         call_606250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606250, url, valid)

proc call*(call_606251: Call_PostCheckIfPhoneNumberIsOptedOut_606237;
          phoneNumber: string; Action: string = "CheckIfPhoneNumberIsOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## postCheckIfPhoneNumberIsOptedOut
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number for which you want to check the opt out status.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606252 = newJObject()
  var formData_606253 = newJObject()
  add(formData_606253, "phoneNumber", newJString(phoneNumber))
  add(query_606252, "Action", newJString(Action))
  add(query_606252, "Version", newJString(Version))
  result = call_606251.call(nil, query_606252, nil, formData_606253, nil)

var postCheckIfPhoneNumberIsOptedOut* = Call_PostCheckIfPhoneNumberIsOptedOut_606237(
    name: "postCheckIfPhoneNumberIsOptedOut", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CheckIfPhoneNumberIsOptedOut",
    validator: validate_PostCheckIfPhoneNumberIsOptedOut_606238, base: "/",
    url: url_PostCheckIfPhoneNumberIsOptedOut_606239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCheckIfPhoneNumberIsOptedOut_606221 = ref object of OpenApiRestCall_605589
proc url_GetCheckIfPhoneNumberIsOptedOut_606223(protocol: Scheme; host: string;
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

proc validate_GetCheckIfPhoneNumberIsOptedOut_606222(path: JsonNode;
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
  var valid_606224 = query.getOrDefault("phoneNumber")
  valid_606224 = validateParameter(valid_606224, JString, required = true,
                                 default = nil)
  if valid_606224 != nil:
    section.add "phoneNumber", valid_606224
  var valid_606225 = query.getOrDefault("Action")
  valid_606225 = validateParameter(valid_606225, JString, required = true, default = newJString(
      "CheckIfPhoneNumberIsOptedOut"))
  if valid_606225 != nil:
    section.add "Action", valid_606225
  var valid_606226 = query.getOrDefault("Version")
  valid_606226 = validateParameter(valid_606226, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606226 != nil:
    section.add "Version", valid_606226
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606227 = header.getOrDefault("X-Amz-Signature")
  valid_606227 = validateParameter(valid_606227, JString, required = false,
                                 default = nil)
  if valid_606227 != nil:
    section.add "X-Amz-Signature", valid_606227
  var valid_606228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606228 = validateParameter(valid_606228, JString, required = false,
                                 default = nil)
  if valid_606228 != nil:
    section.add "X-Amz-Content-Sha256", valid_606228
  var valid_606229 = header.getOrDefault("X-Amz-Date")
  valid_606229 = validateParameter(valid_606229, JString, required = false,
                                 default = nil)
  if valid_606229 != nil:
    section.add "X-Amz-Date", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-Credential")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-Credential", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-Security-Token")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-Security-Token", valid_606231
  var valid_606232 = header.getOrDefault("X-Amz-Algorithm")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Algorithm", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-SignedHeaders", valid_606233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606234: Call_GetCheckIfPhoneNumberIsOptedOut_606221;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ## 
  let valid = call_606234.validator(path, query, header, formData, body)
  let scheme = call_606234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606234.url(scheme.get, call_606234.host, call_606234.base,
                         call_606234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606234, url, valid)

proc call*(call_606235: Call_GetCheckIfPhoneNumberIsOptedOut_606221;
          phoneNumber: string; Action: string = "CheckIfPhoneNumberIsOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## getCheckIfPhoneNumberIsOptedOut
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number for which you want to check the opt out status.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606236 = newJObject()
  add(query_606236, "phoneNumber", newJString(phoneNumber))
  add(query_606236, "Action", newJString(Action))
  add(query_606236, "Version", newJString(Version))
  result = call_606235.call(nil, query_606236, nil, nil, nil)

var getCheckIfPhoneNumberIsOptedOut* = Call_GetCheckIfPhoneNumberIsOptedOut_606221(
    name: "getCheckIfPhoneNumberIsOptedOut", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CheckIfPhoneNumberIsOptedOut",
    validator: validate_GetCheckIfPhoneNumberIsOptedOut_606222, base: "/",
    url: url_GetCheckIfPhoneNumberIsOptedOut_606223,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostConfirmSubscription_606272 = ref object of OpenApiRestCall_605589
proc url_PostConfirmSubscription_606274(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_PostConfirmSubscription_606273(path: JsonNode; query: JsonNode;
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
  var valid_606275 = query.getOrDefault("Action")
  valid_606275 = validateParameter(valid_606275, JString, required = true,
                                 default = newJString("ConfirmSubscription"))
  if valid_606275 != nil:
    section.add "Action", valid_606275
  var valid_606276 = query.getOrDefault("Version")
  valid_606276 = validateParameter(valid_606276, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606276 != nil:
    section.add "Version", valid_606276
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606277 = header.getOrDefault("X-Amz-Signature")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Signature", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Content-Sha256", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Date")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Date", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Credential")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Credential", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-Security-Token")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-Security-Token", valid_606281
  var valid_606282 = header.getOrDefault("X-Amz-Algorithm")
  valid_606282 = validateParameter(valid_606282, JString, required = false,
                                 default = nil)
  if valid_606282 != nil:
    section.add "X-Amz-Algorithm", valid_606282
  var valid_606283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606283 = validateParameter(valid_606283, JString, required = false,
                                 default = nil)
  if valid_606283 != nil:
    section.add "X-Amz-SignedHeaders", valid_606283
  result.add "header", section
  ## parameters in `formData` object:
  ##   AuthenticateOnUnsubscribe: JString
  ##                            : Disallows unauthenticated unsubscribes of the subscription. If the value of this parameter is <code>true</code> and the request has an AWS signature, then only the topic owner and the subscription owner can unsubscribe the endpoint. The unsubscribe action requires AWS authentication. 
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic for which you wish to confirm a subscription.
  ##   Token: JString (required)
  ##        : Short-lived token sent to an endpoint during the <code>Subscribe</code> action.
  section = newJObject()
  var valid_606284 = formData.getOrDefault("AuthenticateOnUnsubscribe")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "AuthenticateOnUnsubscribe", valid_606284
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_606285 = formData.getOrDefault("TopicArn")
  valid_606285 = validateParameter(valid_606285, JString, required = true,
                                 default = nil)
  if valid_606285 != nil:
    section.add "TopicArn", valid_606285
  var valid_606286 = formData.getOrDefault("Token")
  valid_606286 = validateParameter(valid_606286, JString, required = true,
                                 default = nil)
  if valid_606286 != nil:
    section.add "Token", valid_606286
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606287: Call_PostConfirmSubscription_606272; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  let valid = call_606287.validator(path, query, header, formData, body)
  let scheme = call_606287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606287.url(scheme.get, call_606287.host, call_606287.base,
                         call_606287.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606287, url, valid)

proc call*(call_606288: Call_PostConfirmSubscription_606272; TopicArn: string;
          Token: string; AuthenticateOnUnsubscribe: string = "";
          Action: string = "ConfirmSubscription"; Version: string = "2010-03-31"): Recallable =
  ## postConfirmSubscription
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ##   AuthenticateOnUnsubscribe: string
  ##                            : Disallows unauthenticated unsubscribes of the subscription. If the value of this parameter is <code>true</code> and the request has an AWS signature, then only the topic owner and the subscription owner can unsubscribe the endpoint. The unsubscribe action requires AWS authentication. 
  ##   TopicArn: string (required)
  ##           : The ARN of the topic for which you wish to confirm a subscription.
  ##   Token: string (required)
  ##        : Short-lived token sent to an endpoint during the <code>Subscribe</code> action.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606289 = newJObject()
  var formData_606290 = newJObject()
  add(formData_606290, "AuthenticateOnUnsubscribe",
      newJString(AuthenticateOnUnsubscribe))
  add(formData_606290, "TopicArn", newJString(TopicArn))
  add(formData_606290, "Token", newJString(Token))
  add(query_606289, "Action", newJString(Action))
  add(query_606289, "Version", newJString(Version))
  result = call_606288.call(nil, query_606289, nil, formData_606290, nil)

var postConfirmSubscription* = Call_PostConfirmSubscription_606272(
    name: "postConfirmSubscription", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ConfirmSubscription",
    validator: validate_PostConfirmSubscription_606273, base: "/",
    url: url_PostConfirmSubscription_606274, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfirmSubscription_606254 = ref object of OpenApiRestCall_605589
proc url_GetConfirmSubscription_606256(protocol: Scheme; host: string; base: string;
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

proc validate_GetConfirmSubscription_606255(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   AuthenticateOnUnsubscribe: JString
  ##                            : Disallows unauthenticated unsubscribes of the subscription. If the value of this parameter is <code>true</code> and the request has an AWS signature, then only the topic owner and the subscription owner can unsubscribe the endpoint. The unsubscribe action requires AWS authentication. 
  ##   Token: JString (required)
  ##        : Short-lived token sent to an endpoint during the <code>Subscribe</code> action.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic for which you wish to confirm a subscription.
  section = newJObject()
  var valid_606257 = query.getOrDefault("AuthenticateOnUnsubscribe")
  valid_606257 = validateParameter(valid_606257, JString, required = false,
                                 default = nil)
  if valid_606257 != nil:
    section.add "AuthenticateOnUnsubscribe", valid_606257
  assert query != nil, "query argument is necessary due to required `Token` field"
  var valid_606258 = query.getOrDefault("Token")
  valid_606258 = validateParameter(valid_606258, JString, required = true,
                                 default = nil)
  if valid_606258 != nil:
    section.add "Token", valid_606258
  var valid_606259 = query.getOrDefault("Action")
  valid_606259 = validateParameter(valid_606259, JString, required = true,
                                 default = newJString("ConfirmSubscription"))
  if valid_606259 != nil:
    section.add "Action", valid_606259
  var valid_606260 = query.getOrDefault("Version")
  valid_606260 = validateParameter(valid_606260, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606260 != nil:
    section.add "Version", valid_606260
  var valid_606261 = query.getOrDefault("TopicArn")
  valid_606261 = validateParameter(valid_606261, JString, required = true,
                                 default = nil)
  if valid_606261 != nil:
    section.add "TopicArn", valid_606261
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606262 = header.getOrDefault("X-Amz-Signature")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Signature", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Content-Sha256", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Date")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Date", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Credential")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Credential", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-Security-Token")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-Security-Token", valid_606266
  var valid_606267 = header.getOrDefault("X-Amz-Algorithm")
  valid_606267 = validateParameter(valid_606267, JString, required = false,
                                 default = nil)
  if valid_606267 != nil:
    section.add "X-Amz-Algorithm", valid_606267
  var valid_606268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606268 = validateParameter(valid_606268, JString, required = false,
                                 default = nil)
  if valid_606268 != nil:
    section.add "X-Amz-SignedHeaders", valid_606268
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606269: Call_GetConfirmSubscription_606254; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  let valid = call_606269.validator(path, query, header, formData, body)
  let scheme = call_606269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606269.url(scheme.get, call_606269.host, call_606269.base,
                         call_606269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606269, url, valid)

proc call*(call_606270: Call_GetConfirmSubscription_606254; Token: string;
          TopicArn: string; AuthenticateOnUnsubscribe: string = "";
          Action: string = "ConfirmSubscription"; Version: string = "2010-03-31"): Recallable =
  ## getConfirmSubscription
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ##   AuthenticateOnUnsubscribe: string
  ##                            : Disallows unauthenticated unsubscribes of the subscription. If the value of this parameter is <code>true</code> and the request has an AWS signature, then only the topic owner and the subscription owner can unsubscribe the endpoint. The unsubscribe action requires AWS authentication. 
  ##   Token: string (required)
  ##        : Short-lived token sent to an endpoint during the <code>Subscribe</code> action.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic for which you wish to confirm a subscription.
  var query_606271 = newJObject()
  add(query_606271, "AuthenticateOnUnsubscribe",
      newJString(AuthenticateOnUnsubscribe))
  add(query_606271, "Token", newJString(Token))
  add(query_606271, "Action", newJString(Action))
  add(query_606271, "Version", newJString(Version))
  add(query_606271, "TopicArn", newJString(TopicArn))
  result = call_606270.call(nil, query_606271, nil, nil, nil)

var getConfirmSubscription* = Call_GetConfirmSubscription_606254(
    name: "getConfirmSubscription", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ConfirmSubscription",
    validator: validate_GetConfirmSubscription_606255, base: "/",
    url: url_GetConfirmSubscription_606256, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformApplication_606314 = ref object of OpenApiRestCall_605589
proc url_PostCreatePlatformApplication_606316(protocol: Scheme; host: string;
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

proc validate_PostCreatePlatformApplication_606315(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606317 = query.getOrDefault("Action")
  valid_606317 = validateParameter(valid_606317, JString, required = true, default = newJString(
      "CreatePlatformApplication"))
  if valid_606317 != nil:
    section.add "Action", valid_606317
  var valid_606318 = query.getOrDefault("Version")
  valid_606318 = validateParameter(valid_606318, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606318 != nil:
    section.add "Version", valid_606318
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606319 = header.getOrDefault("X-Amz-Signature")
  valid_606319 = validateParameter(valid_606319, JString, required = false,
                                 default = nil)
  if valid_606319 != nil:
    section.add "X-Amz-Signature", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-Content-Sha256", valid_606320
  var valid_606321 = header.getOrDefault("X-Amz-Date")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Date", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-Credential")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-Credential", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Security-Token")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Security-Token", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Algorithm")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Algorithm", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-SignedHeaders", valid_606325
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes.0.key: JString
  ##   Platform: JString (required)
  ##           : The following platforms are supported: ADM (Amazon Device Messaging), APNS (Apple Push Notification Service), APNS_SANDBOX, and FCM (Firebase Cloud Messaging).
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   Attributes.0.value: JString
  ##   Attributes.1.key: JString
  ##   Name: JString (required)
  ##       : Application names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, hyphens, and periods, and must be between 1 and 256 characters long.
  ##   Attributes.1.value: JString
  section = newJObject()
  var valid_606326 = formData.getOrDefault("Attributes.0.key")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "Attributes.0.key", valid_606326
  assert formData != nil,
        "formData argument is necessary due to required `Platform` field"
  var valid_606327 = formData.getOrDefault("Platform")
  valid_606327 = validateParameter(valid_606327, JString, required = true,
                                 default = nil)
  if valid_606327 != nil:
    section.add "Platform", valid_606327
  var valid_606328 = formData.getOrDefault("Attributes.2.value")
  valid_606328 = validateParameter(valid_606328, JString, required = false,
                                 default = nil)
  if valid_606328 != nil:
    section.add "Attributes.2.value", valid_606328
  var valid_606329 = formData.getOrDefault("Attributes.2.key")
  valid_606329 = validateParameter(valid_606329, JString, required = false,
                                 default = nil)
  if valid_606329 != nil:
    section.add "Attributes.2.key", valid_606329
  var valid_606330 = formData.getOrDefault("Attributes.0.value")
  valid_606330 = validateParameter(valid_606330, JString, required = false,
                                 default = nil)
  if valid_606330 != nil:
    section.add "Attributes.0.value", valid_606330
  var valid_606331 = formData.getOrDefault("Attributes.1.key")
  valid_606331 = validateParameter(valid_606331, JString, required = false,
                                 default = nil)
  if valid_606331 != nil:
    section.add "Attributes.1.key", valid_606331
  var valid_606332 = formData.getOrDefault("Name")
  valid_606332 = validateParameter(valid_606332, JString, required = true,
                                 default = nil)
  if valid_606332 != nil:
    section.add "Name", valid_606332
  var valid_606333 = formData.getOrDefault("Attributes.1.value")
  valid_606333 = validateParameter(valid_606333, JString, required = false,
                                 default = nil)
  if valid_606333 != nil:
    section.add "Attributes.1.value", valid_606333
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606334: Call_PostCreatePlatformApplication_606314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For FCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For FCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action.</p>
  ## 
  let valid = call_606334.validator(path, query, header, formData, body)
  let scheme = call_606334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606334.url(scheme.get, call_606334.host, call_606334.base,
                         call_606334.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606334, url, valid)

proc call*(call_606335: Call_PostCreatePlatformApplication_606314;
          Platform: string; Name: string; Attributes0Key: string = "";
          Attributes2Value: string = ""; Attributes2Key: string = "";
          Attributes0Value: string = ""; Attributes1Key: string = "";
          Action: string = "CreatePlatformApplication";
          Version: string = "2010-03-31"; Attributes1Value: string = ""): Recallable =
  ## postCreatePlatformApplication
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For FCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For FCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action.</p>
  ##   Attributes0Key: string
  ##   Platform: string (required)
  ##           : The following platforms are supported: ADM (Amazon Device Messaging), APNS (Apple Push Notification Service), APNS_SANDBOX, and FCM (Firebase Cloud Messaging).
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   Attributes0Value: string
  ##   Attributes1Key: string
  ##   Action: string (required)
  ##   Name: string (required)
  ##       : Application names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, hyphens, and periods, and must be between 1 and 256 characters long.
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_606336 = newJObject()
  var formData_606337 = newJObject()
  add(formData_606337, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_606337, "Platform", newJString(Platform))
  add(formData_606337, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_606337, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_606337, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_606337, "Attributes.1.key", newJString(Attributes1Key))
  add(query_606336, "Action", newJString(Action))
  add(formData_606337, "Name", newJString(Name))
  add(query_606336, "Version", newJString(Version))
  add(formData_606337, "Attributes.1.value", newJString(Attributes1Value))
  result = call_606335.call(nil, query_606336, nil, formData_606337, nil)

var postCreatePlatformApplication* = Call_PostCreatePlatformApplication_606314(
    name: "postCreatePlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformApplication",
    validator: validate_PostCreatePlatformApplication_606315, base: "/",
    url: url_PostCreatePlatformApplication_606316,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformApplication_606291 = ref object of OpenApiRestCall_605589
proc url_GetCreatePlatformApplication_606293(protocol: Scheme; host: string;
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

proc validate_GetCreatePlatformApplication_606292(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For FCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For FCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes.1.key: JString
  ##   Attributes.0.value: JString
  ##   Attributes.0.key: JString
  ##   Platform: JString (required)
  ##           : The following platforms are supported: ADM (Amazon Device Messaging), APNS (Apple Push Notification Service), APNS_SANDBOX, and FCM (Firebase Cloud Messaging).
  ##   Attributes.2.value: JString
  ##   Attributes.1.value: JString
  ##   Name: JString (required)
  ##       : Application names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, hyphens, and periods, and must be between 1 and 256 characters long.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Attributes.2.key: JString
  section = newJObject()
  var valid_606294 = query.getOrDefault("Attributes.1.key")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "Attributes.1.key", valid_606294
  var valid_606295 = query.getOrDefault("Attributes.0.value")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "Attributes.0.value", valid_606295
  var valid_606296 = query.getOrDefault("Attributes.0.key")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "Attributes.0.key", valid_606296
  assert query != nil,
        "query argument is necessary due to required `Platform` field"
  var valid_606297 = query.getOrDefault("Platform")
  valid_606297 = validateParameter(valid_606297, JString, required = true,
                                 default = nil)
  if valid_606297 != nil:
    section.add "Platform", valid_606297
  var valid_606298 = query.getOrDefault("Attributes.2.value")
  valid_606298 = validateParameter(valid_606298, JString, required = false,
                                 default = nil)
  if valid_606298 != nil:
    section.add "Attributes.2.value", valid_606298
  var valid_606299 = query.getOrDefault("Attributes.1.value")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "Attributes.1.value", valid_606299
  var valid_606300 = query.getOrDefault("Name")
  valid_606300 = validateParameter(valid_606300, JString, required = true,
                                 default = nil)
  if valid_606300 != nil:
    section.add "Name", valid_606300
  var valid_606301 = query.getOrDefault("Action")
  valid_606301 = validateParameter(valid_606301, JString, required = true, default = newJString(
      "CreatePlatformApplication"))
  if valid_606301 != nil:
    section.add "Action", valid_606301
  var valid_606302 = query.getOrDefault("Version")
  valid_606302 = validateParameter(valid_606302, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606302 != nil:
    section.add "Version", valid_606302
  var valid_606303 = query.getOrDefault("Attributes.2.key")
  valid_606303 = validateParameter(valid_606303, JString, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "Attributes.2.key", valid_606303
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606304 = header.getOrDefault("X-Amz-Signature")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "X-Amz-Signature", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Content-Sha256", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Date")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Date", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Credential")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Credential", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Security-Token")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Security-Token", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-Algorithm")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Algorithm", valid_606309
  var valid_606310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-SignedHeaders", valid_606310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606311: Call_GetCreatePlatformApplication_606291; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For FCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For FCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action.</p>
  ## 
  let valid = call_606311.validator(path, query, header, formData, body)
  let scheme = call_606311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606311.url(scheme.get, call_606311.host, call_606311.base,
                         call_606311.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606311, url, valid)

proc call*(call_606312: Call_GetCreatePlatformApplication_606291; Platform: string;
          Name: string; Attributes1Key: string = ""; Attributes0Value: string = "";
          Attributes0Key: string = ""; Attributes2Value: string = "";
          Attributes1Value: string = "";
          Action: string = "CreatePlatformApplication";
          Version: string = "2010-03-31"; Attributes2Key: string = ""): Recallable =
  ## getCreatePlatformApplication
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For FCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For FCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action.</p>
  ##   Attributes1Key: string
  ##   Attributes0Value: string
  ##   Attributes0Key: string
  ##   Platform: string (required)
  ##           : The following platforms are supported: ADM (Amazon Device Messaging), APNS (Apple Push Notification Service), APNS_SANDBOX, and FCM (Firebase Cloud Messaging).
  ##   Attributes2Value: string
  ##   Attributes1Value: string
  ##   Name: string (required)
  ##       : Application names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, hyphens, and periods, and must be between 1 and 256 characters long.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Attributes2Key: string
  var query_606313 = newJObject()
  add(query_606313, "Attributes.1.key", newJString(Attributes1Key))
  add(query_606313, "Attributes.0.value", newJString(Attributes0Value))
  add(query_606313, "Attributes.0.key", newJString(Attributes0Key))
  add(query_606313, "Platform", newJString(Platform))
  add(query_606313, "Attributes.2.value", newJString(Attributes2Value))
  add(query_606313, "Attributes.1.value", newJString(Attributes1Value))
  add(query_606313, "Name", newJString(Name))
  add(query_606313, "Action", newJString(Action))
  add(query_606313, "Version", newJString(Version))
  add(query_606313, "Attributes.2.key", newJString(Attributes2Key))
  result = call_606312.call(nil, query_606313, nil, nil, nil)

var getCreatePlatformApplication* = Call_GetCreatePlatformApplication_606291(
    name: "getCreatePlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformApplication",
    validator: validate_GetCreatePlatformApplication_606292, base: "/",
    url: url_GetCreatePlatformApplication_606293,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformEndpoint_606362 = ref object of OpenApiRestCall_605589
proc url_PostCreatePlatformEndpoint_606364(protocol: Scheme; host: string;
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

proc validate_PostCreatePlatformEndpoint_606363(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606365 = query.getOrDefault("Action")
  valid_606365 = validateParameter(valid_606365, JString, required = true,
                                 default = newJString("CreatePlatformEndpoint"))
  if valid_606365 != nil:
    section.add "Action", valid_606365
  var valid_606366 = query.getOrDefault("Version")
  valid_606366 = validateParameter(valid_606366, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606366 != nil:
    section.add "Version", valid_606366
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606367 = header.getOrDefault("X-Amz-Signature")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Signature", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-Content-Sha256", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-Date")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-Date", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-Credential")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-Credential", valid_606370
  var valid_606371 = header.getOrDefault("X-Amz-Security-Token")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "X-Amz-Security-Token", valid_606371
  var valid_606372 = header.getOrDefault("X-Amz-Algorithm")
  valid_606372 = validateParameter(valid_606372, JString, required = false,
                                 default = nil)
  if valid_606372 != nil:
    section.add "X-Amz-Algorithm", valid_606372
  var valid_606373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606373 = validateParameter(valid_606373, JString, required = false,
                                 default = nil)
  if valid_606373 != nil:
    section.add "X-Amz-SignedHeaders", valid_606373
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn returned from CreatePlatformApplication is used to create a an endpoint.
  ##   CustomUserData: JString
  ##                 : Arbitrary user data to associate with the endpoint. Amazon SNS does not use this data. The data must be in UTF-8 format and less than 2KB.
  ##   Attributes.0.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   Attributes.0.value: JString
  ##   Attributes.1.key: JString
  ##   Token: JString (required)
  ##        : Unique identifier created by the notification service for an app on a device. The specific name for Token will vary, depending on which notification service is being used. For example, when using APNS as the notification service, you need the device token. Alternatively, when using FCM or ADM, the device token equivalent is called the registration ID.
  ##   Attributes.1.value: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_606374 = formData.getOrDefault("PlatformApplicationArn")
  valid_606374 = validateParameter(valid_606374, JString, required = true,
                                 default = nil)
  if valid_606374 != nil:
    section.add "PlatformApplicationArn", valid_606374
  var valid_606375 = formData.getOrDefault("CustomUserData")
  valid_606375 = validateParameter(valid_606375, JString, required = false,
                                 default = nil)
  if valid_606375 != nil:
    section.add "CustomUserData", valid_606375
  var valid_606376 = formData.getOrDefault("Attributes.0.key")
  valid_606376 = validateParameter(valid_606376, JString, required = false,
                                 default = nil)
  if valid_606376 != nil:
    section.add "Attributes.0.key", valid_606376
  var valid_606377 = formData.getOrDefault("Attributes.2.value")
  valid_606377 = validateParameter(valid_606377, JString, required = false,
                                 default = nil)
  if valid_606377 != nil:
    section.add "Attributes.2.value", valid_606377
  var valid_606378 = formData.getOrDefault("Attributes.2.key")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "Attributes.2.key", valid_606378
  var valid_606379 = formData.getOrDefault("Attributes.0.value")
  valid_606379 = validateParameter(valid_606379, JString, required = false,
                                 default = nil)
  if valid_606379 != nil:
    section.add "Attributes.0.value", valid_606379
  var valid_606380 = formData.getOrDefault("Attributes.1.key")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "Attributes.1.key", valid_606380
  var valid_606381 = formData.getOrDefault("Token")
  valid_606381 = validateParameter(valid_606381, JString, required = true,
                                 default = nil)
  if valid_606381 != nil:
    section.add "Token", valid_606381
  var valid_606382 = formData.getOrDefault("Attributes.1.value")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "Attributes.1.value", valid_606382
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606383: Call_PostCreatePlatformEndpoint_606362; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as FCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  let valid = call_606383.validator(path, query, header, formData, body)
  let scheme = call_606383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606383.url(scheme.get, call_606383.host, call_606383.base,
                         call_606383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606383, url, valid)

proc call*(call_606384: Call_PostCreatePlatformEndpoint_606362;
          PlatformApplicationArn: string; Token: string;
          CustomUserData: string = ""; Attributes0Key: string = "";
          Attributes2Value: string = ""; Attributes2Key: string = "";
          Attributes0Value: string = ""; Attributes1Key: string = "";
          Action: string = "CreatePlatformEndpoint"; Version: string = "2010-03-31";
          Attributes1Value: string = ""): Recallable =
  ## postCreatePlatformEndpoint
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as FCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn returned from CreatePlatformApplication is used to create a an endpoint.
  ##   CustomUserData: string
  ##                 : Arbitrary user data to associate with the endpoint. Amazon SNS does not use this data. The data must be in UTF-8 format and less than 2KB.
  ##   Attributes0Key: string
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   Attributes0Value: string
  ##   Attributes1Key: string
  ##   Token: string (required)
  ##        : Unique identifier created by the notification service for an app on a device. The specific name for Token will vary, depending on which notification service is being used. For example, when using APNS as the notification service, you need the device token. Alternatively, when using FCM or ADM, the device token equivalent is called the registration ID.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_606385 = newJObject()
  var formData_606386 = newJObject()
  add(formData_606386, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(formData_606386, "CustomUserData", newJString(CustomUserData))
  add(formData_606386, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_606386, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_606386, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_606386, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_606386, "Attributes.1.key", newJString(Attributes1Key))
  add(formData_606386, "Token", newJString(Token))
  add(query_606385, "Action", newJString(Action))
  add(query_606385, "Version", newJString(Version))
  add(formData_606386, "Attributes.1.value", newJString(Attributes1Value))
  result = call_606384.call(nil, query_606385, nil, formData_606386, nil)

var postCreatePlatformEndpoint* = Call_PostCreatePlatformEndpoint_606362(
    name: "postCreatePlatformEndpoint", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformEndpoint",
    validator: validate_PostCreatePlatformEndpoint_606363, base: "/",
    url: url_PostCreatePlatformEndpoint_606364,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformEndpoint_606338 = ref object of OpenApiRestCall_605589
proc url_GetCreatePlatformEndpoint_606340(protocol: Scheme; host: string;
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

proc validate_GetCreatePlatformEndpoint_606339(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as FCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes.1.key: JString
  ##   CustomUserData: JString
  ##                 : Arbitrary user data to associate with the endpoint. Amazon SNS does not use this data. The data must be in UTF-8 format and less than 2KB.
  ##   Attributes.0.value: JString
  ##   Attributes.0.key: JString
  ##   Attributes.2.value: JString
  ##   Token: JString (required)
  ##        : Unique identifier created by the notification service for an app on a device. The specific name for Token will vary, depending on which notification service is being used. For example, when using APNS as the notification service, you need the device token. Alternatively, when using FCM or ADM, the device token equivalent is called the registration ID.
  ##   Attributes.1.value: JString
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn returned from CreatePlatformApplication is used to create a an endpoint.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Attributes.2.key: JString
  section = newJObject()
  var valid_606341 = query.getOrDefault("Attributes.1.key")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "Attributes.1.key", valid_606341
  var valid_606342 = query.getOrDefault("CustomUserData")
  valid_606342 = validateParameter(valid_606342, JString, required = false,
                                 default = nil)
  if valid_606342 != nil:
    section.add "CustomUserData", valid_606342
  var valid_606343 = query.getOrDefault("Attributes.0.value")
  valid_606343 = validateParameter(valid_606343, JString, required = false,
                                 default = nil)
  if valid_606343 != nil:
    section.add "Attributes.0.value", valid_606343
  var valid_606344 = query.getOrDefault("Attributes.0.key")
  valid_606344 = validateParameter(valid_606344, JString, required = false,
                                 default = nil)
  if valid_606344 != nil:
    section.add "Attributes.0.key", valid_606344
  var valid_606345 = query.getOrDefault("Attributes.2.value")
  valid_606345 = validateParameter(valid_606345, JString, required = false,
                                 default = nil)
  if valid_606345 != nil:
    section.add "Attributes.2.value", valid_606345
  assert query != nil, "query argument is necessary due to required `Token` field"
  var valid_606346 = query.getOrDefault("Token")
  valid_606346 = validateParameter(valid_606346, JString, required = true,
                                 default = nil)
  if valid_606346 != nil:
    section.add "Token", valid_606346
  var valid_606347 = query.getOrDefault("Attributes.1.value")
  valid_606347 = validateParameter(valid_606347, JString, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "Attributes.1.value", valid_606347
  var valid_606348 = query.getOrDefault("PlatformApplicationArn")
  valid_606348 = validateParameter(valid_606348, JString, required = true,
                                 default = nil)
  if valid_606348 != nil:
    section.add "PlatformApplicationArn", valid_606348
  var valid_606349 = query.getOrDefault("Action")
  valid_606349 = validateParameter(valid_606349, JString, required = true,
                                 default = newJString("CreatePlatformEndpoint"))
  if valid_606349 != nil:
    section.add "Action", valid_606349
  var valid_606350 = query.getOrDefault("Version")
  valid_606350 = validateParameter(valid_606350, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606350 != nil:
    section.add "Version", valid_606350
  var valid_606351 = query.getOrDefault("Attributes.2.key")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "Attributes.2.key", valid_606351
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606352 = header.getOrDefault("X-Amz-Signature")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-Signature", valid_606352
  var valid_606353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-Content-Sha256", valid_606353
  var valid_606354 = header.getOrDefault("X-Amz-Date")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "X-Amz-Date", valid_606354
  var valid_606355 = header.getOrDefault("X-Amz-Credential")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-Credential", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-Security-Token")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-Security-Token", valid_606356
  var valid_606357 = header.getOrDefault("X-Amz-Algorithm")
  valid_606357 = validateParameter(valid_606357, JString, required = false,
                                 default = nil)
  if valid_606357 != nil:
    section.add "X-Amz-Algorithm", valid_606357
  var valid_606358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606358 = validateParameter(valid_606358, JString, required = false,
                                 default = nil)
  if valid_606358 != nil:
    section.add "X-Amz-SignedHeaders", valid_606358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606359: Call_GetCreatePlatformEndpoint_606338; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as FCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  let valid = call_606359.validator(path, query, header, formData, body)
  let scheme = call_606359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606359.url(scheme.get, call_606359.host, call_606359.base,
                         call_606359.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606359, url, valid)

proc call*(call_606360: Call_GetCreatePlatformEndpoint_606338; Token: string;
          PlatformApplicationArn: string; Attributes1Key: string = "";
          CustomUserData: string = ""; Attributes0Value: string = "";
          Attributes0Key: string = ""; Attributes2Value: string = "";
          Attributes1Value: string = ""; Action: string = "CreatePlatformEndpoint";
          Version: string = "2010-03-31"; Attributes2Key: string = ""): Recallable =
  ## getCreatePlatformEndpoint
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as FCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ##   Attributes1Key: string
  ##   CustomUserData: string
  ##                 : Arbitrary user data to associate with the endpoint. Amazon SNS does not use this data. The data must be in UTF-8 format and less than 2KB.
  ##   Attributes0Value: string
  ##   Attributes0Key: string
  ##   Attributes2Value: string
  ##   Token: string (required)
  ##        : Unique identifier created by the notification service for an app on a device. The specific name for Token will vary, depending on which notification service is being used. For example, when using APNS as the notification service, you need the device token. Alternatively, when using FCM or ADM, the device token equivalent is called the registration ID.
  ##   Attributes1Value: string
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn returned from CreatePlatformApplication is used to create a an endpoint.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Attributes2Key: string
  var query_606361 = newJObject()
  add(query_606361, "Attributes.1.key", newJString(Attributes1Key))
  add(query_606361, "CustomUserData", newJString(CustomUserData))
  add(query_606361, "Attributes.0.value", newJString(Attributes0Value))
  add(query_606361, "Attributes.0.key", newJString(Attributes0Key))
  add(query_606361, "Attributes.2.value", newJString(Attributes2Value))
  add(query_606361, "Token", newJString(Token))
  add(query_606361, "Attributes.1.value", newJString(Attributes1Value))
  add(query_606361, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  add(query_606361, "Action", newJString(Action))
  add(query_606361, "Version", newJString(Version))
  add(query_606361, "Attributes.2.key", newJString(Attributes2Key))
  result = call_606360.call(nil, query_606361, nil, nil, nil)

var getCreatePlatformEndpoint* = Call_GetCreatePlatformEndpoint_606338(
    name: "getCreatePlatformEndpoint", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformEndpoint",
    validator: validate_GetCreatePlatformEndpoint_606339, base: "/",
    url: url_GetCreatePlatformEndpoint_606340,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateTopic_606410 = ref object of OpenApiRestCall_605589
proc url_PostCreateTopic_606412(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateTopic_606411(path: JsonNode; query: JsonNode;
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
  var valid_606413 = query.getOrDefault("Action")
  valid_606413 = validateParameter(valid_606413, JString, required = true,
                                 default = newJString("CreateTopic"))
  if valid_606413 != nil:
    section.add "Action", valid_606413
  var valid_606414 = query.getOrDefault("Version")
  valid_606414 = validateParameter(valid_606414, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606414 != nil:
    section.add "Version", valid_606414
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606415 = header.getOrDefault("X-Amz-Signature")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-Signature", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-Content-Sha256", valid_606416
  var valid_606417 = header.getOrDefault("X-Amz-Date")
  valid_606417 = validateParameter(valid_606417, JString, required = false,
                                 default = nil)
  if valid_606417 != nil:
    section.add "X-Amz-Date", valid_606417
  var valid_606418 = header.getOrDefault("X-Amz-Credential")
  valid_606418 = validateParameter(valid_606418, JString, required = false,
                                 default = nil)
  if valid_606418 != nil:
    section.add "X-Amz-Credential", valid_606418
  var valid_606419 = header.getOrDefault("X-Amz-Security-Token")
  valid_606419 = validateParameter(valid_606419, JString, required = false,
                                 default = nil)
  if valid_606419 != nil:
    section.add "X-Amz-Security-Token", valid_606419
  var valid_606420 = header.getOrDefault("X-Amz-Algorithm")
  valid_606420 = validateParameter(valid_606420, JString, required = false,
                                 default = nil)
  if valid_606420 != nil:
    section.add "X-Amz-Algorithm", valid_606420
  var valid_606421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606421 = validateParameter(valid_606421, JString, required = false,
                                 default = nil)
  if valid_606421 != nil:
    section.add "X-Amz-SignedHeaders", valid_606421
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes.0.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   Attributes.0.value: JString
  ##   Attributes.1.key: JString
  ##   Name: JString (required)
  ##       : <p>The name of the topic you want to create.</p> <p>Constraints: Topic names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, and hyphens, and must be between 1 and 256 characters long.</p>
  ##   Tags: JArray
  ##       : <p>The list of tags to add to a new topic.</p> <note> <p>To be able to tag a topic on creation, you must have the <code>sns:CreateTopic</code> and <code>sns:TagResource</code> permissions.</p> </note>
  ##   Attributes.1.value: JString
  section = newJObject()
  var valid_606422 = formData.getOrDefault("Attributes.0.key")
  valid_606422 = validateParameter(valid_606422, JString, required = false,
                                 default = nil)
  if valid_606422 != nil:
    section.add "Attributes.0.key", valid_606422
  var valid_606423 = formData.getOrDefault("Attributes.2.value")
  valid_606423 = validateParameter(valid_606423, JString, required = false,
                                 default = nil)
  if valid_606423 != nil:
    section.add "Attributes.2.value", valid_606423
  var valid_606424 = formData.getOrDefault("Attributes.2.key")
  valid_606424 = validateParameter(valid_606424, JString, required = false,
                                 default = nil)
  if valid_606424 != nil:
    section.add "Attributes.2.key", valid_606424
  var valid_606425 = formData.getOrDefault("Attributes.0.value")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "Attributes.0.value", valid_606425
  var valid_606426 = formData.getOrDefault("Attributes.1.key")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "Attributes.1.key", valid_606426
  assert formData != nil,
        "formData argument is necessary due to required `Name` field"
  var valid_606427 = formData.getOrDefault("Name")
  valid_606427 = validateParameter(valid_606427, JString, required = true,
                                 default = nil)
  if valid_606427 != nil:
    section.add "Name", valid_606427
  var valid_606428 = formData.getOrDefault("Tags")
  valid_606428 = validateParameter(valid_606428, JArray, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "Tags", valid_606428
  var valid_606429 = formData.getOrDefault("Attributes.1.value")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "Attributes.1.value", valid_606429
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606430: Call_PostCreateTopic_606410; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  let valid = call_606430.validator(path, query, header, formData, body)
  let scheme = call_606430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606430.url(scheme.get, call_606430.host, call_606430.base,
                         call_606430.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606430, url, valid)

proc call*(call_606431: Call_PostCreateTopic_606410; Name: string;
          Attributes0Key: string = ""; Attributes2Value: string = "";
          Attributes2Key: string = ""; Attributes0Value: string = "";
          Attributes1Key: string = ""; Action: string = "CreateTopic";
          Tags: JsonNode = nil; Version: string = "2010-03-31";
          Attributes1Value: string = ""): Recallable =
  ## postCreateTopic
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ##   Attributes0Key: string
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   Attributes0Value: string
  ##   Attributes1Key: string
  ##   Action: string (required)
  ##   Name: string (required)
  ##       : <p>The name of the topic you want to create.</p> <p>Constraints: Topic names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, and hyphens, and must be between 1 and 256 characters long.</p>
  ##   Tags: JArray
  ##       : <p>The list of tags to add to a new topic.</p> <note> <p>To be able to tag a topic on creation, you must have the <code>sns:CreateTopic</code> and <code>sns:TagResource</code> permissions.</p> </note>
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_606432 = newJObject()
  var formData_606433 = newJObject()
  add(formData_606433, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_606433, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_606433, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_606433, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_606433, "Attributes.1.key", newJString(Attributes1Key))
  add(query_606432, "Action", newJString(Action))
  add(formData_606433, "Name", newJString(Name))
  if Tags != nil:
    formData_606433.add "Tags", Tags
  add(query_606432, "Version", newJString(Version))
  add(formData_606433, "Attributes.1.value", newJString(Attributes1Value))
  result = call_606431.call(nil, query_606432, nil, formData_606433, nil)

var postCreateTopic* = Call_PostCreateTopic_606410(name: "postCreateTopic",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=CreateTopic", validator: validate_PostCreateTopic_606411,
    base: "/", url: url_PostCreateTopic_606412, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateTopic_606387 = ref object of OpenApiRestCall_605589
proc url_GetCreateTopic_606389(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateTopic_606388(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes.1.key: JString
  ##   Attributes.0.value: JString
  ##   Attributes.0.key: JString
  ##   Tags: JArray
  ##       : <p>The list of tags to add to a new topic.</p> <note> <p>To be able to tag a topic on creation, you must have the <code>sns:CreateTopic</code> and <code>sns:TagResource</code> permissions.</p> </note>
  ##   Attributes.2.value: JString
  ##   Attributes.1.value: JString
  ##   Name: JString (required)
  ##       : <p>The name of the topic you want to create.</p> <p>Constraints: Topic names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, and hyphens, and must be between 1 and 256 characters long.</p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Attributes.2.key: JString
  section = newJObject()
  var valid_606390 = query.getOrDefault("Attributes.1.key")
  valid_606390 = validateParameter(valid_606390, JString, required = false,
                                 default = nil)
  if valid_606390 != nil:
    section.add "Attributes.1.key", valid_606390
  var valid_606391 = query.getOrDefault("Attributes.0.value")
  valid_606391 = validateParameter(valid_606391, JString, required = false,
                                 default = nil)
  if valid_606391 != nil:
    section.add "Attributes.0.value", valid_606391
  var valid_606392 = query.getOrDefault("Attributes.0.key")
  valid_606392 = validateParameter(valid_606392, JString, required = false,
                                 default = nil)
  if valid_606392 != nil:
    section.add "Attributes.0.key", valid_606392
  var valid_606393 = query.getOrDefault("Tags")
  valid_606393 = validateParameter(valid_606393, JArray, required = false,
                                 default = nil)
  if valid_606393 != nil:
    section.add "Tags", valid_606393
  var valid_606394 = query.getOrDefault("Attributes.2.value")
  valid_606394 = validateParameter(valid_606394, JString, required = false,
                                 default = nil)
  if valid_606394 != nil:
    section.add "Attributes.2.value", valid_606394
  var valid_606395 = query.getOrDefault("Attributes.1.value")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "Attributes.1.value", valid_606395
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_606396 = query.getOrDefault("Name")
  valid_606396 = validateParameter(valid_606396, JString, required = true,
                                 default = nil)
  if valid_606396 != nil:
    section.add "Name", valid_606396
  var valid_606397 = query.getOrDefault("Action")
  valid_606397 = validateParameter(valid_606397, JString, required = true,
                                 default = newJString("CreateTopic"))
  if valid_606397 != nil:
    section.add "Action", valid_606397
  var valid_606398 = query.getOrDefault("Version")
  valid_606398 = validateParameter(valid_606398, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606398 != nil:
    section.add "Version", valid_606398
  var valid_606399 = query.getOrDefault("Attributes.2.key")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "Attributes.2.key", valid_606399
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606400 = header.getOrDefault("X-Amz-Signature")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Signature", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-Content-Sha256", valid_606401
  var valid_606402 = header.getOrDefault("X-Amz-Date")
  valid_606402 = validateParameter(valid_606402, JString, required = false,
                                 default = nil)
  if valid_606402 != nil:
    section.add "X-Amz-Date", valid_606402
  var valid_606403 = header.getOrDefault("X-Amz-Credential")
  valid_606403 = validateParameter(valid_606403, JString, required = false,
                                 default = nil)
  if valid_606403 != nil:
    section.add "X-Amz-Credential", valid_606403
  var valid_606404 = header.getOrDefault("X-Amz-Security-Token")
  valid_606404 = validateParameter(valid_606404, JString, required = false,
                                 default = nil)
  if valid_606404 != nil:
    section.add "X-Amz-Security-Token", valid_606404
  var valid_606405 = header.getOrDefault("X-Amz-Algorithm")
  valid_606405 = validateParameter(valid_606405, JString, required = false,
                                 default = nil)
  if valid_606405 != nil:
    section.add "X-Amz-Algorithm", valid_606405
  var valid_606406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606406 = validateParameter(valid_606406, JString, required = false,
                                 default = nil)
  if valid_606406 != nil:
    section.add "X-Amz-SignedHeaders", valid_606406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606407: Call_GetCreateTopic_606387; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  let valid = call_606407.validator(path, query, header, formData, body)
  let scheme = call_606407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606407.url(scheme.get, call_606407.host, call_606407.base,
                         call_606407.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606407, url, valid)

proc call*(call_606408: Call_GetCreateTopic_606387; Name: string;
          Attributes1Key: string = ""; Attributes0Value: string = "";
          Attributes0Key: string = ""; Tags: JsonNode = nil;
          Attributes2Value: string = ""; Attributes1Value: string = "";
          Action: string = "CreateTopic"; Version: string = "2010-03-31";
          Attributes2Key: string = ""): Recallable =
  ## getCreateTopic
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ##   Attributes1Key: string
  ##   Attributes0Value: string
  ##   Attributes0Key: string
  ##   Tags: JArray
  ##       : <p>The list of tags to add to a new topic.</p> <note> <p>To be able to tag a topic on creation, you must have the <code>sns:CreateTopic</code> and <code>sns:TagResource</code> permissions.</p> </note>
  ##   Attributes2Value: string
  ##   Attributes1Value: string
  ##   Name: string (required)
  ##       : <p>The name of the topic you want to create.</p> <p>Constraints: Topic names must be made up of only uppercase and lowercase ASCII letters, numbers, underscores, and hyphens, and must be between 1 and 256 characters long.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Attributes2Key: string
  var query_606409 = newJObject()
  add(query_606409, "Attributes.1.key", newJString(Attributes1Key))
  add(query_606409, "Attributes.0.value", newJString(Attributes0Value))
  add(query_606409, "Attributes.0.key", newJString(Attributes0Key))
  if Tags != nil:
    query_606409.add "Tags", Tags
  add(query_606409, "Attributes.2.value", newJString(Attributes2Value))
  add(query_606409, "Attributes.1.value", newJString(Attributes1Value))
  add(query_606409, "Name", newJString(Name))
  add(query_606409, "Action", newJString(Action))
  add(query_606409, "Version", newJString(Version))
  add(query_606409, "Attributes.2.key", newJString(Attributes2Key))
  result = call_606408.call(nil, query_606409, nil, nil, nil)

var getCreateTopic* = Call_GetCreateTopic_606387(name: "getCreateTopic",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=CreateTopic", validator: validate_GetCreateTopic_606388,
    base: "/", url: url_GetCreateTopic_606389, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEndpoint_606450 = ref object of OpenApiRestCall_605589
proc url_PostDeleteEndpoint_606452(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteEndpoint_606451(path: JsonNode; query: JsonNode;
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
  var valid_606453 = query.getOrDefault("Action")
  valid_606453 = validateParameter(valid_606453, JString, required = true,
                                 default = newJString("DeleteEndpoint"))
  if valid_606453 != nil:
    section.add "Action", valid_606453
  var valid_606454 = query.getOrDefault("Version")
  valid_606454 = validateParameter(valid_606454, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606454 != nil:
    section.add "Version", valid_606454
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606455 = header.getOrDefault("X-Amz-Signature")
  valid_606455 = validateParameter(valid_606455, JString, required = false,
                                 default = nil)
  if valid_606455 != nil:
    section.add "X-Amz-Signature", valid_606455
  var valid_606456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606456 = validateParameter(valid_606456, JString, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "X-Amz-Content-Sha256", valid_606456
  var valid_606457 = header.getOrDefault("X-Amz-Date")
  valid_606457 = validateParameter(valid_606457, JString, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "X-Amz-Date", valid_606457
  var valid_606458 = header.getOrDefault("X-Amz-Credential")
  valid_606458 = validateParameter(valid_606458, JString, required = false,
                                 default = nil)
  if valid_606458 != nil:
    section.add "X-Amz-Credential", valid_606458
  var valid_606459 = header.getOrDefault("X-Amz-Security-Token")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "X-Amz-Security-Token", valid_606459
  var valid_606460 = header.getOrDefault("X-Amz-Algorithm")
  valid_606460 = validateParameter(valid_606460, JString, required = false,
                                 default = nil)
  if valid_606460 != nil:
    section.add "X-Amz-Algorithm", valid_606460
  var valid_606461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-SignedHeaders", valid_606461
  result.add "header", section
  ## parameters in `formData` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn of endpoint to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_606462 = formData.getOrDefault("EndpointArn")
  valid_606462 = validateParameter(valid_606462, JString, required = true,
                                 default = nil)
  if valid_606462 != nil:
    section.add "EndpointArn", valid_606462
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606463: Call_PostDeleteEndpoint_606450; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ## 
  let valid = call_606463.validator(path, query, header, formData, body)
  let scheme = call_606463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606463.url(scheme.get, call_606463.host, call_606463.base,
                         call_606463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606463, url, valid)

proc call*(call_606464: Call_PostDeleteEndpoint_606450; EndpointArn: string;
          Action: string = "DeleteEndpoint"; Version: string = "2010-03-31"): Recallable =
  ## postDeleteEndpoint
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ##   EndpointArn: string (required)
  ##              : EndpointArn of endpoint to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606465 = newJObject()
  var formData_606466 = newJObject()
  add(formData_606466, "EndpointArn", newJString(EndpointArn))
  add(query_606465, "Action", newJString(Action))
  add(query_606465, "Version", newJString(Version))
  result = call_606464.call(nil, query_606465, nil, formData_606466, nil)

var postDeleteEndpoint* = Call_PostDeleteEndpoint_606450(
    name: "postDeleteEndpoint", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=DeleteEndpoint",
    validator: validate_PostDeleteEndpoint_606451, base: "/",
    url: url_PostDeleteEndpoint_606452, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEndpoint_606434 = ref object of OpenApiRestCall_605589
proc url_GetDeleteEndpoint_606436(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteEndpoint_606435(path: JsonNode; query: JsonNode;
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
  ##   EndpointArn: JString (required)
  ##              : EndpointArn of endpoint to delete.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606437 = query.getOrDefault("Action")
  valid_606437 = validateParameter(valid_606437, JString, required = true,
                                 default = newJString("DeleteEndpoint"))
  if valid_606437 != nil:
    section.add "Action", valid_606437
  var valid_606438 = query.getOrDefault("EndpointArn")
  valid_606438 = validateParameter(valid_606438, JString, required = true,
                                 default = nil)
  if valid_606438 != nil:
    section.add "EndpointArn", valid_606438
  var valid_606439 = query.getOrDefault("Version")
  valid_606439 = validateParameter(valid_606439, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606439 != nil:
    section.add "Version", valid_606439
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606440 = header.getOrDefault("X-Amz-Signature")
  valid_606440 = validateParameter(valid_606440, JString, required = false,
                                 default = nil)
  if valid_606440 != nil:
    section.add "X-Amz-Signature", valid_606440
  var valid_606441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606441 = validateParameter(valid_606441, JString, required = false,
                                 default = nil)
  if valid_606441 != nil:
    section.add "X-Amz-Content-Sha256", valid_606441
  var valid_606442 = header.getOrDefault("X-Amz-Date")
  valid_606442 = validateParameter(valid_606442, JString, required = false,
                                 default = nil)
  if valid_606442 != nil:
    section.add "X-Amz-Date", valid_606442
  var valid_606443 = header.getOrDefault("X-Amz-Credential")
  valid_606443 = validateParameter(valid_606443, JString, required = false,
                                 default = nil)
  if valid_606443 != nil:
    section.add "X-Amz-Credential", valid_606443
  var valid_606444 = header.getOrDefault("X-Amz-Security-Token")
  valid_606444 = validateParameter(valid_606444, JString, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "X-Amz-Security-Token", valid_606444
  var valid_606445 = header.getOrDefault("X-Amz-Algorithm")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-Algorithm", valid_606445
  var valid_606446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-SignedHeaders", valid_606446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606447: Call_GetDeleteEndpoint_606434; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ## 
  let valid = call_606447.validator(path, query, header, formData, body)
  let scheme = call_606447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606447.url(scheme.get, call_606447.host, call_606447.base,
                         call_606447.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606447, url, valid)

proc call*(call_606448: Call_GetDeleteEndpoint_606434; EndpointArn: string;
          Action: string = "DeleteEndpoint"; Version: string = "2010-03-31"): Recallable =
  ## getDeleteEndpoint
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ##   Action: string (required)
  ##   EndpointArn: string (required)
  ##              : EndpointArn of endpoint to delete.
  ##   Version: string (required)
  var query_606449 = newJObject()
  add(query_606449, "Action", newJString(Action))
  add(query_606449, "EndpointArn", newJString(EndpointArn))
  add(query_606449, "Version", newJString(Version))
  result = call_606448.call(nil, query_606449, nil, nil, nil)

var getDeleteEndpoint* = Call_GetDeleteEndpoint_606434(name: "getDeleteEndpoint",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=DeleteEndpoint", validator: validate_GetDeleteEndpoint_606435,
    base: "/", url: url_GetDeleteEndpoint_606436,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeletePlatformApplication_606483 = ref object of OpenApiRestCall_605589
proc url_PostDeletePlatformApplication_606485(protocol: Scheme; host: string;
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

proc validate_PostDeletePlatformApplication_606484(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606486 = query.getOrDefault("Action")
  valid_606486 = validateParameter(valid_606486, JString, required = true, default = newJString(
      "DeletePlatformApplication"))
  if valid_606486 != nil:
    section.add "Action", valid_606486
  var valid_606487 = query.getOrDefault("Version")
  valid_606487 = validateParameter(valid_606487, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606487 != nil:
    section.add "Version", valid_606487
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606488 = header.getOrDefault("X-Amz-Signature")
  valid_606488 = validateParameter(valid_606488, JString, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "X-Amz-Signature", valid_606488
  var valid_606489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606489 = validateParameter(valid_606489, JString, required = false,
                                 default = nil)
  if valid_606489 != nil:
    section.add "X-Amz-Content-Sha256", valid_606489
  var valid_606490 = header.getOrDefault("X-Amz-Date")
  valid_606490 = validateParameter(valid_606490, JString, required = false,
                                 default = nil)
  if valid_606490 != nil:
    section.add "X-Amz-Date", valid_606490
  var valid_606491 = header.getOrDefault("X-Amz-Credential")
  valid_606491 = validateParameter(valid_606491, JString, required = false,
                                 default = nil)
  if valid_606491 != nil:
    section.add "X-Amz-Credential", valid_606491
  var valid_606492 = header.getOrDefault("X-Amz-Security-Token")
  valid_606492 = validateParameter(valid_606492, JString, required = false,
                                 default = nil)
  if valid_606492 != nil:
    section.add "X-Amz-Security-Token", valid_606492
  var valid_606493 = header.getOrDefault("X-Amz-Algorithm")
  valid_606493 = validateParameter(valid_606493, JString, required = false,
                                 default = nil)
  if valid_606493 != nil:
    section.add "X-Amz-Algorithm", valid_606493
  var valid_606494 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606494 = validateParameter(valid_606494, JString, required = false,
                                 default = nil)
  if valid_606494 != nil:
    section.add "X-Amz-SignedHeaders", valid_606494
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_606495 = formData.getOrDefault("PlatformApplicationArn")
  valid_606495 = validateParameter(valid_606495, JString, required = true,
                                 default = nil)
  if valid_606495 != nil:
    section.add "PlatformApplicationArn", valid_606495
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606496: Call_PostDeletePlatformApplication_606483; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_606496.validator(path, query, header, formData, body)
  let scheme = call_606496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606496.url(scheme.get, call_606496.host, call_606496.base,
                         call_606496.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606496, url, valid)

proc call*(call_606497: Call_PostDeletePlatformApplication_606483;
          PlatformApplicationArn: string;
          Action: string = "DeletePlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## postDeletePlatformApplication
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606498 = newJObject()
  var formData_606499 = newJObject()
  add(formData_606499, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(query_606498, "Action", newJString(Action))
  add(query_606498, "Version", newJString(Version))
  result = call_606497.call(nil, query_606498, nil, formData_606499, nil)

var postDeletePlatformApplication* = Call_PostDeletePlatformApplication_606483(
    name: "postDeletePlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=DeletePlatformApplication",
    validator: validate_PostDeletePlatformApplication_606484, base: "/",
    url: url_PostDeletePlatformApplication_606485,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeletePlatformApplication_606467 = ref object of OpenApiRestCall_605589
proc url_GetDeletePlatformApplication_606469(protocol: Scheme; host: string;
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

proc validate_GetDeletePlatformApplication_606468(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `PlatformApplicationArn` field"
  var valid_606470 = query.getOrDefault("PlatformApplicationArn")
  valid_606470 = validateParameter(valid_606470, JString, required = true,
                                 default = nil)
  if valid_606470 != nil:
    section.add "PlatformApplicationArn", valid_606470
  var valid_606471 = query.getOrDefault("Action")
  valid_606471 = validateParameter(valid_606471, JString, required = true, default = newJString(
      "DeletePlatformApplication"))
  if valid_606471 != nil:
    section.add "Action", valid_606471
  var valid_606472 = query.getOrDefault("Version")
  valid_606472 = validateParameter(valid_606472, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606472 != nil:
    section.add "Version", valid_606472
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606473 = header.getOrDefault("X-Amz-Signature")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "X-Amz-Signature", valid_606473
  var valid_606474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606474 = validateParameter(valid_606474, JString, required = false,
                                 default = nil)
  if valid_606474 != nil:
    section.add "X-Amz-Content-Sha256", valid_606474
  var valid_606475 = header.getOrDefault("X-Amz-Date")
  valid_606475 = validateParameter(valid_606475, JString, required = false,
                                 default = nil)
  if valid_606475 != nil:
    section.add "X-Amz-Date", valid_606475
  var valid_606476 = header.getOrDefault("X-Amz-Credential")
  valid_606476 = validateParameter(valid_606476, JString, required = false,
                                 default = nil)
  if valid_606476 != nil:
    section.add "X-Amz-Credential", valid_606476
  var valid_606477 = header.getOrDefault("X-Amz-Security-Token")
  valid_606477 = validateParameter(valid_606477, JString, required = false,
                                 default = nil)
  if valid_606477 != nil:
    section.add "X-Amz-Security-Token", valid_606477
  var valid_606478 = header.getOrDefault("X-Amz-Algorithm")
  valid_606478 = validateParameter(valid_606478, JString, required = false,
                                 default = nil)
  if valid_606478 != nil:
    section.add "X-Amz-Algorithm", valid_606478
  var valid_606479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606479 = validateParameter(valid_606479, JString, required = false,
                                 default = nil)
  if valid_606479 != nil:
    section.add "X-Amz-SignedHeaders", valid_606479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606480: Call_GetDeletePlatformApplication_606467; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_606480.validator(path, query, header, formData, body)
  let scheme = call_606480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606480.url(scheme.get, call_606480.host, call_606480.base,
                         call_606480.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606480, url, valid)

proc call*(call_606481: Call_GetDeletePlatformApplication_606467;
          PlatformApplicationArn: string;
          Action: string = "DeletePlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## getDeletePlatformApplication
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606482 = newJObject()
  add(query_606482, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  add(query_606482, "Action", newJString(Action))
  add(query_606482, "Version", newJString(Version))
  result = call_606481.call(nil, query_606482, nil, nil, nil)

var getDeletePlatformApplication* = Call_GetDeletePlatformApplication_606467(
    name: "getDeletePlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=DeletePlatformApplication",
    validator: validate_GetDeletePlatformApplication_606468, base: "/",
    url: url_GetDeletePlatformApplication_606469,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteTopic_606516 = ref object of OpenApiRestCall_605589
proc url_PostDeleteTopic_606518(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteTopic_606517(path: JsonNode; query: JsonNode;
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
  var valid_606519 = query.getOrDefault("Action")
  valid_606519 = validateParameter(valid_606519, JString, required = true,
                                 default = newJString("DeleteTopic"))
  if valid_606519 != nil:
    section.add "Action", valid_606519
  var valid_606520 = query.getOrDefault("Version")
  valid_606520 = validateParameter(valid_606520, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606520 != nil:
    section.add "Version", valid_606520
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606521 = header.getOrDefault("X-Amz-Signature")
  valid_606521 = validateParameter(valid_606521, JString, required = false,
                                 default = nil)
  if valid_606521 != nil:
    section.add "X-Amz-Signature", valid_606521
  var valid_606522 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606522 = validateParameter(valid_606522, JString, required = false,
                                 default = nil)
  if valid_606522 != nil:
    section.add "X-Amz-Content-Sha256", valid_606522
  var valid_606523 = header.getOrDefault("X-Amz-Date")
  valid_606523 = validateParameter(valid_606523, JString, required = false,
                                 default = nil)
  if valid_606523 != nil:
    section.add "X-Amz-Date", valid_606523
  var valid_606524 = header.getOrDefault("X-Amz-Credential")
  valid_606524 = validateParameter(valid_606524, JString, required = false,
                                 default = nil)
  if valid_606524 != nil:
    section.add "X-Amz-Credential", valid_606524
  var valid_606525 = header.getOrDefault("X-Amz-Security-Token")
  valid_606525 = validateParameter(valid_606525, JString, required = false,
                                 default = nil)
  if valid_606525 != nil:
    section.add "X-Amz-Security-Token", valid_606525
  var valid_606526 = header.getOrDefault("X-Amz-Algorithm")
  valid_606526 = validateParameter(valid_606526, JString, required = false,
                                 default = nil)
  if valid_606526 != nil:
    section.add "X-Amz-Algorithm", valid_606526
  var valid_606527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606527 = validateParameter(valid_606527, JString, required = false,
                                 default = nil)
  if valid_606527 != nil:
    section.add "X-Amz-SignedHeaders", valid_606527
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic you want to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_606528 = formData.getOrDefault("TopicArn")
  valid_606528 = validateParameter(valid_606528, JString, required = true,
                                 default = nil)
  if valid_606528 != nil:
    section.add "TopicArn", valid_606528
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606529: Call_PostDeleteTopic_606516; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ## 
  let valid = call_606529.validator(path, query, header, formData, body)
  let scheme = call_606529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606529.url(scheme.get, call_606529.host, call_606529.base,
                         call_606529.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606529, url, valid)

proc call*(call_606530: Call_PostDeleteTopic_606516; TopicArn: string;
          Action: string = "DeleteTopic"; Version: string = "2010-03-31"): Recallable =
  ## postDeleteTopic
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606531 = newJObject()
  var formData_606532 = newJObject()
  add(formData_606532, "TopicArn", newJString(TopicArn))
  add(query_606531, "Action", newJString(Action))
  add(query_606531, "Version", newJString(Version))
  result = call_606530.call(nil, query_606531, nil, formData_606532, nil)

var postDeleteTopic* = Call_PostDeleteTopic_606516(name: "postDeleteTopic",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=DeleteTopic", validator: validate_PostDeleteTopic_606517,
    base: "/", url: url_PostDeleteTopic_606518, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteTopic_606500 = ref object of OpenApiRestCall_605589
proc url_GetDeleteTopic_606502(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteTopic_606501(path: JsonNode; query: JsonNode;
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
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic you want to delete.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606503 = query.getOrDefault("Action")
  valid_606503 = validateParameter(valid_606503, JString, required = true,
                                 default = newJString("DeleteTopic"))
  if valid_606503 != nil:
    section.add "Action", valid_606503
  var valid_606504 = query.getOrDefault("Version")
  valid_606504 = validateParameter(valid_606504, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606504 != nil:
    section.add "Version", valid_606504
  var valid_606505 = query.getOrDefault("TopicArn")
  valid_606505 = validateParameter(valid_606505, JString, required = true,
                                 default = nil)
  if valid_606505 != nil:
    section.add "TopicArn", valid_606505
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606506 = header.getOrDefault("X-Amz-Signature")
  valid_606506 = validateParameter(valid_606506, JString, required = false,
                                 default = nil)
  if valid_606506 != nil:
    section.add "X-Amz-Signature", valid_606506
  var valid_606507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606507 = validateParameter(valid_606507, JString, required = false,
                                 default = nil)
  if valid_606507 != nil:
    section.add "X-Amz-Content-Sha256", valid_606507
  var valid_606508 = header.getOrDefault("X-Amz-Date")
  valid_606508 = validateParameter(valid_606508, JString, required = false,
                                 default = nil)
  if valid_606508 != nil:
    section.add "X-Amz-Date", valid_606508
  var valid_606509 = header.getOrDefault("X-Amz-Credential")
  valid_606509 = validateParameter(valid_606509, JString, required = false,
                                 default = nil)
  if valid_606509 != nil:
    section.add "X-Amz-Credential", valid_606509
  var valid_606510 = header.getOrDefault("X-Amz-Security-Token")
  valid_606510 = validateParameter(valid_606510, JString, required = false,
                                 default = nil)
  if valid_606510 != nil:
    section.add "X-Amz-Security-Token", valid_606510
  var valid_606511 = header.getOrDefault("X-Amz-Algorithm")
  valid_606511 = validateParameter(valid_606511, JString, required = false,
                                 default = nil)
  if valid_606511 != nil:
    section.add "X-Amz-Algorithm", valid_606511
  var valid_606512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606512 = validateParameter(valid_606512, JString, required = false,
                                 default = nil)
  if valid_606512 != nil:
    section.add "X-Amz-SignedHeaders", valid_606512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606513: Call_GetDeleteTopic_606500; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ## 
  let valid = call_606513.validator(path, query, header, formData, body)
  let scheme = call_606513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606513.url(scheme.get, call_606513.host, call_606513.base,
                         call_606513.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606513, url, valid)

proc call*(call_606514: Call_GetDeleteTopic_606500; TopicArn: string;
          Action: string = "DeleteTopic"; Version: string = "2010-03-31"): Recallable =
  ## getDeleteTopic
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to delete.
  var query_606515 = newJObject()
  add(query_606515, "Action", newJString(Action))
  add(query_606515, "Version", newJString(Version))
  add(query_606515, "TopicArn", newJString(TopicArn))
  result = call_606514.call(nil, query_606515, nil, nil, nil)

var getDeleteTopic* = Call_GetDeleteTopic_606500(name: "getDeleteTopic",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=DeleteTopic", validator: validate_GetDeleteTopic_606501,
    base: "/", url: url_GetDeleteTopic_606502, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetEndpointAttributes_606549 = ref object of OpenApiRestCall_605589
proc url_PostGetEndpointAttributes_606551(protocol: Scheme; host: string;
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

proc validate_PostGetEndpointAttributes_606550(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606552 = query.getOrDefault("Action")
  valid_606552 = validateParameter(valid_606552, JString, required = true,
                                 default = newJString("GetEndpointAttributes"))
  if valid_606552 != nil:
    section.add "Action", valid_606552
  var valid_606553 = query.getOrDefault("Version")
  valid_606553 = validateParameter(valid_606553, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606553 != nil:
    section.add "Version", valid_606553
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606554 = header.getOrDefault("X-Amz-Signature")
  valid_606554 = validateParameter(valid_606554, JString, required = false,
                                 default = nil)
  if valid_606554 != nil:
    section.add "X-Amz-Signature", valid_606554
  var valid_606555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606555 = validateParameter(valid_606555, JString, required = false,
                                 default = nil)
  if valid_606555 != nil:
    section.add "X-Amz-Content-Sha256", valid_606555
  var valid_606556 = header.getOrDefault("X-Amz-Date")
  valid_606556 = validateParameter(valid_606556, JString, required = false,
                                 default = nil)
  if valid_606556 != nil:
    section.add "X-Amz-Date", valid_606556
  var valid_606557 = header.getOrDefault("X-Amz-Credential")
  valid_606557 = validateParameter(valid_606557, JString, required = false,
                                 default = nil)
  if valid_606557 != nil:
    section.add "X-Amz-Credential", valid_606557
  var valid_606558 = header.getOrDefault("X-Amz-Security-Token")
  valid_606558 = validateParameter(valid_606558, JString, required = false,
                                 default = nil)
  if valid_606558 != nil:
    section.add "X-Amz-Security-Token", valid_606558
  var valid_606559 = header.getOrDefault("X-Amz-Algorithm")
  valid_606559 = validateParameter(valid_606559, JString, required = false,
                                 default = nil)
  if valid_606559 != nil:
    section.add "X-Amz-Algorithm", valid_606559
  var valid_606560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606560 = validateParameter(valid_606560, JString, required = false,
                                 default = nil)
  if valid_606560 != nil:
    section.add "X-Amz-SignedHeaders", valid_606560
  result.add "header", section
  ## parameters in `formData` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_606561 = formData.getOrDefault("EndpointArn")
  valid_606561 = validateParameter(valid_606561, JString, required = true,
                                 default = nil)
  if valid_606561 != nil:
    section.add "EndpointArn", valid_606561
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606562: Call_PostGetEndpointAttributes_606549; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_606562.validator(path, query, header, formData, body)
  let scheme = call_606562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606562.url(scheme.get, call_606562.host, call_606562.base,
                         call_606562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606562, url, valid)

proc call*(call_606563: Call_PostGetEndpointAttributes_606549; EndpointArn: string;
          Action: string = "GetEndpointAttributes"; Version: string = "2010-03-31"): Recallable =
  ## postGetEndpointAttributes
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   EndpointArn: string (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606564 = newJObject()
  var formData_606565 = newJObject()
  add(formData_606565, "EndpointArn", newJString(EndpointArn))
  add(query_606564, "Action", newJString(Action))
  add(query_606564, "Version", newJString(Version))
  result = call_606563.call(nil, query_606564, nil, formData_606565, nil)

var postGetEndpointAttributes* = Call_PostGetEndpointAttributes_606549(
    name: "postGetEndpointAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetEndpointAttributes",
    validator: validate_PostGetEndpointAttributes_606550, base: "/",
    url: url_PostGetEndpointAttributes_606551,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetEndpointAttributes_606533 = ref object of OpenApiRestCall_605589
proc url_GetGetEndpointAttributes_606535(protocol: Scheme; host: string;
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

proc validate_GetGetEndpointAttributes_606534(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   EndpointArn: JString (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606536 = query.getOrDefault("Action")
  valid_606536 = validateParameter(valid_606536, JString, required = true,
                                 default = newJString("GetEndpointAttributes"))
  if valid_606536 != nil:
    section.add "Action", valid_606536
  var valid_606537 = query.getOrDefault("EndpointArn")
  valid_606537 = validateParameter(valid_606537, JString, required = true,
                                 default = nil)
  if valid_606537 != nil:
    section.add "EndpointArn", valid_606537
  var valid_606538 = query.getOrDefault("Version")
  valid_606538 = validateParameter(valid_606538, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606538 != nil:
    section.add "Version", valid_606538
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606539 = header.getOrDefault("X-Amz-Signature")
  valid_606539 = validateParameter(valid_606539, JString, required = false,
                                 default = nil)
  if valid_606539 != nil:
    section.add "X-Amz-Signature", valid_606539
  var valid_606540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606540 = validateParameter(valid_606540, JString, required = false,
                                 default = nil)
  if valid_606540 != nil:
    section.add "X-Amz-Content-Sha256", valid_606540
  var valid_606541 = header.getOrDefault("X-Amz-Date")
  valid_606541 = validateParameter(valid_606541, JString, required = false,
                                 default = nil)
  if valid_606541 != nil:
    section.add "X-Amz-Date", valid_606541
  var valid_606542 = header.getOrDefault("X-Amz-Credential")
  valid_606542 = validateParameter(valid_606542, JString, required = false,
                                 default = nil)
  if valid_606542 != nil:
    section.add "X-Amz-Credential", valid_606542
  var valid_606543 = header.getOrDefault("X-Amz-Security-Token")
  valid_606543 = validateParameter(valid_606543, JString, required = false,
                                 default = nil)
  if valid_606543 != nil:
    section.add "X-Amz-Security-Token", valid_606543
  var valid_606544 = header.getOrDefault("X-Amz-Algorithm")
  valid_606544 = validateParameter(valid_606544, JString, required = false,
                                 default = nil)
  if valid_606544 != nil:
    section.add "X-Amz-Algorithm", valid_606544
  var valid_606545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606545 = validateParameter(valid_606545, JString, required = false,
                                 default = nil)
  if valid_606545 != nil:
    section.add "X-Amz-SignedHeaders", valid_606545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606546: Call_GetGetEndpointAttributes_606533; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_606546.validator(path, query, header, formData, body)
  let scheme = call_606546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606546.url(scheme.get, call_606546.host, call_606546.base,
                         call_606546.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606546, url, valid)

proc call*(call_606547: Call_GetGetEndpointAttributes_606533; EndpointArn: string;
          Action: string = "GetEndpointAttributes"; Version: string = "2010-03-31"): Recallable =
  ## getGetEndpointAttributes
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   EndpointArn: string (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  ##   Version: string (required)
  var query_606548 = newJObject()
  add(query_606548, "Action", newJString(Action))
  add(query_606548, "EndpointArn", newJString(EndpointArn))
  add(query_606548, "Version", newJString(Version))
  result = call_606547.call(nil, query_606548, nil, nil, nil)

var getGetEndpointAttributes* = Call_GetGetEndpointAttributes_606533(
    name: "getGetEndpointAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetEndpointAttributes",
    validator: validate_GetGetEndpointAttributes_606534, base: "/",
    url: url_GetGetEndpointAttributes_606535, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetPlatformApplicationAttributes_606582 = ref object of OpenApiRestCall_605589
proc url_PostGetPlatformApplicationAttributes_606584(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetPlatformApplicationAttributes_606583(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606585 = query.getOrDefault("Action")
  valid_606585 = validateParameter(valid_606585, JString, required = true, default = newJString(
      "GetPlatformApplicationAttributes"))
  if valid_606585 != nil:
    section.add "Action", valid_606585
  var valid_606586 = query.getOrDefault("Version")
  valid_606586 = validateParameter(valid_606586, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606586 != nil:
    section.add "Version", valid_606586
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606587 = header.getOrDefault("X-Amz-Signature")
  valid_606587 = validateParameter(valid_606587, JString, required = false,
                                 default = nil)
  if valid_606587 != nil:
    section.add "X-Amz-Signature", valid_606587
  var valid_606588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606588 = validateParameter(valid_606588, JString, required = false,
                                 default = nil)
  if valid_606588 != nil:
    section.add "X-Amz-Content-Sha256", valid_606588
  var valid_606589 = header.getOrDefault("X-Amz-Date")
  valid_606589 = validateParameter(valid_606589, JString, required = false,
                                 default = nil)
  if valid_606589 != nil:
    section.add "X-Amz-Date", valid_606589
  var valid_606590 = header.getOrDefault("X-Amz-Credential")
  valid_606590 = validateParameter(valid_606590, JString, required = false,
                                 default = nil)
  if valid_606590 != nil:
    section.add "X-Amz-Credential", valid_606590
  var valid_606591 = header.getOrDefault("X-Amz-Security-Token")
  valid_606591 = validateParameter(valid_606591, JString, required = false,
                                 default = nil)
  if valid_606591 != nil:
    section.add "X-Amz-Security-Token", valid_606591
  var valid_606592 = header.getOrDefault("X-Amz-Algorithm")
  valid_606592 = validateParameter(valid_606592, JString, required = false,
                                 default = nil)
  if valid_606592 != nil:
    section.add "X-Amz-Algorithm", valid_606592
  var valid_606593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606593 = validateParameter(valid_606593, JString, required = false,
                                 default = nil)
  if valid_606593 != nil:
    section.add "X-Amz-SignedHeaders", valid_606593
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_606594 = formData.getOrDefault("PlatformApplicationArn")
  valid_606594 = validateParameter(valid_606594, JString, required = true,
                                 default = nil)
  if valid_606594 != nil:
    section.add "PlatformApplicationArn", valid_606594
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606595: Call_PostGetPlatformApplicationAttributes_606582;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_606595.validator(path, query, header, formData, body)
  let scheme = call_606595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606595.url(scheme.get, call_606595.host, call_606595.base,
                         call_606595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606595, url, valid)

proc call*(call_606596: Call_PostGetPlatformApplicationAttributes_606582;
          PlatformApplicationArn: string;
          Action: string = "GetPlatformApplicationAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetPlatformApplicationAttributes
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606597 = newJObject()
  var formData_606598 = newJObject()
  add(formData_606598, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(query_606597, "Action", newJString(Action))
  add(query_606597, "Version", newJString(Version))
  result = call_606596.call(nil, query_606597, nil, formData_606598, nil)

var postGetPlatformApplicationAttributes* = Call_PostGetPlatformApplicationAttributes_606582(
    name: "postGetPlatformApplicationAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetPlatformApplicationAttributes",
    validator: validate_PostGetPlatformApplicationAttributes_606583, base: "/",
    url: url_PostGetPlatformApplicationAttributes_606584,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetPlatformApplicationAttributes_606566 = ref object of OpenApiRestCall_605589
proc url_GetGetPlatformApplicationAttributes_606568(protocol: Scheme; host: string;
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

proc validate_GetGetPlatformApplicationAttributes_606567(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `PlatformApplicationArn` field"
  var valid_606569 = query.getOrDefault("PlatformApplicationArn")
  valid_606569 = validateParameter(valid_606569, JString, required = true,
                                 default = nil)
  if valid_606569 != nil:
    section.add "PlatformApplicationArn", valid_606569
  var valid_606570 = query.getOrDefault("Action")
  valid_606570 = validateParameter(valid_606570, JString, required = true, default = newJString(
      "GetPlatformApplicationAttributes"))
  if valid_606570 != nil:
    section.add "Action", valid_606570
  var valid_606571 = query.getOrDefault("Version")
  valid_606571 = validateParameter(valid_606571, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606571 != nil:
    section.add "Version", valid_606571
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606572 = header.getOrDefault("X-Amz-Signature")
  valid_606572 = validateParameter(valid_606572, JString, required = false,
                                 default = nil)
  if valid_606572 != nil:
    section.add "X-Amz-Signature", valid_606572
  var valid_606573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606573 = validateParameter(valid_606573, JString, required = false,
                                 default = nil)
  if valid_606573 != nil:
    section.add "X-Amz-Content-Sha256", valid_606573
  var valid_606574 = header.getOrDefault("X-Amz-Date")
  valid_606574 = validateParameter(valid_606574, JString, required = false,
                                 default = nil)
  if valid_606574 != nil:
    section.add "X-Amz-Date", valid_606574
  var valid_606575 = header.getOrDefault("X-Amz-Credential")
  valid_606575 = validateParameter(valid_606575, JString, required = false,
                                 default = nil)
  if valid_606575 != nil:
    section.add "X-Amz-Credential", valid_606575
  var valid_606576 = header.getOrDefault("X-Amz-Security-Token")
  valid_606576 = validateParameter(valid_606576, JString, required = false,
                                 default = nil)
  if valid_606576 != nil:
    section.add "X-Amz-Security-Token", valid_606576
  var valid_606577 = header.getOrDefault("X-Amz-Algorithm")
  valid_606577 = validateParameter(valid_606577, JString, required = false,
                                 default = nil)
  if valid_606577 != nil:
    section.add "X-Amz-Algorithm", valid_606577
  var valid_606578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606578 = validateParameter(valid_606578, JString, required = false,
                                 default = nil)
  if valid_606578 != nil:
    section.add "X-Amz-SignedHeaders", valid_606578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606579: Call_GetGetPlatformApplicationAttributes_606566;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_606579.validator(path, query, header, formData, body)
  let scheme = call_606579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606579.url(scheme.get, call_606579.host, call_606579.base,
                         call_606579.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606579, url, valid)

proc call*(call_606580: Call_GetGetPlatformApplicationAttributes_606566;
          PlatformApplicationArn: string;
          Action: string = "GetPlatformApplicationAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getGetPlatformApplicationAttributes
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606581 = newJObject()
  add(query_606581, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  add(query_606581, "Action", newJString(Action))
  add(query_606581, "Version", newJString(Version))
  result = call_606580.call(nil, query_606581, nil, nil, nil)

var getGetPlatformApplicationAttributes* = Call_GetGetPlatformApplicationAttributes_606566(
    name: "getGetPlatformApplicationAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetPlatformApplicationAttributes",
    validator: validate_GetGetPlatformApplicationAttributes_606567, base: "/",
    url: url_GetGetPlatformApplicationAttributes_606568,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetSMSAttributes_606615 = ref object of OpenApiRestCall_605589
proc url_PostGetSMSAttributes_606617(protocol: Scheme; host: string; base: string;
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

proc validate_PostGetSMSAttributes_606616(path: JsonNode; query: JsonNode;
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
  var valid_606618 = query.getOrDefault("Action")
  valid_606618 = validateParameter(valid_606618, JString, required = true,
                                 default = newJString("GetSMSAttributes"))
  if valid_606618 != nil:
    section.add "Action", valid_606618
  var valid_606619 = query.getOrDefault("Version")
  valid_606619 = validateParameter(valid_606619, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606619 != nil:
    section.add "Version", valid_606619
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606620 = header.getOrDefault("X-Amz-Signature")
  valid_606620 = validateParameter(valid_606620, JString, required = false,
                                 default = nil)
  if valid_606620 != nil:
    section.add "X-Amz-Signature", valid_606620
  var valid_606621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606621 = validateParameter(valid_606621, JString, required = false,
                                 default = nil)
  if valid_606621 != nil:
    section.add "X-Amz-Content-Sha256", valid_606621
  var valid_606622 = header.getOrDefault("X-Amz-Date")
  valid_606622 = validateParameter(valid_606622, JString, required = false,
                                 default = nil)
  if valid_606622 != nil:
    section.add "X-Amz-Date", valid_606622
  var valid_606623 = header.getOrDefault("X-Amz-Credential")
  valid_606623 = validateParameter(valid_606623, JString, required = false,
                                 default = nil)
  if valid_606623 != nil:
    section.add "X-Amz-Credential", valid_606623
  var valid_606624 = header.getOrDefault("X-Amz-Security-Token")
  valid_606624 = validateParameter(valid_606624, JString, required = false,
                                 default = nil)
  if valid_606624 != nil:
    section.add "X-Amz-Security-Token", valid_606624
  var valid_606625 = header.getOrDefault("X-Amz-Algorithm")
  valid_606625 = validateParameter(valid_606625, JString, required = false,
                                 default = nil)
  if valid_606625 != nil:
    section.add "X-Amz-Algorithm", valid_606625
  var valid_606626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606626 = validateParameter(valid_606626, JString, required = false,
                                 default = nil)
  if valid_606626 != nil:
    section.add "X-Amz-SignedHeaders", valid_606626
  result.add "header", section
  ## parameters in `formData` object:
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  section = newJObject()
  var valid_606627 = formData.getOrDefault("attributes")
  valid_606627 = validateParameter(valid_606627, JArray, required = false,
                                 default = nil)
  if valid_606627 != nil:
    section.add "attributes", valid_606627
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606628: Call_PostGetSMSAttributes_606615; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  let valid = call_606628.validator(path, query, header, formData, body)
  let scheme = call_606628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606628.url(scheme.get, call_606628.host, call_606628.base,
                         call_606628.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606628, url, valid)

proc call*(call_606629: Call_PostGetSMSAttributes_606615;
          attributes: JsonNode = nil; Action: string = "GetSMSAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetSMSAttributes
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606630 = newJObject()
  var formData_606631 = newJObject()
  if attributes != nil:
    formData_606631.add "attributes", attributes
  add(query_606630, "Action", newJString(Action))
  add(query_606630, "Version", newJString(Version))
  result = call_606629.call(nil, query_606630, nil, formData_606631, nil)

var postGetSMSAttributes* = Call_PostGetSMSAttributes_606615(
    name: "postGetSMSAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetSMSAttributes",
    validator: validate_PostGetSMSAttributes_606616, base: "/",
    url: url_PostGetSMSAttributes_606617, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetSMSAttributes_606599 = ref object of OpenApiRestCall_605589
proc url_GetGetSMSAttributes_606601(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetSMSAttributes_606600(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606602 = query.getOrDefault("Action")
  valid_606602 = validateParameter(valid_606602, JString, required = true,
                                 default = newJString("GetSMSAttributes"))
  if valid_606602 != nil:
    section.add "Action", valid_606602
  var valid_606603 = query.getOrDefault("attributes")
  valid_606603 = validateParameter(valid_606603, JArray, required = false,
                                 default = nil)
  if valid_606603 != nil:
    section.add "attributes", valid_606603
  var valid_606604 = query.getOrDefault("Version")
  valid_606604 = validateParameter(valid_606604, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606604 != nil:
    section.add "Version", valid_606604
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606605 = header.getOrDefault("X-Amz-Signature")
  valid_606605 = validateParameter(valid_606605, JString, required = false,
                                 default = nil)
  if valid_606605 != nil:
    section.add "X-Amz-Signature", valid_606605
  var valid_606606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606606 = validateParameter(valid_606606, JString, required = false,
                                 default = nil)
  if valid_606606 != nil:
    section.add "X-Amz-Content-Sha256", valid_606606
  var valid_606607 = header.getOrDefault("X-Amz-Date")
  valid_606607 = validateParameter(valid_606607, JString, required = false,
                                 default = nil)
  if valid_606607 != nil:
    section.add "X-Amz-Date", valid_606607
  var valid_606608 = header.getOrDefault("X-Amz-Credential")
  valid_606608 = validateParameter(valid_606608, JString, required = false,
                                 default = nil)
  if valid_606608 != nil:
    section.add "X-Amz-Credential", valid_606608
  var valid_606609 = header.getOrDefault("X-Amz-Security-Token")
  valid_606609 = validateParameter(valid_606609, JString, required = false,
                                 default = nil)
  if valid_606609 != nil:
    section.add "X-Amz-Security-Token", valid_606609
  var valid_606610 = header.getOrDefault("X-Amz-Algorithm")
  valid_606610 = validateParameter(valid_606610, JString, required = false,
                                 default = nil)
  if valid_606610 != nil:
    section.add "X-Amz-Algorithm", valid_606610
  var valid_606611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606611 = validateParameter(valid_606611, JString, required = false,
                                 default = nil)
  if valid_606611 != nil:
    section.add "X-Amz-SignedHeaders", valid_606611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606612: Call_GetGetSMSAttributes_606599; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  let valid = call_606612.validator(path, query, header, formData, body)
  let scheme = call_606612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606612.url(scheme.get, call_606612.host, call_606612.base,
                         call_606612.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606612, url, valid)

proc call*(call_606613: Call_GetGetSMSAttributes_606599;
          Action: string = "GetSMSAttributes"; attributes: JsonNode = nil;
          Version: string = "2010-03-31"): Recallable =
  ## getGetSMSAttributes
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ##   Action: string (required)
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  ##   Version: string (required)
  var query_606614 = newJObject()
  add(query_606614, "Action", newJString(Action))
  if attributes != nil:
    query_606614.add "attributes", attributes
  add(query_606614, "Version", newJString(Version))
  result = call_606613.call(nil, query_606614, nil, nil, nil)

var getGetSMSAttributes* = Call_GetGetSMSAttributes_606599(
    name: "getGetSMSAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetSMSAttributes",
    validator: validate_GetGetSMSAttributes_606600, base: "/",
    url: url_GetGetSMSAttributes_606601, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetSubscriptionAttributes_606648 = ref object of OpenApiRestCall_605589
proc url_PostGetSubscriptionAttributes_606650(protocol: Scheme; host: string;
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

proc validate_PostGetSubscriptionAttributes_606649(path: JsonNode; query: JsonNode;
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
  var valid_606651 = query.getOrDefault("Action")
  valid_606651 = validateParameter(valid_606651, JString, required = true, default = newJString(
      "GetSubscriptionAttributes"))
  if valid_606651 != nil:
    section.add "Action", valid_606651
  var valid_606652 = query.getOrDefault("Version")
  valid_606652 = validateParameter(valid_606652, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606652 != nil:
    section.add "Version", valid_606652
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606653 = header.getOrDefault("X-Amz-Signature")
  valid_606653 = validateParameter(valid_606653, JString, required = false,
                                 default = nil)
  if valid_606653 != nil:
    section.add "X-Amz-Signature", valid_606653
  var valid_606654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606654 = validateParameter(valid_606654, JString, required = false,
                                 default = nil)
  if valid_606654 != nil:
    section.add "X-Amz-Content-Sha256", valid_606654
  var valid_606655 = header.getOrDefault("X-Amz-Date")
  valid_606655 = validateParameter(valid_606655, JString, required = false,
                                 default = nil)
  if valid_606655 != nil:
    section.add "X-Amz-Date", valid_606655
  var valid_606656 = header.getOrDefault("X-Amz-Credential")
  valid_606656 = validateParameter(valid_606656, JString, required = false,
                                 default = nil)
  if valid_606656 != nil:
    section.add "X-Amz-Credential", valid_606656
  var valid_606657 = header.getOrDefault("X-Amz-Security-Token")
  valid_606657 = validateParameter(valid_606657, JString, required = false,
                                 default = nil)
  if valid_606657 != nil:
    section.add "X-Amz-Security-Token", valid_606657
  var valid_606658 = header.getOrDefault("X-Amz-Algorithm")
  valid_606658 = validateParameter(valid_606658, JString, required = false,
                                 default = nil)
  if valid_606658 != nil:
    section.add "X-Amz-Algorithm", valid_606658
  var valid_606659 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606659 = validateParameter(valid_606659, JString, required = false,
                                 default = nil)
  if valid_606659 != nil:
    section.add "X-Amz-SignedHeaders", valid_606659
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionArn` field"
  var valid_606660 = formData.getOrDefault("SubscriptionArn")
  valid_606660 = validateParameter(valid_606660, JString, required = true,
                                 default = nil)
  if valid_606660 != nil:
    section.add "SubscriptionArn", valid_606660
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606661: Call_PostGetSubscriptionAttributes_606648; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a subscription.
  ## 
  let valid = call_606661.validator(path, query, header, formData, body)
  let scheme = call_606661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606661.url(scheme.get, call_606661.host, call_606661.base,
                         call_606661.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606661, url, valid)

proc call*(call_606662: Call_PostGetSubscriptionAttributes_606648;
          SubscriptionArn: string; Action: string = "GetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetSubscriptionAttributes
  ## Returns all of the properties of a subscription.
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606663 = newJObject()
  var formData_606664 = newJObject()
  add(formData_606664, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_606663, "Action", newJString(Action))
  add(query_606663, "Version", newJString(Version))
  result = call_606662.call(nil, query_606663, nil, formData_606664, nil)

var postGetSubscriptionAttributes* = Call_PostGetSubscriptionAttributes_606648(
    name: "postGetSubscriptionAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetSubscriptionAttributes",
    validator: validate_PostGetSubscriptionAttributes_606649, base: "/",
    url: url_PostGetSubscriptionAttributes_606650,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetSubscriptionAttributes_606632 = ref object of OpenApiRestCall_605589
proc url_GetGetSubscriptionAttributes_606634(protocol: Scheme; host: string;
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

proc validate_GetGetSubscriptionAttributes_606633(path: JsonNode; query: JsonNode;
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
  var valid_606635 = query.getOrDefault("SubscriptionArn")
  valid_606635 = validateParameter(valid_606635, JString, required = true,
                                 default = nil)
  if valid_606635 != nil:
    section.add "SubscriptionArn", valid_606635
  var valid_606636 = query.getOrDefault("Action")
  valid_606636 = validateParameter(valid_606636, JString, required = true, default = newJString(
      "GetSubscriptionAttributes"))
  if valid_606636 != nil:
    section.add "Action", valid_606636
  var valid_606637 = query.getOrDefault("Version")
  valid_606637 = validateParameter(valid_606637, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606637 != nil:
    section.add "Version", valid_606637
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606638 = header.getOrDefault("X-Amz-Signature")
  valid_606638 = validateParameter(valid_606638, JString, required = false,
                                 default = nil)
  if valid_606638 != nil:
    section.add "X-Amz-Signature", valid_606638
  var valid_606639 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606639 = validateParameter(valid_606639, JString, required = false,
                                 default = nil)
  if valid_606639 != nil:
    section.add "X-Amz-Content-Sha256", valid_606639
  var valid_606640 = header.getOrDefault("X-Amz-Date")
  valid_606640 = validateParameter(valid_606640, JString, required = false,
                                 default = nil)
  if valid_606640 != nil:
    section.add "X-Amz-Date", valid_606640
  var valid_606641 = header.getOrDefault("X-Amz-Credential")
  valid_606641 = validateParameter(valid_606641, JString, required = false,
                                 default = nil)
  if valid_606641 != nil:
    section.add "X-Amz-Credential", valid_606641
  var valid_606642 = header.getOrDefault("X-Amz-Security-Token")
  valid_606642 = validateParameter(valid_606642, JString, required = false,
                                 default = nil)
  if valid_606642 != nil:
    section.add "X-Amz-Security-Token", valid_606642
  var valid_606643 = header.getOrDefault("X-Amz-Algorithm")
  valid_606643 = validateParameter(valid_606643, JString, required = false,
                                 default = nil)
  if valid_606643 != nil:
    section.add "X-Amz-Algorithm", valid_606643
  var valid_606644 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606644 = validateParameter(valid_606644, JString, required = false,
                                 default = nil)
  if valid_606644 != nil:
    section.add "X-Amz-SignedHeaders", valid_606644
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606645: Call_GetGetSubscriptionAttributes_606632; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a subscription.
  ## 
  let valid = call_606645.validator(path, query, header, formData, body)
  let scheme = call_606645.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606645.url(scheme.get, call_606645.host, call_606645.base,
                         call_606645.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606645, url, valid)

proc call*(call_606646: Call_GetGetSubscriptionAttributes_606632;
          SubscriptionArn: string; Action: string = "GetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getGetSubscriptionAttributes
  ## Returns all of the properties of a subscription.
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606647 = newJObject()
  add(query_606647, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_606647, "Action", newJString(Action))
  add(query_606647, "Version", newJString(Version))
  result = call_606646.call(nil, query_606647, nil, nil, nil)

var getGetSubscriptionAttributes* = Call_GetGetSubscriptionAttributes_606632(
    name: "getGetSubscriptionAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetSubscriptionAttributes",
    validator: validate_GetGetSubscriptionAttributes_606633, base: "/",
    url: url_GetGetSubscriptionAttributes_606634,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetTopicAttributes_606681 = ref object of OpenApiRestCall_605589
proc url_PostGetTopicAttributes_606683(protocol: Scheme; host: string; base: string;
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

proc validate_PostGetTopicAttributes_606682(path: JsonNode; query: JsonNode;
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
  var valid_606684 = query.getOrDefault("Action")
  valid_606684 = validateParameter(valid_606684, JString, required = true,
                                 default = newJString("GetTopicAttributes"))
  if valid_606684 != nil:
    section.add "Action", valid_606684
  var valid_606685 = query.getOrDefault("Version")
  valid_606685 = validateParameter(valid_606685, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606685 != nil:
    section.add "Version", valid_606685
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606686 = header.getOrDefault("X-Amz-Signature")
  valid_606686 = validateParameter(valid_606686, JString, required = false,
                                 default = nil)
  if valid_606686 != nil:
    section.add "X-Amz-Signature", valid_606686
  var valid_606687 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606687 = validateParameter(valid_606687, JString, required = false,
                                 default = nil)
  if valid_606687 != nil:
    section.add "X-Amz-Content-Sha256", valid_606687
  var valid_606688 = header.getOrDefault("X-Amz-Date")
  valid_606688 = validateParameter(valid_606688, JString, required = false,
                                 default = nil)
  if valid_606688 != nil:
    section.add "X-Amz-Date", valid_606688
  var valid_606689 = header.getOrDefault("X-Amz-Credential")
  valid_606689 = validateParameter(valid_606689, JString, required = false,
                                 default = nil)
  if valid_606689 != nil:
    section.add "X-Amz-Credential", valid_606689
  var valid_606690 = header.getOrDefault("X-Amz-Security-Token")
  valid_606690 = validateParameter(valid_606690, JString, required = false,
                                 default = nil)
  if valid_606690 != nil:
    section.add "X-Amz-Security-Token", valid_606690
  var valid_606691 = header.getOrDefault("X-Amz-Algorithm")
  valid_606691 = validateParameter(valid_606691, JString, required = false,
                                 default = nil)
  if valid_606691 != nil:
    section.add "X-Amz-Algorithm", valid_606691
  var valid_606692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606692 = validateParameter(valid_606692, JString, required = false,
                                 default = nil)
  if valid_606692 != nil:
    section.add "X-Amz-SignedHeaders", valid_606692
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose properties you want to get.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_606693 = formData.getOrDefault("TopicArn")
  valid_606693 = validateParameter(valid_606693, JString, required = true,
                                 default = nil)
  if valid_606693 != nil:
    section.add "TopicArn", valid_606693
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606694: Call_PostGetTopicAttributes_606681; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ## 
  let valid = call_606694.validator(path, query, header, formData, body)
  let scheme = call_606694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606694.url(scheme.get, call_606694.host, call_606694.base,
                         call_606694.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606694, url, valid)

proc call*(call_606695: Call_PostGetTopicAttributes_606681; TopicArn: string;
          Action: string = "GetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## postGetTopicAttributes
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose properties you want to get.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606696 = newJObject()
  var formData_606697 = newJObject()
  add(formData_606697, "TopicArn", newJString(TopicArn))
  add(query_606696, "Action", newJString(Action))
  add(query_606696, "Version", newJString(Version))
  result = call_606695.call(nil, query_606696, nil, formData_606697, nil)

var postGetTopicAttributes* = Call_PostGetTopicAttributes_606681(
    name: "postGetTopicAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetTopicAttributes",
    validator: validate_PostGetTopicAttributes_606682, base: "/",
    url: url_PostGetTopicAttributes_606683, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetTopicAttributes_606665 = ref object of OpenApiRestCall_605589
proc url_GetGetTopicAttributes_606667(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetTopicAttributes_606666(path: JsonNode; query: JsonNode;
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
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose properties you want to get.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606668 = query.getOrDefault("Action")
  valid_606668 = validateParameter(valid_606668, JString, required = true,
                                 default = newJString("GetTopicAttributes"))
  if valid_606668 != nil:
    section.add "Action", valid_606668
  var valid_606669 = query.getOrDefault("Version")
  valid_606669 = validateParameter(valid_606669, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606669 != nil:
    section.add "Version", valid_606669
  var valid_606670 = query.getOrDefault("TopicArn")
  valid_606670 = validateParameter(valid_606670, JString, required = true,
                                 default = nil)
  if valid_606670 != nil:
    section.add "TopicArn", valid_606670
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606671 = header.getOrDefault("X-Amz-Signature")
  valid_606671 = validateParameter(valid_606671, JString, required = false,
                                 default = nil)
  if valid_606671 != nil:
    section.add "X-Amz-Signature", valid_606671
  var valid_606672 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606672 = validateParameter(valid_606672, JString, required = false,
                                 default = nil)
  if valid_606672 != nil:
    section.add "X-Amz-Content-Sha256", valid_606672
  var valid_606673 = header.getOrDefault("X-Amz-Date")
  valid_606673 = validateParameter(valid_606673, JString, required = false,
                                 default = nil)
  if valid_606673 != nil:
    section.add "X-Amz-Date", valid_606673
  var valid_606674 = header.getOrDefault("X-Amz-Credential")
  valid_606674 = validateParameter(valid_606674, JString, required = false,
                                 default = nil)
  if valid_606674 != nil:
    section.add "X-Amz-Credential", valid_606674
  var valid_606675 = header.getOrDefault("X-Amz-Security-Token")
  valid_606675 = validateParameter(valid_606675, JString, required = false,
                                 default = nil)
  if valid_606675 != nil:
    section.add "X-Amz-Security-Token", valid_606675
  var valid_606676 = header.getOrDefault("X-Amz-Algorithm")
  valid_606676 = validateParameter(valid_606676, JString, required = false,
                                 default = nil)
  if valid_606676 != nil:
    section.add "X-Amz-Algorithm", valid_606676
  var valid_606677 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606677 = validateParameter(valid_606677, JString, required = false,
                                 default = nil)
  if valid_606677 != nil:
    section.add "X-Amz-SignedHeaders", valid_606677
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606678: Call_GetGetTopicAttributes_606665; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ## 
  let valid = call_606678.validator(path, query, header, formData, body)
  let scheme = call_606678.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606678.url(scheme.get, call_606678.host, call_606678.base,
                         call_606678.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606678, url, valid)

proc call*(call_606679: Call_GetGetTopicAttributes_606665; TopicArn: string;
          Action: string = "GetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## getGetTopicAttributes
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose properties you want to get.
  var query_606680 = newJObject()
  add(query_606680, "Action", newJString(Action))
  add(query_606680, "Version", newJString(Version))
  add(query_606680, "TopicArn", newJString(TopicArn))
  result = call_606679.call(nil, query_606680, nil, nil, nil)

var getGetTopicAttributes* = Call_GetGetTopicAttributes_606665(
    name: "getGetTopicAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetTopicAttributes",
    validator: validate_GetGetTopicAttributes_606666, base: "/",
    url: url_GetGetTopicAttributes_606667, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListEndpointsByPlatformApplication_606715 = ref object of OpenApiRestCall_605589
proc url_PostListEndpointsByPlatformApplication_606717(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListEndpointsByPlatformApplication_606716(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606718 = query.getOrDefault("Action")
  valid_606718 = validateParameter(valid_606718, JString, required = true, default = newJString(
      "ListEndpointsByPlatformApplication"))
  if valid_606718 != nil:
    section.add "Action", valid_606718
  var valid_606719 = query.getOrDefault("Version")
  valid_606719 = validateParameter(valid_606719, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606719 != nil:
    section.add "Version", valid_606719
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606720 = header.getOrDefault("X-Amz-Signature")
  valid_606720 = validateParameter(valid_606720, JString, required = false,
                                 default = nil)
  if valid_606720 != nil:
    section.add "X-Amz-Signature", valid_606720
  var valid_606721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606721 = validateParameter(valid_606721, JString, required = false,
                                 default = nil)
  if valid_606721 != nil:
    section.add "X-Amz-Content-Sha256", valid_606721
  var valid_606722 = header.getOrDefault("X-Amz-Date")
  valid_606722 = validateParameter(valid_606722, JString, required = false,
                                 default = nil)
  if valid_606722 != nil:
    section.add "X-Amz-Date", valid_606722
  var valid_606723 = header.getOrDefault("X-Amz-Credential")
  valid_606723 = validateParameter(valid_606723, JString, required = false,
                                 default = nil)
  if valid_606723 != nil:
    section.add "X-Amz-Credential", valid_606723
  var valid_606724 = header.getOrDefault("X-Amz-Security-Token")
  valid_606724 = validateParameter(valid_606724, JString, required = false,
                                 default = nil)
  if valid_606724 != nil:
    section.add "X-Amz-Security-Token", valid_606724
  var valid_606725 = header.getOrDefault("X-Amz-Algorithm")
  valid_606725 = validateParameter(valid_606725, JString, required = false,
                                 default = nil)
  if valid_606725 != nil:
    section.add "X-Amz-Algorithm", valid_606725
  var valid_606726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606726 = validateParameter(valid_606726, JString, required = false,
                                 default = nil)
  if valid_606726 != nil:
    section.add "X-Amz-SignedHeaders", valid_606726
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListEndpointsByPlatformApplication action to retrieve additional records that are available after the first page results.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_606727 = formData.getOrDefault("PlatformApplicationArn")
  valid_606727 = validateParameter(valid_606727, JString, required = true,
                                 default = nil)
  if valid_606727 != nil:
    section.add "PlatformApplicationArn", valid_606727
  var valid_606728 = formData.getOrDefault("NextToken")
  valid_606728 = validateParameter(valid_606728, JString, required = false,
                                 default = nil)
  if valid_606728 != nil:
    section.add "NextToken", valid_606728
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606729: Call_PostListEndpointsByPlatformApplication_606715;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as FCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_606729.validator(path, query, header, formData, body)
  let scheme = call_606729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606729.url(scheme.get, call_606729.host, call_606729.base,
                         call_606729.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606729, url, valid)

proc call*(call_606730: Call_PostListEndpointsByPlatformApplication_606715;
          PlatformApplicationArn: string; NextToken: string = "";
          Action: string = "ListEndpointsByPlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## postListEndpointsByPlatformApplication
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as FCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  ##   NextToken: string
  ##            : NextToken string is used when calling ListEndpointsByPlatformApplication action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606731 = newJObject()
  var formData_606732 = newJObject()
  add(formData_606732, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(formData_606732, "NextToken", newJString(NextToken))
  add(query_606731, "Action", newJString(Action))
  add(query_606731, "Version", newJString(Version))
  result = call_606730.call(nil, query_606731, nil, formData_606732, nil)

var postListEndpointsByPlatformApplication* = Call_PostListEndpointsByPlatformApplication_606715(
    name: "postListEndpointsByPlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com",
    route: "/#Action=ListEndpointsByPlatformApplication",
    validator: validate_PostListEndpointsByPlatformApplication_606716, base: "/",
    url: url_PostListEndpointsByPlatformApplication_606717,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListEndpointsByPlatformApplication_606698 = ref object of OpenApiRestCall_605589
proc url_GetListEndpointsByPlatformApplication_606700(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListEndpointsByPlatformApplication_606699(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as FCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListEndpointsByPlatformApplication action to retrieve additional records that are available after the first page results.
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_606701 = query.getOrDefault("NextToken")
  valid_606701 = validateParameter(valid_606701, JString, required = false,
                                 default = nil)
  if valid_606701 != nil:
    section.add "NextToken", valid_606701
  assert query != nil, "query argument is necessary due to required `PlatformApplicationArn` field"
  var valid_606702 = query.getOrDefault("PlatformApplicationArn")
  valid_606702 = validateParameter(valid_606702, JString, required = true,
                                 default = nil)
  if valid_606702 != nil:
    section.add "PlatformApplicationArn", valid_606702
  var valid_606703 = query.getOrDefault("Action")
  valid_606703 = validateParameter(valid_606703, JString, required = true, default = newJString(
      "ListEndpointsByPlatformApplication"))
  if valid_606703 != nil:
    section.add "Action", valid_606703
  var valid_606704 = query.getOrDefault("Version")
  valid_606704 = validateParameter(valid_606704, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606704 != nil:
    section.add "Version", valid_606704
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606705 = header.getOrDefault("X-Amz-Signature")
  valid_606705 = validateParameter(valid_606705, JString, required = false,
                                 default = nil)
  if valid_606705 != nil:
    section.add "X-Amz-Signature", valid_606705
  var valid_606706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606706 = validateParameter(valid_606706, JString, required = false,
                                 default = nil)
  if valid_606706 != nil:
    section.add "X-Amz-Content-Sha256", valid_606706
  var valid_606707 = header.getOrDefault("X-Amz-Date")
  valid_606707 = validateParameter(valid_606707, JString, required = false,
                                 default = nil)
  if valid_606707 != nil:
    section.add "X-Amz-Date", valid_606707
  var valid_606708 = header.getOrDefault("X-Amz-Credential")
  valid_606708 = validateParameter(valid_606708, JString, required = false,
                                 default = nil)
  if valid_606708 != nil:
    section.add "X-Amz-Credential", valid_606708
  var valid_606709 = header.getOrDefault("X-Amz-Security-Token")
  valid_606709 = validateParameter(valid_606709, JString, required = false,
                                 default = nil)
  if valid_606709 != nil:
    section.add "X-Amz-Security-Token", valid_606709
  var valid_606710 = header.getOrDefault("X-Amz-Algorithm")
  valid_606710 = validateParameter(valid_606710, JString, required = false,
                                 default = nil)
  if valid_606710 != nil:
    section.add "X-Amz-Algorithm", valid_606710
  var valid_606711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606711 = validateParameter(valid_606711, JString, required = false,
                                 default = nil)
  if valid_606711 != nil:
    section.add "X-Amz-SignedHeaders", valid_606711
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606712: Call_GetListEndpointsByPlatformApplication_606698;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as FCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_606712.validator(path, query, header, formData, body)
  let scheme = call_606712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606712.url(scheme.get, call_606712.host, call_606712.base,
                         call_606712.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606712, url, valid)

proc call*(call_606713: Call_GetListEndpointsByPlatformApplication_606698;
          PlatformApplicationArn: string; NextToken: string = "";
          Action: string = "ListEndpointsByPlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## getListEndpointsByPlatformApplication
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as FCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListEndpointsByPlatformApplication action to retrieve additional records that are available after the first page results.
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606714 = newJObject()
  add(query_606714, "NextToken", newJString(NextToken))
  add(query_606714, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  add(query_606714, "Action", newJString(Action))
  add(query_606714, "Version", newJString(Version))
  result = call_606713.call(nil, query_606714, nil, nil, nil)

var getListEndpointsByPlatformApplication* = Call_GetListEndpointsByPlatformApplication_606698(
    name: "getListEndpointsByPlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com",
    route: "/#Action=ListEndpointsByPlatformApplication",
    validator: validate_GetListEndpointsByPlatformApplication_606699, base: "/",
    url: url_GetListEndpointsByPlatformApplication_606700,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPhoneNumbersOptedOut_606749 = ref object of OpenApiRestCall_605589
proc url_PostListPhoneNumbersOptedOut_606751(protocol: Scheme; host: string;
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

proc validate_PostListPhoneNumbersOptedOut_606750(path: JsonNode; query: JsonNode;
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
  var valid_606752 = query.getOrDefault("Action")
  valid_606752 = validateParameter(valid_606752, JString, required = true, default = newJString(
      "ListPhoneNumbersOptedOut"))
  if valid_606752 != nil:
    section.add "Action", valid_606752
  var valid_606753 = query.getOrDefault("Version")
  valid_606753 = validateParameter(valid_606753, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606753 != nil:
    section.add "Version", valid_606753
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606754 = header.getOrDefault("X-Amz-Signature")
  valid_606754 = validateParameter(valid_606754, JString, required = false,
                                 default = nil)
  if valid_606754 != nil:
    section.add "X-Amz-Signature", valid_606754
  var valid_606755 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606755 = validateParameter(valid_606755, JString, required = false,
                                 default = nil)
  if valid_606755 != nil:
    section.add "X-Amz-Content-Sha256", valid_606755
  var valid_606756 = header.getOrDefault("X-Amz-Date")
  valid_606756 = validateParameter(valid_606756, JString, required = false,
                                 default = nil)
  if valid_606756 != nil:
    section.add "X-Amz-Date", valid_606756
  var valid_606757 = header.getOrDefault("X-Amz-Credential")
  valid_606757 = validateParameter(valid_606757, JString, required = false,
                                 default = nil)
  if valid_606757 != nil:
    section.add "X-Amz-Credential", valid_606757
  var valid_606758 = header.getOrDefault("X-Amz-Security-Token")
  valid_606758 = validateParameter(valid_606758, JString, required = false,
                                 default = nil)
  if valid_606758 != nil:
    section.add "X-Amz-Security-Token", valid_606758
  var valid_606759 = header.getOrDefault("X-Amz-Algorithm")
  valid_606759 = validateParameter(valid_606759, JString, required = false,
                                 default = nil)
  if valid_606759 != nil:
    section.add "X-Amz-Algorithm", valid_606759
  var valid_606760 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606760 = validateParameter(valid_606760, JString, required = false,
                                 default = nil)
  if valid_606760 != nil:
    section.add "X-Amz-SignedHeaders", valid_606760
  result.add "header", section
  ## parameters in `formData` object:
  ##   nextToken: JString
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  section = newJObject()
  var valid_606761 = formData.getOrDefault("nextToken")
  valid_606761 = validateParameter(valid_606761, JString, required = false,
                                 default = nil)
  if valid_606761 != nil:
    section.add "nextToken", valid_606761
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606762: Call_PostListPhoneNumbersOptedOut_606749; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ## 
  let valid = call_606762.validator(path, query, header, formData, body)
  let scheme = call_606762.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606762.url(scheme.get, call_606762.host, call_606762.base,
                         call_606762.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606762, url, valid)

proc call*(call_606763: Call_PostListPhoneNumbersOptedOut_606749;
          nextToken: string = ""; Action: string = "ListPhoneNumbersOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## postListPhoneNumbersOptedOut
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ##   nextToken: string
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606764 = newJObject()
  var formData_606765 = newJObject()
  add(formData_606765, "nextToken", newJString(nextToken))
  add(query_606764, "Action", newJString(Action))
  add(query_606764, "Version", newJString(Version))
  result = call_606763.call(nil, query_606764, nil, formData_606765, nil)

var postListPhoneNumbersOptedOut* = Call_PostListPhoneNumbersOptedOut_606749(
    name: "postListPhoneNumbersOptedOut", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListPhoneNumbersOptedOut",
    validator: validate_PostListPhoneNumbersOptedOut_606750, base: "/",
    url: url_PostListPhoneNumbersOptedOut_606751,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPhoneNumbersOptedOut_606733 = ref object of OpenApiRestCall_605589
proc url_GetListPhoneNumbersOptedOut_606735(protocol: Scheme; host: string;
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

proc validate_GetListPhoneNumbersOptedOut_606734(path: JsonNode; query: JsonNode;
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
  var valid_606736 = query.getOrDefault("nextToken")
  valid_606736 = validateParameter(valid_606736, JString, required = false,
                                 default = nil)
  if valid_606736 != nil:
    section.add "nextToken", valid_606736
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606737 = query.getOrDefault("Action")
  valid_606737 = validateParameter(valid_606737, JString, required = true, default = newJString(
      "ListPhoneNumbersOptedOut"))
  if valid_606737 != nil:
    section.add "Action", valid_606737
  var valid_606738 = query.getOrDefault("Version")
  valid_606738 = validateParameter(valid_606738, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606738 != nil:
    section.add "Version", valid_606738
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606739 = header.getOrDefault("X-Amz-Signature")
  valid_606739 = validateParameter(valid_606739, JString, required = false,
                                 default = nil)
  if valid_606739 != nil:
    section.add "X-Amz-Signature", valid_606739
  var valid_606740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606740 = validateParameter(valid_606740, JString, required = false,
                                 default = nil)
  if valid_606740 != nil:
    section.add "X-Amz-Content-Sha256", valid_606740
  var valid_606741 = header.getOrDefault("X-Amz-Date")
  valid_606741 = validateParameter(valid_606741, JString, required = false,
                                 default = nil)
  if valid_606741 != nil:
    section.add "X-Amz-Date", valid_606741
  var valid_606742 = header.getOrDefault("X-Amz-Credential")
  valid_606742 = validateParameter(valid_606742, JString, required = false,
                                 default = nil)
  if valid_606742 != nil:
    section.add "X-Amz-Credential", valid_606742
  var valid_606743 = header.getOrDefault("X-Amz-Security-Token")
  valid_606743 = validateParameter(valid_606743, JString, required = false,
                                 default = nil)
  if valid_606743 != nil:
    section.add "X-Amz-Security-Token", valid_606743
  var valid_606744 = header.getOrDefault("X-Amz-Algorithm")
  valid_606744 = validateParameter(valid_606744, JString, required = false,
                                 default = nil)
  if valid_606744 != nil:
    section.add "X-Amz-Algorithm", valid_606744
  var valid_606745 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606745 = validateParameter(valid_606745, JString, required = false,
                                 default = nil)
  if valid_606745 != nil:
    section.add "X-Amz-SignedHeaders", valid_606745
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606746: Call_GetListPhoneNumbersOptedOut_606733; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ## 
  let valid = call_606746.validator(path, query, header, formData, body)
  let scheme = call_606746.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606746.url(scheme.get, call_606746.host, call_606746.base,
                         call_606746.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606746, url, valid)

proc call*(call_606747: Call_GetListPhoneNumbersOptedOut_606733;
          nextToken: string = ""; Action: string = "ListPhoneNumbersOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## getListPhoneNumbersOptedOut
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ##   nextToken: string
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606748 = newJObject()
  add(query_606748, "nextToken", newJString(nextToken))
  add(query_606748, "Action", newJString(Action))
  add(query_606748, "Version", newJString(Version))
  result = call_606747.call(nil, query_606748, nil, nil, nil)

var getListPhoneNumbersOptedOut* = Call_GetListPhoneNumbersOptedOut_606733(
    name: "getListPhoneNumbersOptedOut", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListPhoneNumbersOptedOut",
    validator: validate_GetListPhoneNumbersOptedOut_606734, base: "/",
    url: url_GetListPhoneNumbersOptedOut_606735,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPlatformApplications_606782 = ref object of OpenApiRestCall_605589
proc url_PostListPlatformApplications_606784(protocol: Scheme; host: string;
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

proc validate_PostListPlatformApplications_606783(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606785 = query.getOrDefault("Action")
  valid_606785 = validateParameter(valid_606785, JString, required = true, default = newJString(
      "ListPlatformApplications"))
  if valid_606785 != nil:
    section.add "Action", valid_606785
  var valid_606786 = query.getOrDefault("Version")
  valid_606786 = validateParameter(valid_606786, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606786 != nil:
    section.add "Version", valid_606786
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606787 = header.getOrDefault("X-Amz-Signature")
  valid_606787 = validateParameter(valid_606787, JString, required = false,
                                 default = nil)
  if valid_606787 != nil:
    section.add "X-Amz-Signature", valid_606787
  var valid_606788 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606788 = validateParameter(valid_606788, JString, required = false,
                                 default = nil)
  if valid_606788 != nil:
    section.add "X-Amz-Content-Sha256", valid_606788
  var valid_606789 = header.getOrDefault("X-Amz-Date")
  valid_606789 = validateParameter(valid_606789, JString, required = false,
                                 default = nil)
  if valid_606789 != nil:
    section.add "X-Amz-Date", valid_606789
  var valid_606790 = header.getOrDefault("X-Amz-Credential")
  valid_606790 = validateParameter(valid_606790, JString, required = false,
                                 default = nil)
  if valid_606790 != nil:
    section.add "X-Amz-Credential", valid_606790
  var valid_606791 = header.getOrDefault("X-Amz-Security-Token")
  valid_606791 = validateParameter(valid_606791, JString, required = false,
                                 default = nil)
  if valid_606791 != nil:
    section.add "X-Amz-Security-Token", valid_606791
  var valid_606792 = header.getOrDefault("X-Amz-Algorithm")
  valid_606792 = validateParameter(valid_606792, JString, required = false,
                                 default = nil)
  if valid_606792 != nil:
    section.add "X-Amz-Algorithm", valid_606792
  var valid_606793 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606793 = validateParameter(valid_606793, JString, required = false,
                                 default = nil)
  if valid_606793 != nil:
    section.add "X-Amz-SignedHeaders", valid_606793
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  section = newJObject()
  var valid_606794 = formData.getOrDefault("NextToken")
  valid_606794 = validateParameter(valid_606794, JString, required = false,
                                 default = nil)
  if valid_606794 != nil:
    section.add "NextToken", valid_606794
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606795: Call_PostListPlatformApplications_606782; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and FCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  let valid = call_606795.validator(path, query, header, formData, body)
  let scheme = call_606795.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606795.url(scheme.get, call_606795.host, call_606795.base,
                         call_606795.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606795, url, valid)

proc call*(call_606796: Call_PostListPlatformApplications_606782;
          NextToken: string = ""; Action: string = "ListPlatformApplications";
          Version: string = "2010-03-31"): Recallable =
  ## postListPlatformApplications
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and FCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606797 = newJObject()
  var formData_606798 = newJObject()
  add(formData_606798, "NextToken", newJString(NextToken))
  add(query_606797, "Action", newJString(Action))
  add(query_606797, "Version", newJString(Version))
  result = call_606796.call(nil, query_606797, nil, formData_606798, nil)

var postListPlatformApplications* = Call_PostListPlatformApplications_606782(
    name: "postListPlatformApplications", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListPlatformApplications",
    validator: validate_PostListPlatformApplications_606783, base: "/",
    url: url_PostListPlatformApplications_606784,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPlatformApplications_606766 = ref object of OpenApiRestCall_605589
proc url_GetListPlatformApplications_606768(protocol: Scheme; host: string;
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

proc validate_GetListPlatformApplications_606767(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606769 = query.getOrDefault("NextToken")
  valid_606769 = validateParameter(valid_606769, JString, required = false,
                                 default = nil)
  if valid_606769 != nil:
    section.add "NextToken", valid_606769
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606770 = query.getOrDefault("Action")
  valid_606770 = validateParameter(valid_606770, JString, required = true, default = newJString(
      "ListPlatformApplications"))
  if valid_606770 != nil:
    section.add "Action", valid_606770
  var valid_606771 = query.getOrDefault("Version")
  valid_606771 = validateParameter(valid_606771, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606771 != nil:
    section.add "Version", valid_606771
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606772 = header.getOrDefault("X-Amz-Signature")
  valid_606772 = validateParameter(valid_606772, JString, required = false,
                                 default = nil)
  if valid_606772 != nil:
    section.add "X-Amz-Signature", valid_606772
  var valid_606773 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606773 = validateParameter(valid_606773, JString, required = false,
                                 default = nil)
  if valid_606773 != nil:
    section.add "X-Amz-Content-Sha256", valid_606773
  var valid_606774 = header.getOrDefault("X-Amz-Date")
  valid_606774 = validateParameter(valid_606774, JString, required = false,
                                 default = nil)
  if valid_606774 != nil:
    section.add "X-Amz-Date", valid_606774
  var valid_606775 = header.getOrDefault("X-Amz-Credential")
  valid_606775 = validateParameter(valid_606775, JString, required = false,
                                 default = nil)
  if valid_606775 != nil:
    section.add "X-Amz-Credential", valid_606775
  var valid_606776 = header.getOrDefault("X-Amz-Security-Token")
  valid_606776 = validateParameter(valid_606776, JString, required = false,
                                 default = nil)
  if valid_606776 != nil:
    section.add "X-Amz-Security-Token", valid_606776
  var valid_606777 = header.getOrDefault("X-Amz-Algorithm")
  valid_606777 = validateParameter(valid_606777, JString, required = false,
                                 default = nil)
  if valid_606777 != nil:
    section.add "X-Amz-Algorithm", valid_606777
  var valid_606778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606778 = validateParameter(valid_606778, JString, required = false,
                                 default = nil)
  if valid_606778 != nil:
    section.add "X-Amz-SignedHeaders", valid_606778
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606779: Call_GetListPlatformApplications_606766; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and FCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  let valid = call_606779.validator(path, query, header, formData, body)
  let scheme = call_606779.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606779.url(scheme.get, call_606779.host, call_606779.base,
                         call_606779.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606779, url, valid)

proc call*(call_606780: Call_GetListPlatformApplications_606766;
          NextToken: string = ""; Action: string = "ListPlatformApplications";
          Version: string = "2010-03-31"): Recallable =
  ## getListPlatformApplications
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and FCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606781 = newJObject()
  add(query_606781, "NextToken", newJString(NextToken))
  add(query_606781, "Action", newJString(Action))
  add(query_606781, "Version", newJString(Version))
  result = call_606780.call(nil, query_606781, nil, nil, nil)

var getListPlatformApplications* = Call_GetListPlatformApplications_606766(
    name: "getListPlatformApplications", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListPlatformApplications",
    validator: validate_GetListPlatformApplications_606767, base: "/",
    url: url_GetListPlatformApplications_606768,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListSubscriptions_606815 = ref object of OpenApiRestCall_605589
proc url_PostListSubscriptions_606817(protocol: Scheme; host: string; base: string;
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

proc validate_PostListSubscriptions_606816(path: JsonNode; query: JsonNode;
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
  var valid_606818 = query.getOrDefault("Action")
  valid_606818 = validateParameter(valid_606818, JString, required = true,
                                 default = newJString("ListSubscriptions"))
  if valid_606818 != nil:
    section.add "Action", valid_606818
  var valid_606819 = query.getOrDefault("Version")
  valid_606819 = validateParameter(valid_606819, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606819 != nil:
    section.add "Version", valid_606819
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606820 = header.getOrDefault("X-Amz-Signature")
  valid_606820 = validateParameter(valid_606820, JString, required = false,
                                 default = nil)
  if valid_606820 != nil:
    section.add "X-Amz-Signature", valid_606820
  var valid_606821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606821 = validateParameter(valid_606821, JString, required = false,
                                 default = nil)
  if valid_606821 != nil:
    section.add "X-Amz-Content-Sha256", valid_606821
  var valid_606822 = header.getOrDefault("X-Amz-Date")
  valid_606822 = validateParameter(valid_606822, JString, required = false,
                                 default = nil)
  if valid_606822 != nil:
    section.add "X-Amz-Date", valid_606822
  var valid_606823 = header.getOrDefault("X-Amz-Credential")
  valid_606823 = validateParameter(valid_606823, JString, required = false,
                                 default = nil)
  if valid_606823 != nil:
    section.add "X-Amz-Credential", valid_606823
  var valid_606824 = header.getOrDefault("X-Amz-Security-Token")
  valid_606824 = validateParameter(valid_606824, JString, required = false,
                                 default = nil)
  if valid_606824 != nil:
    section.add "X-Amz-Security-Token", valid_606824
  var valid_606825 = header.getOrDefault("X-Amz-Algorithm")
  valid_606825 = validateParameter(valid_606825, JString, required = false,
                                 default = nil)
  if valid_606825 != nil:
    section.add "X-Amz-Algorithm", valid_606825
  var valid_606826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606826 = validateParameter(valid_606826, JString, required = false,
                                 default = nil)
  if valid_606826 != nil:
    section.add "X-Amz-SignedHeaders", valid_606826
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  section = newJObject()
  var valid_606827 = formData.getOrDefault("NextToken")
  valid_606827 = validateParameter(valid_606827, JString, required = false,
                                 default = nil)
  if valid_606827 != nil:
    section.add "NextToken", valid_606827
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606828: Call_PostListSubscriptions_606815; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_606828.validator(path, query, header, formData, body)
  let scheme = call_606828.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606828.url(scheme.get, call_606828.host, call_606828.base,
                         call_606828.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606828, url, valid)

proc call*(call_606829: Call_PostListSubscriptions_606815; NextToken: string = "";
          Action: string = "ListSubscriptions"; Version: string = "2010-03-31"): Recallable =
  ## postListSubscriptions
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606830 = newJObject()
  var formData_606831 = newJObject()
  add(formData_606831, "NextToken", newJString(NextToken))
  add(query_606830, "Action", newJString(Action))
  add(query_606830, "Version", newJString(Version))
  result = call_606829.call(nil, query_606830, nil, formData_606831, nil)

var postListSubscriptions* = Call_PostListSubscriptions_606815(
    name: "postListSubscriptions", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptions",
    validator: validate_PostListSubscriptions_606816, base: "/",
    url: url_PostListSubscriptions_606817, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListSubscriptions_606799 = ref object of OpenApiRestCall_605589
proc url_GetListSubscriptions_606801(protocol: Scheme; host: string; base: string;
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

proc validate_GetListSubscriptions_606800(path: JsonNode; query: JsonNode;
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
  var valid_606802 = query.getOrDefault("NextToken")
  valid_606802 = validateParameter(valid_606802, JString, required = false,
                                 default = nil)
  if valid_606802 != nil:
    section.add "NextToken", valid_606802
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606803 = query.getOrDefault("Action")
  valid_606803 = validateParameter(valid_606803, JString, required = true,
                                 default = newJString("ListSubscriptions"))
  if valid_606803 != nil:
    section.add "Action", valid_606803
  var valid_606804 = query.getOrDefault("Version")
  valid_606804 = validateParameter(valid_606804, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606804 != nil:
    section.add "Version", valid_606804
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606805 = header.getOrDefault("X-Amz-Signature")
  valid_606805 = validateParameter(valid_606805, JString, required = false,
                                 default = nil)
  if valid_606805 != nil:
    section.add "X-Amz-Signature", valid_606805
  var valid_606806 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606806 = validateParameter(valid_606806, JString, required = false,
                                 default = nil)
  if valid_606806 != nil:
    section.add "X-Amz-Content-Sha256", valid_606806
  var valid_606807 = header.getOrDefault("X-Amz-Date")
  valid_606807 = validateParameter(valid_606807, JString, required = false,
                                 default = nil)
  if valid_606807 != nil:
    section.add "X-Amz-Date", valid_606807
  var valid_606808 = header.getOrDefault("X-Amz-Credential")
  valid_606808 = validateParameter(valid_606808, JString, required = false,
                                 default = nil)
  if valid_606808 != nil:
    section.add "X-Amz-Credential", valid_606808
  var valid_606809 = header.getOrDefault("X-Amz-Security-Token")
  valid_606809 = validateParameter(valid_606809, JString, required = false,
                                 default = nil)
  if valid_606809 != nil:
    section.add "X-Amz-Security-Token", valid_606809
  var valid_606810 = header.getOrDefault("X-Amz-Algorithm")
  valid_606810 = validateParameter(valid_606810, JString, required = false,
                                 default = nil)
  if valid_606810 != nil:
    section.add "X-Amz-Algorithm", valid_606810
  var valid_606811 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606811 = validateParameter(valid_606811, JString, required = false,
                                 default = nil)
  if valid_606811 != nil:
    section.add "X-Amz-SignedHeaders", valid_606811
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606812: Call_GetListSubscriptions_606799; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_606812.validator(path, query, header, formData, body)
  let scheme = call_606812.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606812.url(scheme.get, call_606812.host, call_606812.base,
                         call_606812.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606812, url, valid)

proc call*(call_606813: Call_GetListSubscriptions_606799; NextToken: string = "";
          Action: string = "ListSubscriptions"; Version: string = "2010-03-31"): Recallable =
  ## getListSubscriptions
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606814 = newJObject()
  add(query_606814, "NextToken", newJString(NextToken))
  add(query_606814, "Action", newJString(Action))
  add(query_606814, "Version", newJString(Version))
  result = call_606813.call(nil, query_606814, nil, nil, nil)

var getListSubscriptions* = Call_GetListSubscriptions_606799(
    name: "getListSubscriptions", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptions",
    validator: validate_GetListSubscriptions_606800, base: "/",
    url: url_GetListSubscriptions_606801, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListSubscriptionsByTopic_606849 = ref object of OpenApiRestCall_605589
proc url_PostListSubscriptionsByTopic_606851(protocol: Scheme; host: string;
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

proc validate_PostListSubscriptionsByTopic_606850(path: JsonNode; query: JsonNode;
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
  var valid_606852 = query.getOrDefault("Action")
  valid_606852 = validateParameter(valid_606852, JString, required = true, default = newJString(
      "ListSubscriptionsByTopic"))
  if valid_606852 != nil:
    section.add "Action", valid_606852
  var valid_606853 = query.getOrDefault("Version")
  valid_606853 = validateParameter(valid_606853, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606853 != nil:
    section.add "Version", valid_606853
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606854 = header.getOrDefault("X-Amz-Signature")
  valid_606854 = validateParameter(valid_606854, JString, required = false,
                                 default = nil)
  if valid_606854 != nil:
    section.add "X-Amz-Signature", valid_606854
  var valid_606855 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606855 = validateParameter(valid_606855, JString, required = false,
                                 default = nil)
  if valid_606855 != nil:
    section.add "X-Amz-Content-Sha256", valid_606855
  var valid_606856 = header.getOrDefault("X-Amz-Date")
  valid_606856 = validateParameter(valid_606856, JString, required = false,
                                 default = nil)
  if valid_606856 != nil:
    section.add "X-Amz-Date", valid_606856
  var valid_606857 = header.getOrDefault("X-Amz-Credential")
  valid_606857 = validateParameter(valid_606857, JString, required = false,
                                 default = nil)
  if valid_606857 != nil:
    section.add "X-Amz-Credential", valid_606857
  var valid_606858 = header.getOrDefault("X-Amz-Security-Token")
  valid_606858 = validateParameter(valid_606858, JString, required = false,
                                 default = nil)
  if valid_606858 != nil:
    section.add "X-Amz-Security-Token", valid_606858
  var valid_606859 = header.getOrDefault("X-Amz-Algorithm")
  valid_606859 = validateParameter(valid_606859, JString, required = false,
                                 default = nil)
  if valid_606859 != nil:
    section.add "X-Amz-Algorithm", valid_606859
  var valid_606860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606860 = validateParameter(valid_606860, JString, required = false,
                                 default = nil)
  if valid_606860 != nil:
    section.add "X-Amz-SignedHeaders", valid_606860
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListSubscriptionsByTopic</code> request.
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic for which you wish to find subscriptions.
  section = newJObject()
  var valid_606861 = formData.getOrDefault("NextToken")
  valid_606861 = validateParameter(valid_606861, JString, required = false,
                                 default = nil)
  if valid_606861 != nil:
    section.add "NextToken", valid_606861
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_606862 = formData.getOrDefault("TopicArn")
  valid_606862 = validateParameter(valid_606862, JString, required = true,
                                 default = nil)
  if valid_606862 != nil:
    section.add "TopicArn", valid_606862
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606863: Call_PostListSubscriptionsByTopic_606849; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_606863.validator(path, query, header, formData, body)
  let scheme = call_606863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606863.url(scheme.get, call_606863.host, call_606863.base,
                         call_606863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606863, url, valid)

proc call*(call_606864: Call_PostListSubscriptionsByTopic_606849; TopicArn: string;
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
  var query_606865 = newJObject()
  var formData_606866 = newJObject()
  add(formData_606866, "NextToken", newJString(NextToken))
  add(formData_606866, "TopicArn", newJString(TopicArn))
  add(query_606865, "Action", newJString(Action))
  add(query_606865, "Version", newJString(Version))
  result = call_606864.call(nil, query_606865, nil, formData_606866, nil)

var postListSubscriptionsByTopic* = Call_PostListSubscriptionsByTopic_606849(
    name: "postListSubscriptionsByTopic", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptionsByTopic",
    validator: validate_PostListSubscriptionsByTopic_606850, base: "/",
    url: url_PostListSubscriptionsByTopic_606851,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListSubscriptionsByTopic_606832 = ref object of OpenApiRestCall_605589
proc url_GetListSubscriptionsByTopic_606834(protocol: Scheme; host: string;
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

proc validate_GetListSubscriptionsByTopic_606833(path: JsonNode; query: JsonNode;
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
  ##   Version: JString (required)
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic for which you wish to find subscriptions.
  section = newJObject()
  var valid_606835 = query.getOrDefault("NextToken")
  valid_606835 = validateParameter(valid_606835, JString, required = false,
                                 default = nil)
  if valid_606835 != nil:
    section.add "NextToken", valid_606835
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606836 = query.getOrDefault("Action")
  valid_606836 = validateParameter(valid_606836, JString, required = true, default = newJString(
      "ListSubscriptionsByTopic"))
  if valid_606836 != nil:
    section.add "Action", valid_606836
  var valid_606837 = query.getOrDefault("Version")
  valid_606837 = validateParameter(valid_606837, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606837 != nil:
    section.add "Version", valid_606837
  var valid_606838 = query.getOrDefault("TopicArn")
  valid_606838 = validateParameter(valid_606838, JString, required = true,
                                 default = nil)
  if valid_606838 != nil:
    section.add "TopicArn", valid_606838
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606839 = header.getOrDefault("X-Amz-Signature")
  valid_606839 = validateParameter(valid_606839, JString, required = false,
                                 default = nil)
  if valid_606839 != nil:
    section.add "X-Amz-Signature", valid_606839
  var valid_606840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606840 = validateParameter(valid_606840, JString, required = false,
                                 default = nil)
  if valid_606840 != nil:
    section.add "X-Amz-Content-Sha256", valid_606840
  var valid_606841 = header.getOrDefault("X-Amz-Date")
  valid_606841 = validateParameter(valid_606841, JString, required = false,
                                 default = nil)
  if valid_606841 != nil:
    section.add "X-Amz-Date", valid_606841
  var valid_606842 = header.getOrDefault("X-Amz-Credential")
  valid_606842 = validateParameter(valid_606842, JString, required = false,
                                 default = nil)
  if valid_606842 != nil:
    section.add "X-Amz-Credential", valid_606842
  var valid_606843 = header.getOrDefault("X-Amz-Security-Token")
  valid_606843 = validateParameter(valid_606843, JString, required = false,
                                 default = nil)
  if valid_606843 != nil:
    section.add "X-Amz-Security-Token", valid_606843
  var valid_606844 = header.getOrDefault("X-Amz-Algorithm")
  valid_606844 = validateParameter(valid_606844, JString, required = false,
                                 default = nil)
  if valid_606844 != nil:
    section.add "X-Amz-Algorithm", valid_606844
  var valid_606845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606845 = validateParameter(valid_606845, JString, required = false,
                                 default = nil)
  if valid_606845 != nil:
    section.add "X-Amz-SignedHeaders", valid_606845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606846: Call_GetListSubscriptionsByTopic_606832; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_606846.validator(path, query, header, formData, body)
  let scheme = call_606846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606846.url(scheme.get, call_606846.host, call_606846.base,
                         call_606846.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606846, url, valid)

proc call*(call_606847: Call_GetListSubscriptionsByTopic_606832; TopicArn: string;
          NextToken: string = ""; Action: string = "ListSubscriptionsByTopic";
          Version: string = "2010-03-31"): Recallable =
  ## getListSubscriptionsByTopic
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptionsByTopic</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic for which you wish to find subscriptions.
  var query_606848 = newJObject()
  add(query_606848, "NextToken", newJString(NextToken))
  add(query_606848, "Action", newJString(Action))
  add(query_606848, "Version", newJString(Version))
  add(query_606848, "TopicArn", newJString(TopicArn))
  result = call_606847.call(nil, query_606848, nil, nil, nil)

var getListSubscriptionsByTopic* = Call_GetListSubscriptionsByTopic_606832(
    name: "getListSubscriptionsByTopic", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptionsByTopic",
    validator: validate_GetListSubscriptionsByTopic_606833, base: "/",
    url: url_GetListSubscriptionsByTopic_606834,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_606883 = ref object of OpenApiRestCall_605589
proc url_PostListTagsForResource_606885(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_PostListTagsForResource_606884(path: JsonNode; query: JsonNode;
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
  var valid_606886 = query.getOrDefault("Action")
  valid_606886 = validateParameter(valid_606886, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_606886 != nil:
    section.add "Action", valid_606886
  var valid_606887 = query.getOrDefault("Version")
  valid_606887 = validateParameter(valid_606887, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606887 != nil:
    section.add "Version", valid_606887
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606888 = header.getOrDefault("X-Amz-Signature")
  valid_606888 = validateParameter(valid_606888, JString, required = false,
                                 default = nil)
  if valid_606888 != nil:
    section.add "X-Amz-Signature", valid_606888
  var valid_606889 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606889 = validateParameter(valid_606889, JString, required = false,
                                 default = nil)
  if valid_606889 != nil:
    section.add "X-Amz-Content-Sha256", valid_606889
  var valid_606890 = header.getOrDefault("X-Amz-Date")
  valid_606890 = validateParameter(valid_606890, JString, required = false,
                                 default = nil)
  if valid_606890 != nil:
    section.add "X-Amz-Date", valid_606890
  var valid_606891 = header.getOrDefault("X-Amz-Credential")
  valid_606891 = validateParameter(valid_606891, JString, required = false,
                                 default = nil)
  if valid_606891 != nil:
    section.add "X-Amz-Credential", valid_606891
  var valid_606892 = header.getOrDefault("X-Amz-Security-Token")
  valid_606892 = validateParameter(valid_606892, JString, required = false,
                                 default = nil)
  if valid_606892 != nil:
    section.add "X-Amz-Security-Token", valid_606892
  var valid_606893 = header.getOrDefault("X-Amz-Algorithm")
  valid_606893 = validateParameter(valid_606893, JString, required = false,
                                 default = nil)
  if valid_606893 != nil:
    section.add "X-Amz-Algorithm", valid_606893
  var valid_606894 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606894 = validateParameter(valid_606894, JString, required = false,
                                 default = nil)
  if valid_606894 != nil:
    section.add "X-Amz-SignedHeaders", valid_606894
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic for which to list tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_606895 = formData.getOrDefault("ResourceArn")
  valid_606895 = validateParameter(valid_606895, JString, required = true,
                                 default = nil)
  if valid_606895 != nil:
    section.add "ResourceArn", valid_606895
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606896: Call_PostListTagsForResource_606883; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ## 
  let valid = call_606896.validator(path, query, header, formData, body)
  let scheme = call_606896.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606896.url(scheme.get, call_606896.host, call_606896.base,
                         call_606896.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606896, url, valid)

proc call*(call_606897: Call_PostListTagsForResource_606883; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-03-31"): Recallable =
  ## postListTagsForResource
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic for which to list tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606898 = newJObject()
  var formData_606899 = newJObject()
  add(formData_606899, "ResourceArn", newJString(ResourceArn))
  add(query_606898, "Action", newJString(Action))
  add(query_606898, "Version", newJString(Version))
  result = call_606897.call(nil, query_606898, nil, formData_606899, nil)

var postListTagsForResource* = Call_PostListTagsForResource_606883(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_606884, base: "/",
    url: url_PostListTagsForResource_606885, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_606867 = ref object of OpenApiRestCall_605589
proc url_GetListTagsForResource_606869(protocol: Scheme; host: string; base: string;
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

proc validate_GetListTagsForResource_606868(path: JsonNode; query: JsonNode;
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
  var valid_606870 = query.getOrDefault("ResourceArn")
  valid_606870 = validateParameter(valid_606870, JString, required = true,
                                 default = nil)
  if valid_606870 != nil:
    section.add "ResourceArn", valid_606870
  var valid_606871 = query.getOrDefault("Action")
  valid_606871 = validateParameter(valid_606871, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_606871 != nil:
    section.add "Action", valid_606871
  var valid_606872 = query.getOrDefault("Version")
  valid_606872 = validateParameter(valid_606872, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606872 != nil:
    section.add "Version", valid_606872
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606873 = header.getOrDefault("X-Amz-Signature")
  valid_606873 = validateParameter(valid_606873, JString, required = false,
                                 default = nil)
  if valid_606873 != nil:
    section.add "X-Amz-Signature", valid_606873
  var valid_606874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606874 = validateParameter(valid_606874, JString, required = false,
                                 default = nil)
  if valid_606874 != nil:
    section.add "X-Amz-Content-Sha256", valid_606874
  var valid_606875 = header.getOrDefault("X-Amz-Date")
  valid_606875 = validateParameter(valid_606875, JString, required = false,
                                 default = nil)
  if valid_606875 != nil:
    section.add "X-Amz-Date", valid_606875
  var valid_606876 = header.getOrDefault("X-Amz-Credential")
  valid_606876 = validateParameter(valid_606876, JString, required = false,
                                 default = nil)
  if valid_606876 != nil:
    section.add "X-Amz-Credential", valid_606876
  var valid_606877 = header.getOrDefault("X-Amz-Security-Token")
  valid_606877 = validateParameter(valid_606877, JString, required = false,
                                 default = nil)
  if valid_606877 != nil:
    section.add "X-Amz-Security-Token", valid_606877
  var valid_606878 = header.getOrDefault("X-Amz-Algorithm")
  valid_606878 = validateParameter(valid_606878, JString, required = false,
                                 default = nil)
  if valid_606878 != nil:
    section.add "X-Amz-Algorithm", valid_606878
  var valid_606879 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606879 = validateParameter(valid_606879, JString, required = false,
                                 default = nil)
  if valid_606879 != nil:
    section.add "X-Amz-SignedHeaders", valid_606879
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606880: Call_GetListTagsForResource_606867; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ## 
  let valid = call_606880.validator(path, query, header, formData, body)
  let scheme = call_606880.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606880.url(scheme.get, call_606880.host, call_606880.base,
                         call_606880.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606880, url, valid)

proc call*(call_606881: Call_GetListTagsForResource_606867; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-03-31"): Recallable =
  ## getListTagsForResource
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic for which to list tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606882 = newJObject()
  add(query_606882, "ResourceArn", newJString(ResourceArn))
  add(query_606882, "Action", newJString(Action))
  add(query_606882, "Version", newJString(Version))
  result = call_606881.call(nil, query_606882, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_606867(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_606868, base: "/",
    url: url_GetListTagsForResource_606869, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTopics_606916 = ref object of OpenApiRestCall_605589
proc url_PostListTopics_606918(protocol: Scheme; host: string; base: string;
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

proc validate_PostListTopics_606917(path: JsonNode; query: JsonNode;
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
  var valid_606919 = query.getOrDefault("Action")
  valid_606919 = validateParameter(valid_606919, JString, required = true,
                                 default = newJString("ListTopics"))
  if valid_606919 != nil:
    section.add "Action", valid_606919
  var valid_606920 = query.getOrDefault("Version")
  valid_606920 = validateParameter(valid_606920, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606920 != nil:
    section.add "Version", valid_606920
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606921 = header.getOrDefault("X-Amz-Signature")
  valid_606921 = validateParameter(valid_606921, JString, required = false,
                                 default = nil)
  if valid_606921 != nil:
    section.add "X-Amz-Signature", valid_606921
  var valid_606922 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606922 = validateParameter(valid_606922, JString, required = false,
                                 default = nil)
  if valid_606922 != nil:
    section.add "X-Amz-Content-Sha256", valid_606922
  var valid_606923 = header.getOrDefault("X-Amz-Date")
  valid_606923 = validateParameter(valid_606923, JString, required = false,
                                 default = nil)
  if valid_606923 != nil:
    section.add "X-Amz-Date", valid_606923
  var valid_606924 = header.getOrDefault("X-Amz-Credential")
  valid_606924 = validateParameter(valid_606924, JString, required = false,
                                 default = nil)
  if valid_606924 != nil:
    section.add "X-Amz-Credential", valid_606924
  var valid_606925 = header.getOrDefault("X-Amz-Security-Token")
  valid_606925 = validateParameter(valid_606925, JString, required = false,
                                 default = nil)
  if valid_606925 != nil:
    section.add "X-Amz-Security-Token", valid_606925
  var valid_606926 = header.getOrDefault("X-Amz-Algorithm")
  valid_606926 = validateParameter(valid_606926, JString, required = false,
                                 default = nil)
  if valid_606926 != nil:
    section.add "X-Amz-Algorithm", valid_606926
  var valid_606927 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606927 = validateParameter(valid_606927, JString, required = false,
                                 default = nil)
  if valid_606927 != nil:
    section.add "X-Amz-SignedHeaders", valid_606927
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListTopics</code> request.
  section = newJObject()
  var valid_606928 = formData.getOrDefault("NextToken")
  valid_606928 = validateParameter(valid_606928, JString, required = false,
                                 default = nil)
  if valid_606928 != nil:
    section.add "NextToken", valid_606928
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606929: Call_PostListTopics_606916; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_606929.validator(path, query, header, formData, body)
  let scheme = call_606929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606929.url(scheme.get, call_606929.host, call_606929.base,
                         call_606929.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606929, url, valid)

proc call*(call_606930: Call_PostListTopics_606916; NextToken: string = "";
          Action: string = "ListTopics"; Version: string = "2010-03-31"): Recallable =
  ## postListTopics
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListTopics</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606931 = newJObject()
  var formData_606932 = newJObject()
  add(formData_606932, "NextToken", newJString(NextToken))
  add(query_606931, "Action", newJString(Action))
  add(query_606931, "Version", newJString(Version))
  result = call_606930.call(nil, query_606931, nil, formData_606932, nil)

var postListTopics* = Call_PostListTopics_606916(name: "postListTopics",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=ListTopics", validator: validate_PostListTopics_606917,
    base: "/", url: url_PostListTopics_606918, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTopics_606900 = ref object of OpenApiRestCall_605589
proc url_GetListTopics_606902(protocol: Scheme; host: string; base: string;
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

proc validate_GetListTopics_606901(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606903 = query.getOrDefault("NextToken")
  valid_606903 = validateParameter(valid_606903, JString, required = false,
                                 default = nil)
  if valid_606903 != nil:
    section.add "NextToken", valid_606903
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606904 = query.getOrDefault("Action")
  valid_606904 = validateParameter(valid_606904, JString, required = true,
                                 default = newJString("ListTopics"))
  if valid_606904 != nil:
    section.add "Action", valid_606904
  var valid_606905 = query.getOrDefault("Version")
  valid_606905 = validateParameter(valid_606905, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606905 != nil:
    section.add "Version", valid_606905
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606906 = header.getOrDefault("X-Amz-Signature")
  valid_606906 = validateParameter(valid_606906, JString, required = false,
                                 default = nil)
  if valid_606906 != nil:
    section.add "X-Amz-Signature", valid_606906
  var valid_606907 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606907 = validateParameter(valid_606907, JString, required = false,
                                 default = nil)
  if valid_606907 != nil:
    section.add "X-Amz-Content-Sha256", valid_606907
  var valid_606908 = header.getOrDefault("X-Amz-Date")
  valid_606908 = validateParameter(valid_606908, JString, required = false,
                                 default = nil)
  if valid_606908 != nil:
    section.add "X-Amz-Date", valid_606908
  var valid_606909 = header.getOrDefault("X-Amz-Credential")
  valid_606909 = validateParameter(valid_606909, JString, required = false,
                                 default = nil)
  if valid_606909 != nil:
    section.add "X-Amz-Credential", valid_606909
  var valid_606910 = header.getOrDefault("X-Amz-Security-Token")
  valid_606910 = validateParameter(valid_606910, JString, required = false,
                                 default = nil)
  if valid_606910 != nil:
    section.add "X-Amz-Security-Token", valid_606910
  var valid_606911 = header.getOrDefault("X-Amz-Algorithm")
  valid_606911 = validateParameter(valid_606911, JString, required = false,
                                 default = nil)
  if valid_606911 != nil:
    section.add "X-Amz-Algorithm", valid_606911
  var valid_606912 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606912 = validateParameter(valid_606912, JString, required = false,
                                 default = nil)
  if valid_606912 != nil:
    section.add "X-Amz-SignedHeaders", valid_606912
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606913: Call_GetListTopics_606900; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_606913.validator(path, query, header, formData, body)
  let scheme = call_606913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606913.url(scheme.get, call_606913.host, call_606913.base,
                         call_606913.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606913, url, valid)

proc call*(call_606914: Call_GetListTopics_606900; NextToken: string = "";
          Action: string = "ListTopics"; Version: string = "2010-03-31"): Recallable =
  ## getListTopics
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListTopics</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606915 = newJObject()
  add(query_606915, "NextToken", newJString(NextToken))
  add(query_606915, "Action", newJString(Action))
  add(query_606915, "Version", newJString(Version))
  result = call_606914.call(nil, query_606915, nil, nil, nil)

var getListTopics* = Call_GetListTopics_606900(name: "getListTopics",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=ListTopics", validator: validate_GetListTopics_606901,
    base: "/", url: url_GetListTopics_606902, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostOptInPhoneNumber_606949 = ref object of OpenApiRestCall_605589
proc url_PostOptInPhoneNumber_606951(protocol: Scheme; host: string; base: string;
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

proc validate_PostOptInPhoneNumber_606950(path: JsonNode; query: JsonNode;
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
  var valid_606952 = query.getOrDefault("Action")
  valid_606952 = validateParameter(valid_606952, JString, required = true,
                                 default = newJString("OptInPhoneNumber"))
  if valid_606952 != nil:
    section.add "Action", valid_606952
  var valid_606953 = query.getOrDefault("Version")
  valid_606953 = validateParameter(valid_606953, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606953 != nil:
    section.add "Version", valid_606953
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606954 = header.getOrDefault("X-Amz-Signature")
  valid_606954 = validateParameter(valid_606954, JString, required = false,
                                 default = nil)
  if valid_606954 != nil:
    section.add "X-Amz-Signature", valid_606954
  var valid_606955 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606955 = validateParameter(valid_606955, JString, required = false,
                                 default = nil)
  if valid_606955 != nil:
    section.add "X-Amz-Content-Sha256", valid_606955
  var valid_606956 = header.getOrDefault("X-Amz-Date")
  valid_606956 = validateParameter(valid_606956, JString, required = false,
                                 default = nil)
  if valid_606956 != nil:
    section.add "X-Amz-Date", valid_606956
  var valid_606957 = header.getOrDefault("X-Amz-Credential")
  valid_606957 = validateParameter(valid_606957, JString, required = false,
                                 default = nil)
  if valid_606957 != nil:
    section.add "X-Amz-Credential", valid_606957
  var valid_606958 = header.getOrDefault("X-Amz-Security-Token")
  valid_606958 = validateParameter(valid_606958, JString, required = false,
                                 default = nil)
  if valid_606958 != nil:
    section.add "X-Amz-Security-Token", valid_606958
  var valid_606959 = header.getOrDefault("X-Amz-Algorithm")
  valid_606959 = validateParameter(valid_606959, JString, required = false,
                                 default = nil)
  if valid_606959 != nil:
    section.add "X-Amz-Algorithm", valid_606959
  var valid_606960 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606960 = validateParameter(valid_606960, JString, required = false,
                                 default = nil)
  if valid_606960 != nil:
    section.add "X-Amz-SignedHeaders", valid_606960
  result.add "header", section
  ## parameters in `formData` object:
  ##   phoneNumber: JString (required)
  ##              : The phone number to opt in.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `phoneNumber` field"
  var valid_606961 = formData.getOrDefault("phoneNumber")
  valid_606961 = validateParameter(valid_606961, JString, required = true,
                                 default = nil)
  if valid_606961 != nil:
    section.add "phoneNumber", valid_606961
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606962: Call_PostOptInPhoneNumber_606949; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ## 
  let valid = call_606962.validator(path, query, header, formData, body)
  let scheme = call_606962.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606962.url(scheme.get, call_606962.host, call_606962.base,
                         call_606962.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606962, url, valid)

proc call*(call_606963: Call_PostOptInPhoneNumber_606949; phoneNumber: string;
          Action: string = "OptInPhoneNumber"; Version: string = "2010-03-31"): Recallable =
  ## postOptInPhoneNumber
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number to opt in.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606964 = newJObject()
  var formData_606965 = newJObject()
  add(formData_606965, "phoneNumber", newJString(phoneNumber))
  add(query_606964, "Action", newJString(Action))
  add(query_606964, "Version", newJString(Version))
  result = call_606963.call(nil, query_606964, nil, formData_606965, nil)

var postOptInPhoneNumber* = Call_PostOptInPhoneNumber_606949(
    name: "postOptInPhoneNumber", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=OptInPhoneNumber",
    validator: validate_PostOptInPhoneNumber_606950, base: "/",
    url: url_PostOptInPhoneNumber_606951, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOptInPhoneNumber_606933 = ref object of OpenApiRestCall_605589
proc url_GetOptInPhoneNumber_606935(protocol: Scheme; host: string; base: string;
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

proc validate_GetOptInPhoneNumber_606934(path: JsonNode; query: JsonNode;
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
  var valid_606936 = query.getOrDefault("phoneNumber")
  valid_606936 = validateParameter(valid_606936, JString, required = true,
                                 default = nil)
  if valid_606936 != nil:
    section.add "phoneNumber", valid_606936
  var valid_606937 = query.getOrDefault("Action")
  valid_606937 = validateParameter(valid_606937, JString, required = true,
                                 default = newJString("OptInPhoneNumber"))
  if valid_606937 != nil:
    section.add "Action", valid_606937
  var valid_606938 = query.getOrDefault("Version")
  valid_606938 = validateParameter(valid_606938, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606938 != nil:
    section.add "Version", valid_606938
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606939 = header.getOrDefault("X-Amz-Signature")
  valid_606939 = validateParameter(valid_606939, JString, required = false,
                                 default = nil)
  if valid_606939 != nil:
    section.add "X-Amz-Signature", valid_606939
  var valid_606940 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606940 = validateParameter(valid_606940, JString, required = false,
                                 default = nil)
  if valid_606940 != nil:
    section.add "X-Amz-Content-Sha256", valid_606940
  var valid_606941 = header.getOrDefault("X-Amz-Date")
  valid_606941 = validateParameter(valid_606941, JString, required = false,
                                 default = nil)
  if valid_606941 != nil:
    section.add "X-Amz-Date", valid_606941
  var valid_606942 = header.getOrDefault("X-Amz-Credential")
  valid_606942 = validateParameter(valid_606942, JString, required = false,
                                 default = nil)
  if valid_606942 != nil:
    section.add "X-Amz-Credential", valid_606942
  var valid_606943 = header.getOrDefault("X-Amz-Security-Token")
  valid_606943 = validateParameter(valid_606943, JString, required = false,
                                 default = nil)
  if valid_606943 != nil:
    section.add "X-Amz-Security-Token", valid_606943
  var valid_606944 = header.getOrDefault("X-Amz-Algorithm")
  valid_606944 = validateParameter(valid_606944, JString, required = false,
                                 default = nil)
  if valid_606944 != nil:
    section.add "X-Amz-Algorithm", valid_606944
  var valid_606945 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606945 = validateParameter(valid_606945, JString, required = false,
                                 default = nil)
  if valid_606945 != nil:
    section.add "X-Amz-SignedHeaders", valid_606945
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606946: Call_GetOptInPhoneNumber_606933; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ## 
  let valid = call_606946.validator(path, query, header, formData, body)
  let scheme = call_606946.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606946.url(scheme.get, call_606946.host, call_606946.base,
                         call_606946.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606946, url, valid)

proc call*(call_606947: Call_GetOptInPhoneNumber_606933; phoneNumber: string;
          Action: string = "OptInPhoneNumber"; Version: string = "2010-03-31"): Recallable =
  ## getOptInPhoneNumber
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number to opt in.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606948 = newJObject()
  add(query_606948, "phoneNumber", newJString(phoneNumber))
  add(query_606948, "Action", newJString(Action))
  add(query_606948, "Version", newJString(Version))
  result = call_606947.call(nil, query_606948, nil, nil, nil)

var getOptInPhoneNumber* = Call_GetOptInPhoneNumber_606933(
    name: "getOptInPhoneNumber", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=OptInPhoneNumber",
    validator: validate_GetOptInPhoneNumber_606934, base: "/",
    url: url_GetOptInPhoneNumber_606935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPublish_606993 = ref object of OpenApiRestCall_605589
proc url_PostPublish_606995(protocol: Scheme; host: string; base: string;
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

proc validate_PostPublish_606994(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606996 = query.getOrDefault("Action")
  valid_606996 = validateParameter(valid_606996, JString, required = true,
                                 default = newJString("Publish"))
  if valid_606996 != nil:
    section.add "Action", valid_606996
  var valid_606997 = query.getOrDefault("Version")
  valid_606997 = validateParameter(valid_606997, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606997 != nil:
    section.add "Version", valid_606997
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606998 = header.getOrDefault("X-Amz-Signature")
  valid_606998 = validateParameter(valid_606998, JString, required = false,
                                 default = nil)
  if valid_606998 != nil:
    section.add "X-Amz-Signature", valid_606998
  var valid_606999 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606999 = validateParameter(valid_606999, JString, required = false,
                                 default = nil)
  if valid_606999 != nil:
    section.add "X-Amz-Content-Sha256", valid_606999
  var valid_607000 = header.getOrDefault("X-Amz-Date")
  valid_607000 = validateParameter(valid_607000, JString, required = false,
                                 default = nil)
  if valid_607000 != nil:
    section.add "X-Amz-Date", valid_607000
  var valid_607001 = header.getOrDefault("X-Amz-Credential")
  valid_607001 = validateParameter(valid_607001, JString, required = false,
                                 default = nil)
  if valid_607001 != nil:
    section.add "X-Amz-Credential", valid_607001
  var valid_607002 = header.getOrDefault("X-Amz-Security-Token")
  valid_607002 = validateParameter(valid_607002, JString, required = false,
                                 default = nil)
  if valid_607002 != nil:
    section.add "X-Amz-Security-Token", valid_607002
  var valid_607003 = header.getOrDefault("X-Amz-Algorithm")
  valid_607003 = validateParameter(valid_607003, JString, required = false,
                                 default = nil)
  if valid_607003 != nil:
    section.add "X-Amz-Algorithm", valid_607003
  var valid_607004 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607004 = validateParameter(valid_607004, JString, required = false,
                                 default = nil)
  if valid_607004 != nil:
    section.add "X-Amz-SignedHeaders", valid_607004
  result.add "header", section
  ## parameters in `formData` object:
  ##   MessageAttributes.1.key: JString
  ##   PhoneNumber: JString
  ##              : <p>The phone number to which you want to deliver an SMS message. Use E.164 format.</p> <p>If you don't specify a value for the <code>PhoneNumber</code> parameter, you must specify a value for the <code>TargetArn</code> or <code>TopicArn</code> parameters.</p>
  ##   MessageAttributes.2.value: JString
  ##   Subject: JString
  ##          : <p>Optional parameter to be used as the "Subject" line when the message is delivered to email endpoints. This field will also be included, if present, in the standard JSON messages delivered to other endpoints.</p> <p>Constraints: Subjects must be ASCII text that begins with a letter, number, or punctuation mark; must not include line breaks or control characters; and must be less than 100 characters long.</p>
  ##   MessageAttributes.0.value: JString
  ##   MessageAttributes.0.key: JString
  ##   MessageAttributes.2.key: JString
  ##   Message: JString (required)
  ##          : <p>The message you want to send.</p> <p>If you are publishing to a topic and you want to send the same message to all transport protocols, include the text of the message as a String value. If you want to send different messages for each transport protocol, set the value of the <code>MessageStructure</code> parameter to <code>json</code> and use a JSON object for the <code>Message</code> parameter. </p> <p/> <p>Constraints:</p> <ul> <li> <p>With the exception of SMS, messages must be UTF-8 encoded strings and at most 256 KB in size (262,144 bytes, not 262,144 characters).</p> </li> <li> <p>For SMS, each message can contain up to 140 characters. This character limit depends on the encoding schema. For example, an SMS message can contain 160 GSM characters, 140 ASCII characters, or 70 UCS-2 characters.</p> <p>If you publish a message that exceeds this size limit, Amazon SNS sends the message as multiple messages, each fitting within the size limit. Messages aren't truncated mid-word but are cut off at whole-word boundaries.</p> <p>The total size limit for a single SMS <code>Publish</code> action is 1,600 characters.</p> </li> </ul> <p>JSON-specific constraints:</p> <ul> <li> <p>Keys in the JSON object that correspond to supported transport protocols must have simple JSON string values.</p> </li> <li> <p>The values will be parsed (unescaped) before they are used in outgoing messages.</p> </li> <li> <p>Outbound notifications are JSON encoded (meaning that the characters will be reescaped for sending).</p> </li> <li> <p>Values have a minimum length of 0 (the empty string, "", is allowed).</p> </li> <li> <p>Values have a maximum length bounded by the overall message size (so, including multiple protocols may limit message sizes).</p> </li> <li> <p>Non-string values will cause the key to be ignored.</p> </li> <li> <p>Keys that do not correspond to supported transport protocols are ignored.</p> </li> <li> <p>Duplicate keys are not allowed.</p> </li> <li> <p>Failure to parse or validate any key or value in the message will cause the <code>Publish</code> call to return an error (no partial delivery).</p> </li> </ul>
  ##   TopicArn: JString
  ##           : <p>The topic you want to publish to.</p> <p>If you don't specify a value for the <code>TopicArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TargetArn</code> parameters.</p>
  ##   MessageStructure: JString
  ##                   : <p>Set <code>MessageStructure</code> to <code>json</code> if you want to send a different message for each protocol. For example, using one publish action, you can send a short message to your SMS subscribers and a longer message to your email subscribers. If you set <code>MessageStructure</code> to <code>json</code>, the value of the <code>Message</code> parameter must: </p> <ul> <li> <p>be a syntactically valid JSON object; and</p> </li> <li> <p>contain at least a top-level JSON key of "default" with a value that is a string.</p> </li> </ul> <p>You can define other top-level keys that define the message you want to send to a specific transport protocol (e.g., "http").</p> <p>Valid value: <code>json</code> </p>
  ##   MessageAttributes.1.value: JString
  ##   TargetArn: JString
  ##            : If you don't specify a value for the <code>TargetArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TopicArn</code> parameters.
  section = newJObject()
  var valid_607005 = formData.getOrDefault("MessageAttributes.1.key")
  valid_607005 = validateParameter(valid_607005, JString, required = false,
                                 default = nil)
  if valid_607005 != nil:
    section.add "MessageAttributes.1.key", valid_607005
  var valid_607006 = formData.getOrDefault("PhoneNumber")
  valid_607006 = validateParameter(valid_607006, JString, required = false,
                                 default = nil)
  if valid_607006 != nil:
    section.add "PhoneNumber", valid_607006
  var valid_607007 = formData.getOrDefault("MessageAttributes.2.value")
  valid_607007 = validateParameter(valid_607007, JString, required = false,
                                 default = nil)
  if valid_607007 != nil:
    section.add "MessageAttributes.2.value", valid_607007
  var valid_607008 = formData.getOrDefault("Subject")
  valid_607008 = validateParameter(valid_607008, JString, required = false,
                                 default = nil)
  if valid_607008 != nil:
    section.add "Subject", valid_607008
  var valid_607009 = formData.getOrDefault("MessageAttributes.0.value")
  valid_607009 = validateParameter(valid_607009, JString, required = false,
                                 default = nil)
  if valid_607009 != nil:
    section.add "MessageAttributes.0.value", valid_607009
  var valid_607010 = formData.getOrDefault("MessageAttributes.0.key")
  valid_607010 = validateParameter(valid_607010, JString, required = false,
                                 default = nil)
  if valid_607010 != nil:
    section.add "MessageAttributes.0.key", valid_607010
  var valid_607011 = formData.getOrDefault("MessageAttributes.2.key")
  valid_607011 = validateParameter(valid_607011, JString, required = false,
                                 default = nil)
  if valid_607011 != nil:
    section.add "MessageAttributes.2.key", valid_607011
  assert formData != nil,
        "formData argument is necessary due to required `Message` field"
  var valid_607012 = formData.getOrDefault("Message")
  valid_607012 = validateParameter(valid_607012, JString, required = true,
                                 default = nil)
  if valid_607012 != nil:
    section.add "Message", valid_607012
  var valid_607013 = formData.getOrDefault("TopicArn")
  valid_607013 = validateParameter(valid_607013, JString, required = false,
                                 default = nil)
  if valid_607013 != nil:
    section.add "TopicArn", valid_607013
  var valid_607014 = formData.getOrDefault("MessageStructure")
  valid_607014 = validateParameter(valid_607014, JString, required = false,
                                 default = nil)
  if valid_607014 != nil:
    section.add "MessageStructure", valid_607014
  var valid_607015 = formData.getOrDefault("MessageAttributes.1.value")
  valid_607015 = validateParameter(valid_607015, JString, required = false,
                                 default = nil)
  if valid_607015 != nil:
    section.add "MessageAttributes.1.value", valid_607015
  var valid_607016 = formData.getOrDefault("TargetArn")
  valid_607016 = validateParameter(valid_607016, JString, required = false,
                                 default = nil)
  if valid_607016 != nil:
    section.add "TargetArn", valid_607016
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607017: Call_PostPublish_606993; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  let valid = call_607017.validator(path, query, header, formData, body)
  let scheme = call_607017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607017.url(scheme.get, call_607017.host, call_607017.base,
                         call_607017.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607017, url, valid)

proc call*(call_607018: Call_PostPublish_606993; Message: string;
          MessageAttributes1Key: string = ""; PhoneNumber: string = "";
          MessageAttributes2Value: string = ""; Subject: string = "";
          MessageAttributes0Value: string = ""; MessageAttributes0Key: string = "";
          MessageAttributes2Key: string = ""; TopicArn: string = "";
          Action: string = "Publish"; MessageStructure: string = "";
          MessageAttributes1Value: string = ""; TargetArn: string = "";
          Version: string = "2010-03-31"): Recallable =
  ## postPublish
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ##   MessageAttributes1Key: string
  ##   PhoneNumber: string
  ##              : <p>The phone number to which you want to deliver an SMS message. Use E.164 format.</p> <p>If you don't specify a value for the <code>PhoneNumber</code> parameter, you must specify a value for the <code>TargetArn</code> or <code>TopicArn</code> parameters.</p>
  ##   MessageAttributes2Value: string
  ##   Subject: string
  ##          : <p>Optional parameter to be used as the "Subject" line when the message is delivered to email endpoints. This field will also be included, if present, in the standard JSON messages delivered to other endpoints.</p> <p>Constraints: Subjects must be ASCII text that begins with a letter, number, or punctuation mark; must not include line breaks or control characters; and must be less than 100 characters long.</p>
  ##   MessageAttributes0Value: string
  ##   MessageAttributes0Key: string
  ##   MessageAttributes2Key: string
  ##   Message: string (required)
  ##          : <p>The message you want to send.</p> <p>If you are publishing to a topic and you want to send the same message to all transport protocols, include the text of the message as a String value. If you want to send different messages for each transport protocol, set the value of the <code>MessageStructure</code> parameter to <code>json</code> and use a JSON object for the <code>Message</code> parameter. </p> <p/> <p>Constraints:</p> <ul> <li> <p>With the exception of SMS, messages must be UTF-8 encoded strings and at most 256 KB in size (262,144 bytes, not 262,144 characters).</p> </li> <li> <p>For SMS, each message can contain up to 140 characters. This character limit depends on the encoding schema. For example, an SMS message can contain 160 GSM characters, 140 ASCII characters, or 70 UCS-2 characters.</p> <p>If you publish a message that exceeds this size limit, Amazon SNS sends the message as multiple messages, each fitting within the size limit. Messages aren't truncated mid-word but are cut off at whole-word boundaries.</p> <p>The total size limit for a single SMS <code>Publish</code> action is 1,600 characters.</p> </li> </ul> <p>JSON-specific constraints:</p> <ul> <li> <p>Keys in the JSON object that correspond to supported transport protocols must have simple JSON string values.</p> </li> <li> <p>The values will be parsed (unescaped) before they are used in outgoing messages.</p> </li> <li> <p>Outbound notifications are JSON encoded (meaning that the characters will be reescaped for sending).</p> </li> <li> <p>Values have a minimum length of 0 (the empty string, "", is allowed).</p> </li> <li> <p>Values have a maximum length bounded by the overall message size (so, including multiple protocols may limit message sizes).</p> </li> <li> <p>Non-string values will cause the key to be ignored.</p> </li> <li> <p>Keys that do not correspond to supported transport protocols are ignored.</p> </li> <li> <p>Duplicate keys are not allowed.</p> </li> <li> <p>Failure to parse or validate any key or value in the message will cause the <code>Publish</code> call to return an error (no partial delivery).</p> </li> </ul>
  ##   TopicArn: string
  ##           : <p>The topic you want to publish to.</p> <p>If you don't specify a value for the <code>TopicArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TargetArn</code> parameters.</p>
  ##   Action: string (required)
  ##   MessageStructure: string
  ##                   : <p>Set <code>MessageStructure</code> to <code>json</code> if you want to send a different message for each protocol. For example, using one publish action, you can send a short message to your SMS subscribers and a longer message to your email subscribers. If you set <code>MessageStructure</code> to <code>json</code>, the value of the <code>Message</code> parameter must: </p> <ul> <li> <p>be a syntactically valid JSON object; and</p> </li> <li> <p>contain at least a top-level JSON key of "default" with a value that is a string.</p> </li> </ul> <p>You can define other top-level keys that define the message you want to send to a specific transport protocol (e.g., "http").</p> <p>Valid value: <code>json</code> </p>
  ##   MessageAttributes1Value: string
  ##   TargetArn: string
  ##            : If you don't specify a value for the <code>TargetArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TopicArn</code> parameters.
  ##   Version: string (required)
  var query_607019 = newJObject()
  var formData_607020 = newJObject()
  add(formData_607020, "MessageAttributes.1.key",
      newJString(MessageAttributes1Key))
  add(formData_607020, "PhoneNumber", newJString(PhoneNumber))
  add(formData_607020, "MessageAttributes.2.value",
      newJString(MessageAttributes2Value))
  add(formData_607020, "Subject", newJString(Subject))
  add(formData_607020, "MessageAttributes.0.value",
      newJString(MessageAttributes0Value))
  add(formData_607020, "MessageAttributes.0.key",
      newJString(MessageAttributes0Key))
  add(formData_607020, "MessageAttributes.2.key",
      newJString(MessageAttributes2Key))
  add(formData_607020, "Message", newJString(Message))
  add(formData_607020, "TopicArn", newJString(TopicArn))
  add(query_607019, "Action", newJString(Action))
  add(formData_607020, "MessageStructure", newJString(MessageStructure))
  add(formData_607020, "MessageAttributes.1.value",
      newJString(MessageAttributes1Value))
  add(formData_607020, "TargetArn", newJString(TargetArn))
  add(query_607019, "Version", newJString(Version))
  result = call_607018.call(nil, query_607019, nil, formData_607020, nil)

var postPublish* = Call_PostPublish_606993(name: "postPublish",
                                        meth: HttpMethod.HttpPost,
                                        host: "sns.amazonaws.com",
                                        route: "/#Action=Publish",
                                        validator: validate_PostPublish_606994,
                                        base: "/", url: url_PostPublish_606995,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublish_606966 = ref object of OpenApiRestCall_605589
proc url_GetPublish_606968(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPublish_606967(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PhoneNumber: JString
  ##              : <p>The phone number to which you want to deliver an SMS message. Use E.164 format.</p> <p>If you don't specify a value for the <code>PhoneNumber</code> parameter, you must specify a value for the <code>TargetArn</code> or <code>TopicArn</code> parameters.</p>
  ##   MessageStructure: JString
  ##                   : <p>Set <code>MessageStructure</code> to <code>json</code> if you want to send a different message for each protocol. For example, using one publish action, you can send a short message to your SMS subscribers and a longer message to your email subscribers. If you set <code>MessageStructure</code> to <code>json</code>, the value of the <code>Message</code> parameter must: </p> <ul> <li> <p>be a syntactically valid JSON object; and</p> </li> <li> <p>contain at least a top-level JSON key of "default" with a value that is a string.</p> </li> </ul> <p>You can define other top-level keys that define the message you want to send to a specific transport protocol (e.g., "http").</p> <p>Valid value: <code>json</code> </p>
  ##   MessageAttributes.0.value: JString
  ##   MessageAttributes.2.key: JString
  ##   Message: JString (required)
  ##          : <p>The message you want to send.</p> <p>If you are publishing to a topic and you want to send the same message to all transport protocols, include the text of the message as a String value. If you want to send different messages for each transport protocol, set the value of the <code>MessageStructure</code> parameter to <code>json</code> and use a JSON object for the <code>Message</code> parameter. </p> <p/> <p>Constraints:</p> <ul> <li> <p>With the exception of SMS, messages must be UTF-8 encoded strings and at most 256 KB in size (262,144 bytes, not 262,144 characters).</p> </li> <li> <p>For SMS, each message can contain up to 140 characters. This character limit depends on the encoding schema. For example, an SMS message can contain 160 GSM characters, 140 ASCII characters, or 70 UCS-2 characters.</p> <p>If you publish a message that exceeds this size limit, Amazon SNS sends the message as multiple messages, each fitting within the size limit. Messages aren't truncated mid-word but are cut off at whole-word boundaries.</p> <p>The total size limit for a single SMS <code>Publish</code> action is 1,600 characters.</p> </li> </ul> <p>JSON-specific constraints:</p> <ul> <li> <p>Keys in the JSON object that correspond to supported transport protocols must have simple JSON string values.</p> </li> <li> <p>The values will be parsed (unescaped) before they are used in outgoing messages.</p> </li> <li> <p>Outbound notifications are JSON encoded (meaning that the characters will be reescaped for sending).</p> </li> <li> <p>Values have a minimum length of 0 (the empty string, "", is allowed).</p> </li> <li> <p>Values have a maximum length bounded by the overall message size (so, including multiple protocols may limit message sizes).</p> </li> <li> <p>Non-string values will cause the key to be ignored.</p> </li> <li> <p>Keys that do not correspond to supported transport protocols are ignored.</p> </li> <li> <p>Duplicate keys are not allowed.</p> </li> <li> <p>Failure to parse or validate any key or value in the message will cause the <code>Publish</code> call to return an error (no partial delivery).</p> </li> </ul>
  ##   MessageAttributes.2.value: JString
  ##   Action: JString (required)
  ##   MessageAttributes.1.key: JString
  ##   MessageAttributes.0.key: JString
  ##   Subject: JString
  ##          : <p>Optional parameter to be used as the "Subject" line when the message is delivered to email endpoints. This field will also be included, if present, in the standard JSON messages delivered to other endpoints.</p> <p>Constraints: Subjects must be ASCII text that begins with a letter, number, or punctuation mark; must not include line breaks or control characters; and must be less than 100 characters long.</p>
  ##   MessageAttributes.1.value: JString
  ##   Version: JString (required)
  ##   TargetArn: JString
  ##            : If you don't specify a value for the <code>TargetArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TopicArn</code> parameters.
  ##   TopicArn: JString
  ##           : <p>The topic you want to publish to.</p> <p>If you don't specify a value for the <code>TopicArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TargetArn</code> parameters.</p>
  section = newJObject()
  var valid_606969 = query.getOrDefault("PhoneNumber")
  valid_606969 = validateParameter(valid_606969, JString, required = false,
                                 default = nil)
  if valid_606969 != nil:
    section.add "PhoneNumber", valid_606969
  var valid_606970 = query.getOrDefault("MessageStructure")
  valid_606970 = validateParameter(valid_606970, JString, required = false,
                                 default = nil)
  if valid_606970 != nil:
    section.add "MessageStructure", valid_606970
  var valid_606971 = query.getOrDefault("MessageAttributes.0.value")
  valid_606971 = validateParameter(valid_606971, JString, required = false,
                                 default = nil)
  if valid_606971 != nil:
    section.add "MessageAttributes.0.value", valid_606971
  var valid_606972 = query.getOrDefault("MessageAttributes.2.key")
  valid_606972 = validateParameter(valid_606972, JString, required = false,
                                 default = nil)
  if valid_606972 != nil:
    section.add "MessageAttributes.2.key", valid_606972
  assert query != nil, "query argument is necessary due to required `Message` field"
  var valid_606973 = query.getOrDefault("Message")
  valid_606973 = validateParameter(valid_606973, JString, required = true,
                                 default = nil)
  if valid_606973 != nil:
    section.add "Message", valid_606973
  var valid_606974 = query.getOrDefault("MessageAttributes.2.value")
  valid_606974 = validateParameter(valid_606974, JString, required = false,
                                 default = nil)
  if valid_606974 != nil:
    section.add "MessageAttributes.2.value", valid_606974
  var valid_606975 = query.getOrDefault("Action")
  valid_606975 = validateParameter(valid_606975, JString, required = true,
                                 default = newJString("Publish"))
  if valid_606975 != nil:
    section.add "Action", valid_606975
  var valid_606976 = query.getOrDefault("MessageAttributes.1.key")
  valid_606976 = validateParameter(valid_606976, JString, required = false,
                                 default = nil)
  if valid_606976 != nil:
    section.add "MessageAttributes.1.key", valid_606976
  var valid_606977 = query.getOrDefault("MessageAttributes.0.key")
  valid_606977 = validateParameter(valid_606977, JString, required = false,
                                 default = nil)
  if valid_606977 != nil:
    section.add "MessageAttributes.0.key", valid_606977
  var valid_606978 = query.getOrDefault("Subject")
  valid_606978 = validateParameter(valid_606978, JString, required = false,
                                 default = nil)
  if valid_606978 != nil:
    section.add "Subject", valid_606978
  var valid_606979 = query.getOrDefault("MessageAttributes.1.value")
  valid_606979 = validateParameter(valid_606979, JString, required = false,
                                 default = nil)
  if valid_606979 != nil:
    section.add "MessageAttributes.1.value", valid_606979
  var valid_606980 = query.getOrDefault("Version")
  valid_606980 = validateParameter(valid_606980, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_606980 != nil:
    section.add "Version", valid_606980
  var valid_606981 = query.getOrDefault("TargetArn")
  valid_606981 = validateParameter(valid_606981, JString, required = false,
                                 default = nil)
  if valid_606981 != nil:
    section.add "TargetArn", valid_606981
  var valid_606982 = query.getOrDefault("TopicArn")
  valid_606982 = validateParameter(valid_606982, JString, required = false,
                                 default = nil)
  if valid_606982 != nil:
    section.add "TopicArn", valid_606982
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606983 = header.getOrDefault("X-Amz-Signature")
  valid_606983 = validateParameter(valid_606983, JString, required = false,
                                 default = nil)
  if valid_606983 != nil:
    section.add "X-Amz-Signature", valid_606983
  var valid_606984 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606984 = validateParameter(valid_606984, JString, required = false,
                                 default = nil)
  if valid_606984 != nil:
    section.add "X-Amz-Content-Sha256", valid_606984
  var valid_606985 = header.getOrDefault("X-Amz-Date")
  valid_606985 = validateParameter(valid_606985, JString, required = false,
                                 default = nil)
  if valid_606985 != nil:
    section.add "X-Amz-Date", valid_606985
  var valid_606986 = header.getOrDefault("X-Amz-Credential")
  valid_606986 = validateParameter(valid_606986, JString, required = false,
                                 default = nil)
  if valid_606986 != nil:
    section.add "X-Amz-Credential", valid_606986
  var valid_606987 = header.getOrDefault("X-Amz-Security-Token")
  valid_606987 = validateParameter(valid_606987, JString, required = false,
                                 default = nil)
  if valid_606987 != nil:
    section.add "X-Amz-Security-Token", valid_606987
  var valid_606988 = header.getOrDefault("X-Amz-Algorithm")
  valid_606988 = validateParameter(valid_606988, JString, required = false,
                                 default = nil)
  if valid_606988 != nil:
    section.add "X-Amz-Algorithm", valid_606988
  var valid_606989 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606989 = validateParameter(valid_606989, JString, required = false,
                                 default = nil)
  if valid_606989 != nil:
    section.add "X-Amz-SignedHeaders", valid_606989
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606990: Call_GetPublish_606966; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  let valid = call_606990.validator(path, query, header, formData, body)
  let scheme = call_606990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606990.url(scheme.get, call_606990.host, call_606990.base,
                         call_606990.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606990, url, valid)

proc call*(call_606991: Call_GetPublish_606966; Message: string;
          PhoneNumber: string = ""; MessageStructure: string = "";
          MessageAttributes0Value: string = ""; MessageAttributes2Key: string = "";
          MessageAttributes2Value: string = ""; Action: string = "Publish";
          MessageAttributes1Key: string = ""; MessageAttributes0Key: string = "";
          Subject: string = ""; MessageAttributes1Value: string = "";
          Version: string = "2010-03-31"; TargetArn: string = ""; TopicArn: string = ""): Recallable =
  ## getPublish
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ##   PhoneNumber: string
  ##              : <p>The phone number to which you want to deliver an SMS message. Use E.164 format.</p> <p>If you don't specify a value for the <code>PhoneNumber</code> parameter, you must specify a value for the <code>TargetArn</code> or <code>TopicArn</code> parameters.</p>
  ##   MessageStructure: string
  ##                   : <p>Set <code>MessageStructure</code> to <code>json</code> if you want to send a different message for each protocol. For example, using one publish action, you can send a short message to your SMS subscribers and a longer message to your email subscribers. If you set <code>MessageStructure</code> to <code>json</code>, the value of the <code>Message</code> parameter must: </p> <ul> <li> <p>be a syntactically valid JSON object; and</p> </li> <li> <p>contain at least a top-level JSON key of "default" with a value that is a string.</p> </li> </ul> <p>You can define other top-level keys that define the message you want to send to a specific transport protocol (e.g., "http").</p> <p>Valid value: <code>json</code> </p>
  ##   MessageAttributes0Value: string
  ##   MessageAttributes2Key: string
  ##   Message: string (required)
  ##          : <p>The message you want to send.</p> <p>If you are publishing to a topic and you want to send the same message to all transport protocols, include the text of the message as a String value. If you want to send different messages for each transport protocol, set the value of the <code>MessageStructure</code> parameter to <code>json</code> and use a JSON object for the <code>Message</code> parameter. </p> <p/> <p>Constraints:</p> <ul> <li> <p>With the exception of SMS, messages must be UTF-8 encoded strings and at most 256 KB in size (262,144 bytes, not 262,144 characters).</p> </li> <li> <p>For SMS, each message can contain up to 140 characters. This character limit depends on the encoding schema. For example, an SMS message can contain 160 GSM characters, 140 ASCII characters, or 70 UCS-2 characters.</p> <p>If you publish a message that exceeds this size limit, Amazon SNS sends the message as multiple messages, each fitting within the size limit. Messages aren't truncated mid-word but are cut off at whole-word boundaries.</p> <p>The total size limit for a single SMS <code>Publish</code> action is 1,600 characters.</p> </li> </ul> <p>JSON-specific constraints:</p> <ul> <li> <p>Keys in the JSON object that correspond to supported transport protocols must have simple JSON string values.</p> </li> <li> <p>The values will be parsed (unescaped) before they are used in outgoing messages.</p> </li> <li> <p>Outbound notifications are JSON encoded (meaning that the characters will be reescaped for sending).</p> </li> <li> <p>Values have a minimum length of 0 (the empty string, "", is allowed).</p> </li> <li> <p>Values have a maximum length bounded by the overall message size (so, including multiple protocols may limit message sizes).</p> </li> <li> <p>Non-string values will cause the key to be ignored.</p> </li> <li> <p>Keys that do not correspond to supported transport protocols are ignored.</p> </li> <li> <p>Duplicate keys are not allowed.</p> </li> <li> <p>Failure to parse or validate any key or value in the message will cause the <code>Publish</code> call to return an error (no partial delivery).</p> </li> </ul>
  ##   MessageAttributes2Value: string
  ##   Action: string (required)
  ##   MessageAttributes1Key: string
  ##   MessageAttributes0Key: string
  ##   Subject: string
  ##          : <p>Optional parameter to be used as the "Subject" line when the message is delivered to email endpoints. This field will also be included, if present, in the standard JSON messages delivered to other endpoints.</p> <p>Constraints: Subjects must be ASCII text that begins with a letter, number, or punctuation mark; must not include line breaks or control characters; and must be less than 100 characters long.</p>
  ##   MessageAttributes1Value: string
  ##   Version: string (required)
  ##   TargetArn: string
  ##            : If you don't specify a value for the <code>TargetArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TopicArn</code> parameters.
  ##   TopicArn: string
  ##           : <p>The topic you want to publish to.</p> <p>If you don't specify a value for the <code>TopicArn</code> parameter, you must specify a value for the <code>PhoneNumber</code> or <code>TargetArn</code> parameters.</p>
  var query_606992 = newJObject()
  add(query_606992, "PhoneNumber", newJString(PhoneNumber))
  add(query_606992, "MessageStructure", newJString(MessageStructure))
  add(query_606992, "MessageAttributes.0.value",
      newJString(MessageAttributes0Value))
  add(query_606992, "MessageAttributes.2.key", newJString(MessageAttributes2Key))
  add(query_606992, "Message", newJString(Message))
  add(query_606992, "MessageAttributes.2.value",
      newJString(MessageAttributes2Value))
  add(query_606992, "Action", newJString(Action))
  add(query_606992, "MessageAttributes.1.key", newJString(MessageAttributes1Key))
  add(query_606992, "MessageAttributes.0.key", newJString(MessageAttributes0Key))
  add(query_606992, "Subject", newJString(Subject))
  add(query_606992, "MessageAttributes.1.value",
      newJString(MessageAttributes1Value))
  add(query_606992, "Version", newJString(Version))
  add(query_606992, "TargetArn", newJString(TargetArn))
  add(query_606992, "TopicArn", newJString(TopicArn))
  result = call_606991.call(nil, query_606992, nil, nil, nil)

var getPublish* = Call_GetPublish_606966(name: "getPublish",
                                      meth: HttpMethod.HttpGet,
                                      host: "sns.amazonaws.com",
                                      route: "/#Action=Publish",
                                      validator: validate_GetPublish_606967,
                                      base: "/", url: url_GetPublish_606968,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemovePermission_607038 = ref object of OpenApiRestCall_605589
proc url_PostRemovePermission_607040(protocol: Scheme; host: string; base: string;
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

proc validate_PostRemovePermission_607039(path: JsonNode; query: JsonNode;
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
  var valid_607041 = query.getOrDefault("Action")
  valid_607041 = validateParameter(valid_607041, JString, required = true,
                                 default = newJString("RemovePermission"))
  if valid_607041 != nil:
    section.add "Action", valid_607041
  var valid_607042 = query.getOrDefault("Version")
  valid_607042 = validateParameter(valid_607042, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_607042 != nil:
    section.add "Version", valid_607042
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607043 = header.getOrDefault("X-Amz-Signature")
  valid_607043 = validateParameter(valid_607043, JString, required = false,
                                 default = nil)
  if valid_607043 != nil:
    section.add "X-Amz-Signature", valid_607043
  var valid_607044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607044 = validateParameter(valid_607044, JString, required = false,
                                 default = nil)
  if valid_607044 != nil:
    section.add "X-Amz-Content-Sha256", valid_607044
  var valid_607045 = header.getOrDefault("X-Amz-Date")
  valid_607045 = validateParameter(valid_607045, JString, required = false,
                                 default = nil)
  if valid_607045 != nil:
    section.add "X-Amz-Date", valid_607045
  var valid_607046 = header.getOrDefault("X-Amz-Credential")
  valid_607046 = validateParameter(valid_607046, JString, required = false,
                                 default = nil)
  if valid_607046 != nil:
    section.add "X-Amz-Credential", valid_607046
  var valid_607047 = header.getOrDefault("X-Amz-Security-Token")
  valid_607047 = validateParameter(valid_607047, JString, required = false,
                                 default = nil)
  if valid_607047 != nil:
    section.add "X-Amz-Security-Token", valid_607047
  var valid_607048 = header.getOrDefault("X-Amz-Algorithm")
  valid_607048 = validateParameter(valid_607048, JString, required = false,
                                 default = nil)
  if valid_607048 != nil:
    section.add "X-Amz-Algorithm", valid_607048
  var valid_607049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607049 = validateParameter(valid_607049, JString, required = false,
                                 default = nil)
  if valid_607049 != nil:
    section.add "X-Amz-SignedHeaders", valid_607049
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Label: JString (required)
  ##        : The unique label of the statement you want to remove.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_607050 = formData.getOrDefault("TopicArn")
  valid_607050 = validateParameter(valid_607050, JString, required = true,
                                 default = nil)
  if valid_607050 != nil:
    section.add "TopicArn", valid_607050
  var valid_607051 = formData.getOrDefault("Label")
  valid_607051 = validateParameter(valid_607051, JString, required = true,
                                 default = nil)
  if valid_607051 != nil:
    section.add "Label", valid_607051
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607052: Call_PostRemovePermission_607038; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a statement from a topic's access control policy.
  ## 
  let valid = call_607052.validator(path, query, header, formData, body)
  let scheme = call_607052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607052.url(scheme.get, call_607052.host, call_607052.base,
                         call_607052.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607052, url, valid)

proc call*(call_607053: Call_PostRemovePermission_607038; TopicArn: string;
          Label: string; Action: string = "RemovePermission";
          Version: string = "2010-03-31"): Recallable =
  ## postRemovePermission
  ## Removes a statement from a topic's access control policy.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Action: string (required)
  ##   Label: string (required)
  ##        : The unique label of the statement you want to remove.
  ##   Version: string (required)
  var query_607054 = newJObject()
  var formData_607055 = newJObject()
  add(formData_607055, "TopicArn", newJString(TopicArn))
  add(query_607054, "Action", newJString(Action))
  add(formData_607055, "Label", newJString(Label))
  add(query_607054, "Version", newJString(Version))
  result = call_607053.call(nil, query_607054, nil, formData_607055, nil)

var postRemovePermission* = Call_PostRemovePermission_607038(
    name: "postRemovePermission", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=RemovePermission",
    validator: validate_PostRemovePermission_607039, base: "/",
    url: url_PostRemovePermission_607040, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemovePermission_607021 = ref object of OpenApiRestCall_605589
proc url_GetRemovePermission_607023(protocol: Scheme; host: string; base: string;
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

proc validate_GetRemovePermission_607022(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Removes a statement from a topic's access control policy.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Label: JString (required)
  ##        : The unique label of the statement you want to remove.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `TopicArn` field"
  var valid_607024 = query.getOrDefault("TopicArn")
  valid_607024 = validateParameter(valid_607024, JString, required = true,
                                 default = nil)
  if valid_607024 != nil:
    section.add "TopicArn", valid_607024
  var valid_607025 = query.getOrDefault("Action")
  valid_607025 = validateParameter(valid_607025, JString, required = true,
                                 default = newJString("RemovePermission"))
  if valid_607025 != nil:
    section.add "Action", valid_607025
  var valid_607026 = query.getOrDefault("Version")
  valid_607026 = validateParameter(valid_607026, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_607026 != nil:
    section.add "Version", valid_607026
  var valid_607027 = query.getOrDefault("Label")
  valid_607027 = validateParameter(valid_607027, JString, required = true,
                                 default = nil)
  if valid_607027 != nil:
    section.add "Label", valid_607027
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607028 = header.getOrDefault("X-Amz-Signature")
  valid_607028 = validateParameter(valid_607028, JString, required = false,
                                 default = nil)
  if valid_607028 != nil:
    section.add "X-Amz-Signature", valid_607028
  var valid_607029 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607029 = validateParameter(valid_607029, JString, required = false,
                                 default = nil)
  if valid_607029 != nil:
    section.add "X-Amz-Content-Sha256", valid_607029
  var valid_607030 = header.getOrDefault("X-Amz-Date")
  valid_607030 = validateParameter(valid_607030, JString, required = false,
                                 default = nil)
  if valid_607030 != nil:
    section.add "X-Amz-Date", valid_607030
  var valid_607031 = header.getOrDefault("X-Amz-Credential")
  valid_607031 = validateParameter(valid_607031, JString, required = false,
                                 default = nil)
  if valid_607031 != nil:
    section.add "X-Amz-Credential", valid_607031
  var valid_607032 = header.getOrDefault("X-Amz-Security-Token")
  valid_607032 = validateParameter(valid_607032, JString, required = false,
                                 default = nil)
  if valid_607032 != nil:
    section.add "X-Amz-Security-Token", valid_607032
  var valid_607033 = header.getOrDefault("X-Amz-Algorithm")
  valid_607033 = validateParameter(valid_607033, JString, required = false,
                                 default = nil)
  if valid_607033 != nil:
    section.add "X-Amz-Algorithm", valid_607033
  var valid_607034 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607034 = validateParameter(valid_607034, JString, required = false,
                                 default = nil)
  if valid_607034 != nil:
    section.add "X-Amz-SignedHeaders", valid_607034
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607035: Call_GetRemovePermission_607021; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a statement from a topic's access control policy.
  ## 
  let valid = call_607035.validator(path, query, header, formData, body)
  let scheme = call_607035.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607035.url(scheme.get, call_607035.host, call_607035.base,
                         call_607035.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607035, url, valid)

proc call*(call_607036: Call_GetRemovePermission_607021; TopicArn: string;
          Label: string; Action: string = "RemovePermission";
          Version: string = "2010-03-31"): Recallable =
  ## getRemovePermission
  ## Removes a statement from a topic's access control policy.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Label: string (required)
  ##        : The unique label of the statement you want to remove.
  var query_607037 = newJObject()
  add(query_607037, "TopicArn", newJString(TopicArn))
  add(query_607037, "Action", newJString(Action))
  add(query_607037, "Version", newJString(Version))
  add(query_607037, "Label", newJString(Label))
  result = call_607036.call(nil, query_607037, nil, nil, nil)

var getRemovePermission* = Call_GetRemovePermission_607021(
    name: "getRemovePermission", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=RemovePermission",
    validator: validate_GetRemovePermission_607022, base: "/",
    url: url_GetRemovePermission_607023, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetEndpointAttributes_607078 = ref object of OpenApiRestCall_605589
proc url_PostSetEndpointAttributes_607080(protocol: Scheme; host: string;
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

proc validate_PostSetEndpointAttributes_607079(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607081 = query.getOrDefault("Action")
  valid_607081 = validateParameter(valid_607081, JString, required = true,
                                 default = newJString("SetEndpointAttributes"))
  if valid_607081 != nil:
    section.add "Action", valid_607081
  var valid_607082 = query.getOrDefault("Version")
  valid_607082 = validateParameter(valid_607082, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_607082 != nil:
    section.add "Version", valid_607082
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607083 = header.getOrDefault("X-Amz-Signature")
  valid_607083 = validateParameter(valid_607083, JString, required = false,
                                 default = nil)
  if valid_607083 != nil:
    section.add "X-Amz-Signature", valid_607083
  var valid_607084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607084 = validateParameter(valid_607084, JString, required = false,
                                 default = nil)
  if valid_607084 != nil:
    section.add "X-Amz-Content-Sha256", valid_607084
  var valid_607085 = header.getOrDefault("X-Amz-Date")
  valid_607085 = validateParameter(valid_607085, JString, required = false,
                                 default = nil)
  if valid_607085 != nil:
    section.add "X-Amz-Date", valid_607085
  var valid_607086 = header.getOrDefault("X-Amz-Credential")
  valid_607086 = validateParameter(valid_607086, JString, required = false,
                                 default = nil)
  if valid_607086 != nil:
    section.add "X-Amz-Credential", valid_607086
  var valid_607087 = header.getOrDefault("X-Amz-Security-Token")
  valid_607087 = validateParameter(valid_607087, JString, required = false,
                                 default = nil)
  if valid_607087 != nil:
    section.add "X-Amz-Security-Token", valid_607087
  var valid_607088 = header.getOrDefault("X-Amz-Algorithm")
  valid_607088 = validateParameter(valid_607088, JString, required = false,
                                 default = nil)
  if valid_607088 != nil:
    section.add "X-Amz-Algorithm", valid_607088
  var valid_607089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607089 = validateParameter(valid_607089, JString, required = false,
                                 default = nil)
  if valid_607089 != nil:
    section.add "X-Amz-SignedHeaders", valid_607089
  result.add "header", section
  ## parameters in `formData` object:
  ##   Attributes.0.key: JString
  ##   EndpointArn: JString (required)
  ##              : EndpointArn used for SetEndpointAttributes action.
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   Attributes.0.value: JString
  ##   Attributes.1.key: JString
  ##   Attributes.1.value: JString
  section = newJObject()
  var valid_607090 = formData.getOrDefault("Attributes.0.key")
  valid_607090 = validateParameter(valid_607090, JString, required = false,
                                 default = nil)
  if valid_607090 != nil:
    section.add "Attributes.0.key", valid_607090
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_607091 = formData.getOrDefault("EndpointArn")
  valid_607091 = validateParameter(valid_607091, JString, required = true,
                                 default = nil)
  if valid_607091 != nil:
    section.add "EndpointArn", valid_607091
  var valid_607092 = formData.getOrDefault("Attributes.2.value")
  valid_607092 = validateParameter(valid_607092, JString, required = false,
                                 default = nil)
  if valid_607092 != nil:
    section.add "Attributes.2.value", valid_607092
  var valid_607093 = formData.getOrDefault("Attributes.2.key")
  valid_607093 = validateParameter(valid_607093, JString, required = false,
                                 default = nil)
  if valid_607093 != nil:
    section.add "Attributes.2.key", valid_607093
  var valid_607094 = formData.getOrDefault("Attributes.0.value")
  valid_607094 = validateParameter(valid_607094, JString, required = false,
                                 default = nil)
  if valid_607094 != nil:
    section.add "Attributes.0.value", valid_607094
  var valid_607095 = formData.getOrDefault("Attributes.1.key")
  valid_607095 = validateParameter(valid_607095, JString, required = false,
                                 default = nil)
  if valid_607095 != nil:
    section.add "Attributes.1.key", valid_607095
  var valid_607096 = formData.getOrDefault("Attributes.1.value")
  valid_607096 = validateParameter(valid_607096, JString, required = false,
                                 default = nil)
  if valid_607096 != nil:
    section.add "Attributes.1.value", valid_607096
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607097: Call_PostSetEndpointAttributes_607078; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_607097.validator(path, query, header, formData, body)
  let scheme = call_607097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607097.url(scheme.get, call_607097.host, call_607097.base,
                         call_607097.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607097, url, valid)

proc call*(call_607098: Call_PostSetEndpointAttributes_607078; EndpointArn: string;
          Attributes0Key: string = ""; Attributes2Value: string = "";
          Attributes2Key: string = ""; Attributes0Value: string = "";
          Attributes1Key: string = ""; Action: string = "SetEndpointAttributes";
          Version: string = "2010-03-31"; Attributes1Value: string = ""): Recallable =
  ## postSetEndpointAttributes
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Attributes0Key: string
  ##   EndpointArn: string (required)
  ##              : EndpointArn used for SetEndpointAttributes action.
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   Attributes0Value: string
  ##   Attributes1Key: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_607099 = newJObject()
  var formData_607100 = newJObject()
  add(formData_607100, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_607100, "EndpointArn", newJString(EndpointArn))
  add(formData_607100, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_607100, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_607100, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_607100, "Attributes.1.key", newJString(Attributes1Key))
  add(query_607099, "Action", newJString(Action))
  add(query_607099, "Version", newJString(Version))
  add(formData_607100, "Attributes.1.value", newJString(Attributes1Value))
  result = call_607098.call(nil, query_607099, nil, formData_607100, nil)

var postSetEndpointAttributes* = Call_PostSetEndpointAttributes_607078(
    name: "postSetEndpointAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetEndpointAttributes",
    validator: validate_PostSetEndpointAttributes_607079, base: "/",
    url: url_PostSetEndpointAttributes_607080,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetEndpointAttributes_607056 = ref object of OpenApiRestCall_605589
proc url_GetSetEndpointAttributes_607058(protocol: Scheme; host: string;
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

proc validate_GetSetEndpointAttributes_607057(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes.1.key: JString
  ##   Attributes.0.value: JString
  ##   Attributes.0.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.1.value: JString
  ##   Action: JString (required)
  ##   EndpointArn: JString (required)
  ##              : EndpointArn used for SetEndpointAttributes action.
  ##   Version: JString (required)
  ##   Attributes.2.key: JString
  section = newJObject()
  var valid_607059 = query.getOrDefault("Attributes.1.key")
  valid_607059 = validateParameter(valid_607059, JString, required = false,
                                 default = nil)
  if valid_607059 != nil:
    section.add "Attributes.1.key", valid_607059
  var valid_607060 = query.getOrDefault("Attributes.0.value")
  valid_607060 = validateParameter(valid_607060, JString, required = false,
                                 default = nil)
  if valid_607060 != nil:
    section.add "Attributes.0.value", valid_607060
  var valid_607061 = query.getOrDefault("Attributes.0.key")
  valid_607061 = validateParameter(valid_607061, JString, required = false,
                                 default = nil)
  if valid_607061 != nil:
    section.add "Attributes.0.key", valid_607061
  var valid_607062 = query.getOrDefault("Attributes.2.value")
  valid_607062 = validateParameter(valid_607062, JString, required = false,
                                 default = nil)
  if valid_607062 != nil:
    section.add "Attributes.2.value", valid_607062
  var valid_607063 = query.getOrDefault("Attributes.1.value")
  valid_607063 = validateParameter(valid_607063, JString, required = false,
                                 default = nil)
  if valid_607063 != nil:
    section.add "Attributes.1.value", valid_607063
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607064 = query.getOrDefault("Action")
  valid_607064 = validateParameter(valid_607064, JString, required = true,
                                 default = newJString("SetEndpointAttributes"))
  if valid_607064 != nil:
    section.add "Action", valid_607064
  var valid_607065 = query.getOrDefault("EndpointArn")
  valid_607065 = validateParameter(valid_607065, JString, required = true,
                                 default = nil)
  if valid_607065 != nil:
    section.add "EndpointArn", valid_607065
  var valid_607066 = query.getOrDefault("Version")
  valid_607066 = validateParameter(valid_607066, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_607066 != nil:
    section.add "Version", valid_607066
  var valid_607067 = query.getOrDefault("Attributes.2.key")
  valid_607067 = validateParameter(valid_607067, JString, required = false,
                                 default = nil)
  if valid_607067 != nil:
    section.add "Attributes.2.key", valid_607067
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607068 = header.getOrDefault("X-Amz-Signature")
  valid_607068 = validateParameter(valid_607068, JString, required = false,
                                 default = nil)
  if valid_607068 != nil:
    section.add "X-Amz-Signature", valid_607068
  var valid_607069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607069 = validateParameter(valid_607069, JString, required = false,
                                 default = nil)
  if valid_607069 != nil:
    section.add "X-Amz-Content-Sha256", valid_607069
  var valid_607070 = header.getOrDefault("X-Amz-Date")
  valid_607070 = validateParameter(valid_607070, JString, required = false,
                                 default = nil)
  if valid_607070 != nil:
    section.add "X-Amz-Date", valid_607070
  var valid_607071 = header.getOrDefault("X-Amz-Credential")
  valid_607071 = validateParameter(valid_607071, JString, required = false,
                                 default = nil)
  if valid_607071 != nil:
    section.add "X-Amz-Credential", valid_607071
  var valid_607072 = header.getOrDefault("X-Amz-Security-Token")
  valid_607072 = validateParameter(valid_607072, JString, required = false,
                                 default = nil)
  if valid_607072 != nil:
    section.add "X-Amz-Security-Token", valid_607072
  var valid_607073 = header.getOrDefault("X-Amz-Algorithm")
  valid_607073 = validateParameter(valid_607073, JString, required = false,
                                 default = nil)
  if valid_607073 != nil:
    section.add "X-Amz-Algorithm", valid_607073
  var valid_607074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607074 = validateParameter(valid_607074, JString, required = false,
                                 default = nil)
  if valid_607074 != nil:
    section.add "X-Amz-SignedHeaders", valid_607074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607075: Call_GetSetEndpointAttributes_607056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_607075.validator(path, query, header, formData, body)
  let scheme = call_607075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607075.url(scheme.get, call_607075.host, call_607075.base,
                         call_607075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607075, url, valid)

proc call*(call_607076: Call_GetSetEndpointAttributes_607056; EndpointArn: string;
          Attributes1Key: string = ""; Attributes0Value: string = "";
          Attributes0Key: string = ""; Attributes2Value: string = "";
          Attributes1Value: string = ""; Action: string = "SetEndpointAttributes";
          Version: string = "2010-03-31"; Attributes2Key: string = ""): Recallable =
  ## getSetEndpointAttributes
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Attributes1Key: string
  ##   Attributes0Value: string
  ##   Attributes0Key: string
  ##   Attributes2Value: string
  ##   Attributes1Value: string
  ##   Action: string (required)
  ##   EndpointArn: string (required)
  ##              : EndpointArn used for SetEndpointAttributes action.
  ##   Version: string (required)
  ##   Attributes2Key: string
  var query_607077 = newJObject()
  add(query_607077, "Attributes.1.key", newJString(Attributes1Key))
  add(query_607077, "Attributes.0.value", newJString(Attributes0Value))
  add(query_607077, "Attributes.0.key", newJString(Attributes0Key))
  add(query_607077, "Attributes.2.value", newJString(Attributes2Value))
  add(query_607077, "Attributes.1.value", newJString(Attributes1Value))
  add(query_607077, "Action", newJString(Action))
  add(query_607077, "EndpointArn", newJString(EndpointArn))
  add(query_607077, "Version", newJString(Version))
  add(query_607077, "Attributes.2.key", newJString(Attributes2Key))
  result = call_607076.call(nil, query_607077, nil, nil, nil)

var getSetEndpointAttributes* = Call_GetSetEndpointAttributes_607056(
    name: "getSetEndpointAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetEndpointAttributes",
    validator: validate_GetSetEndpointAttributes_607057, base: "/",
    url: url_GetSetEndpointAttributes_607058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetPlatformApplicationAttributes_607123 = ref object of OpenApiRestCall_605589
proc url_PostSetPlatformApplicationAttributes_607125(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetPlatformApplicationAttributes_607124(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607126 = query.getOrDefault("Action")
  valid_607126 = validateParameter(valid_607126, JString, required = true, default = newJString(
      "SetPlatformApplicationAttributes"))
  if valid_607126 != nil:
    section.add "Action", valid_607126
  var valid_607127 = query.getOrDefault("Version")
  valid_607127 = validateParameter(valid_607127, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_607127 != nil:
    section.add "Version", valid_607127
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607128 = header.getOrDefault("X-Amz-Signature")
  valid_607128 = validateParameter(valid_607128, JString, required = false,
                                 default = nil)
  if valid_607128 != nil:
    section.add "X-Amz-Signature", valid_607128
  var valid_607129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607129 = validateParameter(valid_607129, JString, required = false,
                                 default = nil)
  if valid_607129 != nil:
    section.add "X-Amz-Content-Sha256", valid_607129
  var valid_607130 = header.getOrDefault("X-Amz-Date")
  valid_607130 = validateParameter(valid_607130, JString, required = false,
                                 default = nil)
  if valid_607130 != nil:
    section.add "X-Amz-Date", valid_607130
  var valid_607131 = header.getOrDefault("X-Amz-Credential")
  valid_607131 = validateParameter(valid_607131, JString, required = false,
                                 default = nil)
  if valid_607131 != nil:
    section.add "X-Amz-Credential", valid_607131
  var valid_607132 = header.getOrDefault("X-Amz-Security-Token")
  valid_607132 = validateParameter(valid_607132, JString, required = false,
                                 default = nil)
  if valid_607132 != nil:
    section.add "X-Amz-Security-Token", valid_607132
  var valid_607133 = header.getOrDefault("X-Amz-Algorithm")
  valid_607133 = validateParameter(valid_607133, JString, required = false,
                                 default = nil)
  if valid_607133 != nil:
    section.add "X-Amz-Algorithm", valid_607133
  var valid_607134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607134 = validateParameter(valid_607134, JString, required = false,
                                 default = nil)
  if valid_607134 != nil:
    section.add "X-Amz-SignedHeaders", valid_607134
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for SetPlatformApplicationAttributes action.
  ##   Attributes.0.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   Attributes.0.value: JString
  ##   Attributes.1.key: JString
  ##   Attributes.1.value: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_607135 = formData.getOrDefault("PlatformApplicationArn")
  valid_607135 = validateParameter(valid_607135, JString, required = true,
                                 default = nil)
  if valid_607135 != nil:
    section.add "PlatformApplicationArn", valid_607135
  var valid_607136 = formData.getOrDefault("Attributes.0.key")
  valid_607136 = validateParameter(valid_607136, JString, required = false,
                                 default = nil)
  if valid_607136 != nil:
    section.add "Attributes.0.key", valid_607136
  var valid_607137 = formData.getOrDefault("Attributes.2.value")
  valid_607137 = validateParameter(valid_607137, JString, required = false,
                                 default = nil)
  if valid_607137 != nil:
    section.add "Attributes.2.value", valid_607137
  var valid_607138 = formData.getOrDefault("Attributes.2.key")
  valid_607138 = validateParameter(valid_607138, JString, required = false,
                                 default = nil)
  if valid_607138 != nil:
    section.add "Attributes.2.key", valid_607138
  var valid_607139 = formData.getOrDefault("Attributes.0.value")
  valid_607139 = validateParameter(valid_607139, JString, required = false,
                                 default = nil)
  if valid_607139 != nil:
    section.add "Attributes.0.value", valid_607139
  var valid_607140 = formData.getOrDefault("Attributes.1.key")
  valid_607140 = validateParameter(valid_607140, JString, required = false,
                                 default = nil)
  if valid_607140 != nil:
    section.add "Attributes.1.key", valid_607140
  var valid_607141 = formData.getOrDefault("Attributes.1.value")
  valid_607141 = validateParameter(valid_607141, JString, required = false,
                                 default = nil)
  if valid_607141 != nil:
    section.add "Attributes.1.value", valid_607141
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607142: Call_PostSetPlatformApplicationAttributes_607123;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  let valid = call_607142.validator(path, query, header, formData, body)
  let scheme = call_607142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607142.url(scheme.get, call_607142.host, call_607142.base,
                         call_607142.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607142, url, valid)

proc call*(call_607143: Call_PostSetPlatformApplicationAttributes_607123;
          PlatformApplicationArn: string; Attributes0Key: string = "";
          Attributes2Value: string = ""; Attributes2Key: string = "";
          Attributes0Value: string = ""; Attributes1Key: string = "";
          Action: string = "SetPlatformApplicationAttributes";
          Version: string = "2010-03-31"; Attributes1Value: string = ""): Recallable =
  ## postSetPlatformApplicationAttributes
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for SetPlatformApplicationAttributes action.
  ##   Attributes0Key: string
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   Attributes0Value: string
  ##   Attributes1Key: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_607144 = newJObject()
  var formData_607145 = newJObject()
  add(formData_607145, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(formData_607145, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_607145, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_607145, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_607145, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_607145, "Attributes.1.key", newJString(Attributes1Key))
  add(query_607144, "Action", newJString(Action))
  add(query_607144, "Version", newJString(Version))
  add(formData_607145, "Attributes.1.value", newJString(Attributes1Value))
  result = call_607143.call(nil, query_607144, nil, formData_607145, nil)

var postSetPlatformApplicationAttributes* = Call_PostSetPlatformApplicationAttributes_607123(
    name: "postSetPlatformApplicationAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetPlatformApplicationAttributes",
    validator: validate_PostSetPlatformApplicationAttributes_607124, base: "/",
    url: url_PostSetPlatformApplicationAttributes_607125,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetPlatformApplicationAttributes_607101 = ref object of OpenApiRestCall_605589
proc url_GetSetPlatformApplicationAttributes_607103(protocol: Scheme; host: string;
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

proc validate_GetSetPlatformApplicationAttributes_607102(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes.1.key: JString
  ##   Attributes.0.value: JString
  ##   Attributes.0.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.1.value: JString
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for SetPlatformApplicationAttributes action.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Attributes.2.key: JString
  section = newJObject()
  var valid_607104 = query.getOrDefault("Attributes.1.key")
  valid_607104 = validateParameter(valid_607104, JString, required = false,
                                 default = nil)
  if valid_607104 != nil:
    section.add "Attributes.1.key", valid_607104
  var valid_607105 = query.getOrDefault("Attributes.0.value")
  valid_607105 = validateParameter(valid_607105, JString, required = false,
                                 default = nil)
  if valid_607105 != nil:
    section.add "Attributes.0.value", valid_607105
  var valid_607106 = query.getOrDefault("Attributes.0.key")
  valid_607106 = validateParameter(valid_607106, JString, required = false,
                                 default = nil)
  if valid_607106 != nil:
    section.add "Attributes.0.key", valid_607106
  var valid_607107 = query.getOrDefault("Attributes.2.value")
  valid_607107 = validateParameter(valid_607107, JString, required = false,
                                 default = nil)
  if valid_607107 != nil:
    section.add "Attributes.2.value", valid_607107
  var valid_607108 = query.getOrDefault("Attributes.1.value")
  valid_607108 = validateParameter(valid_607108, JString, required = false,
                                 default = nil)
  if valid_607108 != nil:
    section.add "Attributes.1.value", valid_607108
  assert query != nil, "query argument is necessary due to required `PlatformApplicationArn` field"
  var valid_607109 = query.getOrDefault("PlatformApplicationArn")
  valid_607109 = validateParameter(valid_607109, JString, required = true,
                                 default = nil)
  if valid_607109 != nil:
    section.add "PlatformApplicationArn", valid_607109
  var valid_607110 = query.getOrDefault("Action")
  valid_607110 = validateParameter(valid_607110, JString, required = true, default = newJString(
      "SetPlatformApplicationAttributes"))
  if valid_607110 != nil:
    section.add "Action", valid_607110
  var valid_607111 = query.getOrDefault("Version")
  valid_607111 = validateParameter(valid_607111, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_607111 != nil:
    section.add "Version", valid_607111
  var valid_607112 = query.getOrDefault("Attributes.2.key")
  valid_607112 = validateParameter(valid_607112, JString, required = false,
                                 default = nil)
  if valid_607112 != nil:
    section.add "Attributes.2.key", valid_607112
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607113 = header.getOrDefault("X-Amz-Signature")
  valid_607113 = validateParameter(valid_607113, JString, required = false,
                                 default = nil)
  if valid_607113 != nil:
    section.add "X-Amz-Signature", valid_607113
  var valid_607114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607114 = validateParameter(valid_607114, JString, required = false,
                                 default = nil)
  if valid_607114 != nil:
    section.add "X-Amz-Content-Sha256", valid_607114
  var valid_607115 = header.getOrDefault("X-Amz-Date")
  valid_607115 = validateParameter(valid_607115, JString, required = false,
                                 default = nil)
  if valid_607115 != nil:
    section.add "X-Amz-Date", valid_607115
  var valid_607116 = header.getOrDefault("X-Amz-Credential")
  valid_607116 = validateParameter(valid_607116, JString, required = false,
                                 default = nil)
  if valid_607116 != nil:
    section.add "X-Amz-Credential", valid_607116
  var valid_607117 = header.getOrDefault("X-Amz-Security-Token")
  valid_607117 = validateParameter(valid_607117, JString, required = false,
                                 default = nil)
  if valid_607117 != nil:
    section.add "X-Amz-Security-Token", valid_607117
  var valid_607118 = header.getOrDefault("X-Amz-Algorithm")
  valid_607118 = validateParameter(valid_607118, JString, required = false,
                                 default = nil)
  if valid_607118 != nil:
    section.add "X-Amz-Algorithm", valid_607118
  var valid_607119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607119 = validateParameter(valid_607119, JString, required = false,
                                 default = nil)
  if valid_607119 != nil:
    section.add "X-Amz-SignedHeaders", valid_607119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607120: Call_GetSetPlatformApplicationAttributes_607101;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  let valid = call_607120.validator(path, query, header, formData, body)
  let scheme = call_607120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607120.url(scheme.get, call_607120.host, call_607120.base,
                         call_607120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607120, url, valid)

proc call*(call_607121: Call_GetSetPlatformApplicationAttributes_607101;
          PlatformApplicationArn: string; Attributes1Key: string = "";
          Attributes0Value: string = ""; Attributes0Key: string = "";
          Attributes2Value: string = ""; Attributes1Value: string = "";
          Action: string = "SetPlatformApplicationAttributes";
          Version: string = "2010-03-31"; Attributes2Key: string = ""): Recallable =
  ## getSetPlatformApplicationAttributes
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ##   Attributes1Key: string
  ##   Attributes0Value: string
  ##   Attributes0Key: string
  ##   Attributes2Value: string
  ##   Attributes1Value: string
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for SetPlatformApplicationAttributes action.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Attributes2Key: string
  var query_607122 = newJObject()
  add(query_607122, "Attributes.1.key", newJString(Attributes1Key))
  add(query_607122, "Attributes.0.value", newJString(Attributes0Value))
  add(query_607122, "Attributes.0.key", newJString(Attributes0Key))
  add(query_607122, "Attributes.2.value", newJString(Attributes2Value))
  add(query_607122, "Attributes.1.value", newJString(Attributes1Value))
  add(query_607122, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  add(query_607122, "Action", newJString(Action))
  add(query_607122, "Version", newJString(Version))
  add(query_607122, "Attributes.2.key", newJString(Attributes2Key))
  result = call_607121.call(nil, query_607122, nil, nil, nil)

var getSetPlatformApplicationAttributes* = Call_GetSetPlatformApplicationAttributes_607101(
    name: "getSetPlatformApplicationAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetPlatformApplicationAttributes",
    validator: validate_GetSetPlatformApplicationAttributes_607102, base: "/",
    url: url_GetSetPlatformApplicationAttributes_607103,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSMSAttributes_607167 = ref object of OpenApiRestCall_605589
proc url_PostSetSMSAttributes_607169(protocol: Scheme; host: string; base: string;
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

proc validate_PostSetSMSAttributes_607168(path: JsonNode; query: JsonNode;
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
  var valid_607170 = query.getOrDefault("Action")
  valid_607170 = validateParameter(valid_607170, JString, required = true,
                                 default = newJString("SetSMSAttributes"))
  if valid_607170 != nil:
    section.add "Action", valid_607170
  var valid_607171 = query.getOrDefault("Version")
  valid_607171 = validateParameter(valid_607171, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_607171 != nil:
    section.add "Version", valid_607171
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607172 = header.getOrDefault("X-Amz-Signature")
  valid_607172 = validateParameter(valid_607172, JString, required = false,
                                 default = nil)
  if valid_607172 != nil:
    section.add "X-Amz-Signature", valid_607172
  var valid_607173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607173 = validateParameter(valid_607173, JString, required = false,
                                 default = nil)
  if valid_607173 != nil:
    section.add "X-Amz-Content-Sha256", valid_607173
  var valid_607174 = header.getOrDefault("X-Amz-Date")
  valid_607174 = validateParameter(valid_607174, JString, required = false,
                                 default = nil)
  if valid_607174 != nil:
    section.add "X-Amz-Date", valid_607174
  var valid_607175 = header.getOrDefault("X-Amz-Credential")
  valid_607175 = validateParameter(valid_607175, JString, required = false,
                                 default = nil)
  if valid_607175 != nil:
    section.add "X-Amz-Credential", valid_607175
  var valid_607176 = header.getOrDefault("X-Amz-Security-Token")
  valid_607176 = validateParameter(valid_607176, JString, required = false,
                                 default = nil)
  if valid_607176 != nil:
    section.add "X-Amz-Security-Token", valid_607176
  var valid_607177 = header.getOrDefault("X-Amz-Algorithm")
  valid_607177 = validateParameter(valid_607177, JString, required = false,
                                 default = nil)
  if valid_607177 != nil:
    section.add "X-Amz-Algorithm", valid_607177
  var valid_607178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607178 = validateParameter(valid_607178, JString, required = false,
                                 default = nil)
  if valid_607178 != nil:
    section.add "X-Amz-SignedHeaders", valid_607178
  result.add "header", section
  ## parameters in `formData` object:
  ##   attributes.1.key: JString
  ##   attributes.1.value: JString
  ##   attributes.2.key: JString
  ##   attributes.0.value: JString
  ##   attributes.0.key: JString
  ##   attributes.2.value: JString
  section = newJObject()
  var valid_607179 = formData.getOrDefault("attributes.1.key")
  valid_607179 = validateParameter(valid_607179, JString, required = false,
                                 default = nil)
  if valid_607179 != nil:
    section.add "attributes.1.key", valid_607179
  var valid_607180 = formData.getOrDefault("attributes.1.value")
  valid_607180 = validateParameter(valid_607180, JString, required = false,
                                 default = nil)
  if valid_607180 != nil:
    section.add "attributes.1.value", valid_607180
  var valid_607181 = formData.getOrDefault("attributes.2.key")
  valid_607181 = validateParameter(valid_607181, JString, required = false,
                                 default = nil)
  if valid_607181 != nil:
    section.add "attributes.2.key", valid_607181
  var valid_607182 = formData.getOrDefault("attributes.0.value")
  valid_607182 = validateParameter(valid_607182, JString, required = false,
                                 default = nil)
  if valid_607182 != nil:
    section.add "attributes.0.value", valid_607182
  var valid_607183 = formData.getOrDefault("attributes.0.key")
  valid_607183 = validateParameter(valid_607183, JString, required = false,
                                 default = nil)
  if valid_607183 != nil:
    section.add "attributes.0.key", valid_607183
  var valid_607184 = formData.getOrDefault("attributes.2.value")
  valid_607184 = validateParameter(valid_607184, JString, required = false,
                                 default = nil)
  if valid_607184 != nil:
    section.add "attributes.2.value", valid_607184
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607185: Call_PostSetSMSAttributes_607167; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_607185.validator(path, query, header, formData, body)
  let scheme = call_607185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607185.url(scheme.get, call_607185.host, call_607185.base,
                         call_607185.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607185, url, valid)

proc call*(call_607186: Call_PostSetSMSAttributes_607167;
          attributes1Key: string = ""; attributes1Value: string = "";
          attributes2Key: string = ""; attributes0Value: string = "";
          Action: string = "SetSMSAttributes"; Version: string = "2010-03-31";
          attributes0Key: string = ""; attributes2Value: string = ""): Recallable =
  ## postSetSMSAttributes
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ##   attributes1Key: string
  ##   attributes1Value: string
  ##   attributes2Key: string
  ##   attributes0Value: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   attributes0Key: string
  ##   attributes2Value: string
  var query_607187 = newJObject()
  var formData_607188 = newJObject()
  add(formData_607188, "attributes.1.key", newJString(attributes1Key))
  add(formData_607188, "attributes.1.value", newJString(attributes1Value))
  add(formData_607188, "attributes.2.key", newJString(attributes2Key))
  add(formData_607188, "attributes.0.value", newJString(attributes0Value))
  add(query_607187, "Action", newJString(Action))
  add(query_607187, "Version", newJString(Version))
  add(formData_607188, "attributes.0.key", newJString(attributes0Key))
  add(formData_607188, "attributes.2.value", newJString(attributes2Value))
  result = call_607186.call(nil, query_607187, nil, formData_607188, nil)

var postSetSMSAttributes* = Call_PostSetSMSAttributes_607167(
    name: "postSetSMSAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetSMSAttributes",
    validator: validate_PostSetSMSAttributes_607168, base: "/",
    url: url_PostSetSMSAttributes_607169, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSMSAttributes_607146 = ref object of OpenApiRestCall_605589
proc url_GetSetSMSAttributes_607148(protocol: Scheme; host: string; base: string;
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

proc validate_GetSetSMSAttributes_607147(path: JsonNode; query: JsonNode;
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
  ##   attributes.0.key: JString
  ##   Action: JString (required)
  ##   attributes.1.key: JString
  ##   attributes.0.value: JString
  ##   Version: JString (required)
  ##   attributes.1.value: JString
  ##   attributes.2.value: JString
  section = newJObject()
  var valid_607149 = query.getOrDefault("attributes.2.key")
  valid_607149 = validateParameter(valid_607149, JString, required = false,
                                 default = nil)
  if valid_607149 != nil:
    section.add "attributes.2.key", valid_607149
  var valid_607150 = query.getOrDefault("attributes.0.key")
  valid_607150 = validateParameter(valid_607150, JString, required = false,
                                 default = nil)
  if valid_607150 != nil:
    section.add "attributes.0.key", valid_607150
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607151 = query.getOrDefault("Action")
  valid_607151 = validateParameter(valid_607151, JString, required = true,
                                 default = newJString("SetSMSAttributes"))
  if valid_607151 != nil:
    section.add "Action", valid_607151
  var valid_607152 = query.getOrDefault("attributes.1.key")
  valid_607152 = validateParameter(valid_607152, JString, required = false,
                                 default = nil)
  if valid_607152 != nil:
    section.add "attributes.1.key", valid_607152
  var valid_607153 = query.getOrDefault("attributes.0.value")
  valid_607153 = validateParameter(valid_607153, JString, required = false,
                                 default = nil)
  if valid_607153 != nil:
    section.add "attributes.0.value", valid_607153
  var valid_607154 = query.getOrDefault("Version")
  valid_607154 = validateParameter(valid_607154, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_607154 != nil:
    section.add "Version", valid_607154
  var valid_607155 = query.getOrDefault("attributes.1.value")
  valid_607155 = validateParameter(valid_607155, JString, required = false,
                                 default = nil)
  if valid_607155 != nil:
    section.add "attributes.1.value", valid_607155
  var valid_607156 = query.getOrDefault("attributes.2.value")
  valid_607156 = validateParameter(valid_607156, JString, required = false,
                                 default = nil)
  if valid_607156 != nil:
    section.add "attributes.2.value", valid_607156
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607157 = header.getOrDefault("X-Amz-Signature")
  valid_607157 = validateParameter(valid_607157, JString, required = false,
                                 default = nil)
  if valid_607157 != nil:
    section.add "X-Amz-Signature", valid_607157
  var valid_607158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607158 = validateParameter(valid_607158, JString, required = false,
                                 default = nil)
  if valid_607158 != nil:
    section.add "X-Amz-Content-Sha256", valid_607158
  var valid_607159 = header.getOrDefault("X-Amz-Date")
  valid_607159 = validateParameter(valid_607159, JString, required = false,
                                 default = nil)
  if valid_607159 != nil:
    section.add "X-Amz-Date", valid_607159
  var valid_607160 = header.getOrDefault("X-Amz-Credential")
  valid_607160 = validateParameter(valid_607160, JString, required = false,
                                 default = nil)
  if valid_607160 != nil:
    section.add "X-Amz-Credential", valid_607160
  var valid_607161 = header.getOrDefault("X-Amz-Security-Token")
  valid_607161 = validateParameter(valid_607161, JString, required = false,
                                 default = nil)
  if valid_607161 != nil:
    section.add "X-Amz-Security-Token", valid_607161
  var valid_607162 = header.getOrDefault("X-Amz-Algorithm")
  valid_607162 = validateParameter(valid_607162, JString, required = false,
                                 default = nil)
  if valid_607162 != nil:
    section.add "X-Amz-Algorithm", valid_607162
  var valid_607163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607163 = validateParameter(valid_607163, JString, required = false,
                                 default = nil)
  if valid_607163 != nil:
    section.add "X-Amz-SignedHeaders", valid_607163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607164: Call_GetSetSMSAttributes_607146; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_607164.validator(path, query, header, formData, body)
  let scheme = call_607164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607164.url(scheme.get, call_607164.host, call_607164.base,
                         call_607164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607164, url, valid)

proc call*(call_607165: Call_GetSetSMSAttributes_607146;
          attributes2Key: string = ""; attributes0Key: string = "";
          Action: string = "SetSMSAttributes"; attributes1Key: string = "";
          attributes0Value: string = ""; Version: string = "2010-03-31";
          attributes1Value: string = ""; attributes2Value: string = ""): Recallable =
  ## getSetSMSAttributes
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ##   attributes2Key: string
  ##   attributes0Key: string
  ##   Action: string (required)
  ##   attributes1Key: string
  ##   attributes0Value: string
  ##   Version: string (required)
  ##   attributes1Value: string
  ##   attributes2Value: string
  var query_607166 = newJObject()
  add(query_607166, "attributes.2.key", newJString(attributes2Key))
  add(query_607166, "attributes.0.key", newJString(attributes0Key))
  add(query_607166, "Action", newJString(Action))
  add(query_607166, "attributes.1.key", newJString(attributes1Key))
  add(query_607166, "attributes.0.value", newJString(attributes0Value))
  add(query_607166, "Version", newJString(Version))
  add(query_607166, "attributes.1.value", newJString(attributes1Value))
  add(query_607166, "attributes.2.value", newJString(attributes2Value))
  result = call_607165.call(nil, query_607166, nil, nil, nil)

var getSetSMSAttributes* = Call_GetSetSMSAttributes_607146(
    name: "getSetSMSAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetSMSAttributes",
    validator: validate_GetSetSMSAttributes_607147, base: "/",
    url: url_GetSetSMSAttributes_607148, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSubscriptionAttributes_607207 = ref object of OpenApiRestCall_605589
proc url_PostSetSubscriptionAttributes_607209(protocol: Scheme; host: string;
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

proc validate_PostSetSubscriptionAttributes_607208(path: JsonNode; query: JsonNode;
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
  var valid_607210 = query.getOrDefault("Action")
  valid_607210 = validateParameter(valid_607210, JString, required = true, default = newJString(
      "SetSubscriptionAttributes"))
  if valid_607210 != nil:
    section.add "Action", valid_607210
  var valid_607211 = query.getOrDefault("Version")
  valid_607211 = validateParameter(valid_607211, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_607211 != nil:
    section.add "Version", valid_607211
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607212 = header.getOrDefault("X-Amz-Signature")
  valid_607212 = validateParameter(valid_607212, JString, required = false,
                                 default = nil)
  if valid_607212 != nil:
    section.add "X-Amz-Signature", valid_607212
  var valid_607213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607213 = validateParameter(valid_607213, JString, required = false,
                                 default = nil)
  if valid_607213 != nil:
    section.add "X-Amz-Content-Sha256", valid_607213
  var valid_607214 = header.getOrDefault("X-Amz-Date")
  valid_607214 = validateParameter(valid_607214, JString, required = false,
                                 default = nil)
  if valid_607214 != nil:
    section.add "X-Amz-Date", valid_607214
  var valid_607215 = header.getOrDefault("X-Amz-Credential")
  valid_607215 = validateParameter(valid_607215, JString, required = false,
                                 default = nil)
  if valid_607215 != nil:
    section.add "X-Amz-Credential", valid_607215
  var valid_607216 = header.getOrDefault("X-Amz-Security-Token")
  valid_607216 = validateParameter(valid_607216, JString, required = false,
                                 default = nil)
  if valid_607216 != nil:
    section.add "X-Amz-Security-Token", valid_607216
  var valid_607217 = header.getOrDefault("X-Amz-Algorithm")
  valid_607217 = validateParameter(valid_607217, JString, required = false,
                                 default = nil)
  if valid_607217 != nil:
    section.add "X-Amz-Algorithm", valid_607217
  var valid_607218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607218 = validateParameter(valid_607218, JString, required = false,
                                 default = nil)
  if valid_607218 != nil:
    section.add "X-Amz-SignedHeaders", valid_607218
  result.add "header", section
  ## parameters in `formData` object:
  ##   AttributeName: JString (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>FilterPolicy</code> – The simple JSON object that lets your subscriber receive only a subset of messages, rather than receiving every message published to the topic.</p> </li> <li> <p> <code>RawMessageDelivery</code> – When set to <code>true</code>, enables raw message delivery to Amazon SQS or HTTP/S endpoints. This eliminates the need for the endpoints to process JSON formatting, which is otherwise created for Amazon SNS metadata.</p> </li> <li> <p> <code>RedrivePolicy</code> – When specified, sends undeliverable messages to the specified Amazon SQS dead-letter queue. Messages that can't be delivered due to client errors (for example, when the subscribed endpoint is unreachable) or server errors (for example, when the service that powers the subscribed endpoint becomes unavailable) are held in the dead-letter queue for further analysis or reprocessing.</p> </li> </ul>
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription to modify.
  ##   AttributeValue: JString
  ##                 : The new value for the attribute in JSON format.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AttributeName` field"
  var valid_607219 = formData.getOrDefault("AttributeName")
  valid_607219 = validateParameter(valid_607219, JString, required = true,
                                 default = nil)
  if valid_607219 != nil:
    section.add "AttributeName", valid_607219
  var valid_607220 = formData.getOrDefault("SubscriptionArn")
  valid_607220 = validateParameter(valid_607220, JString, required = true,
                                 default = nil)
  if valid_607220 != nil:
    section.add "SubscriptionArn", valid_607220
  var valid_607221 = formData.getOrDefault("AttributeValue")
  valid_607221 = validateParameter(valid_607221, JString, required = false,
                                 default = nil)
  if valid_607221 != nil:
    section.add "AttributeValue", valid_607221
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607222: Call_PostSetSubscriptionAttributes_607207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ## 
  let valid = call_607222.validator(path, query, header, formData, body)
  let scheme = call_607222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607222.url(scheme.get, call_607222.host, call_607222.base,
                         call_607222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607222, url, valid)

proc call*(call_607223: Call_PostSetSubscriptionAttributes_607207;
          AttributeName: string; SubscriptionArn: string;
          AttributeValue: string = ""; Action: string = "SetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postSetSubscriptionAttributes
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ##   AttributeName: string (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>FilterPolicy</code> – The simple JSON object that lets your subscriber receive only a subset of messages, rather than receiving every message published to the topic.</p> </li> <li> <p> <code>RawMessageDelivery</code> – When set to <code>true</code>, enables raw message delivery to Amazon SQS or HTTP/S endpoints. This eliminates the need for the endpoints to process JSON formatting, which is otherwise created for Amazon SNS metadata.</p> </li> <li> <p> <code>RedrivePolicy</code> – When specified, sends undeliverable messages to the specified Amazon SQS dead-letter queue. Messages that can't be delivered due to client errors (for example, when the subscribed endpoint is unreachable) or server errors (for example, when the service that powers the subscribed endpoint becomes unavailable) are held in the dead-letter queue for further analysis or reprocessing.</p> </li> </ul>
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to modify.
  ##   AttributeValue: string
  ##                 : The new value for the attribute in JSON format.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607224 = newJObject()
  var formData_607225 = newJObject()
  add(formData_607225, "AttributeName", newJString(AttributeName))
  add(formData_607225, "SubscriptionArn", newJString(SubscriptionArn))
  add(formData_607225, "AttributeValue", newJString(AttributeValue))
  add(query_607224, "Action", newJString(Action))
  add(query_607224, "Version", newJString(Version))
  result = call_607223.call(nil, query_607224, nil, formData_607225, nil)

var postSetSubscriptionAttributes* = Call_PostSetSubscriptionAttributes_607207(
    name: "postSetSubscriptionAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetSubscriptionAttributes",
    validator: validate_PostSetSubscriptionAttributes_607208, base: "/",
    url: url_PostSetSubscriptionAttributes_607209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSubscriptionAttributes_607189 = ref object of OpenApiRestCall_605589
proc url_GetSetSubscriptionAttributes_607191(protocol: Scheme; host: string;
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

proc validate_GetSetSubscriptionAttributes_607190(path: JsonNode; query: JsonNode;
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
  ##   AttributeValue: JString
  ##                 : The new value for the attribute in JSON format.
  ##   Action: JString (required)
  ##   AttributeName: JString (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>FilterPolicy</code> – The simple JSON object that lets your subscriber receive only a subset of messages, rather than receiving every message published to the topic.</p> </li> <li> <p> <code>RawMessageDelivery</code> – When set to <code>true</code>, enables raw message delivery to Amazon SQS or HTTP/S endpoints. This eliminates the need for the endpoints to process JSON formatting, which is otherwise created for Amazon SNS metadata.</p> </li> <li> <p> <code>RedrivePolicy</code> – When specified, sends undeliverable messages to the specified Amazon SQS dead-letter queue. Messages that can't be delivered due to client errors (for example, when the subscribed endpoint is unreachable) or server errors (for example, when the service that powers the subscribed endpoint becomes unavailable) are held in the dead-letter queue for further analysis or reprocessing.</p> </li> </ul>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SubscriptionArn` field"
  var valid_607192 = query.getOrDefault("SubscriptionArn")
  valid_607192 = validateParameter(valid_607192, JString, required = true,
                                 default = nil)
  if valid_607192 != nil:
    section.add "SubscriptionArn", valid_607192
  var valid_607193 = query.getOrDefault("AttributeValue")
  valid_607193 = validateParameter(valid_607193, JString, required = false,
                                 default = nil)
  if valid_607193 != nil:
    section.add "AttributeValue", valid_607193
  var valid_607194 = query.getOrDefault("Action")
  valid_607194 = validateParameter(valid_607194, JString, required = true, default = newJString(
      "SetSubscriptionAttributes"))
  if valid_607194 != nil:
    section.add "Action", valid_607194
  var valid_607195 = query.getOrDefault("AttributeName")
  valid_607195 = validateParameter(valid_607195, JString, required = true,
                                 default = nil)
  if valid_607195 != nil:
    section.add "AttributeName", valid_607195
  var valid_607196 = query.getOrDefault("Version")
  valid_607196 = validateParameter(valid_607196, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_607196 != nil:
    section.add "Version", valid_607196
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607197 = header.getOrDefault("X-Amz-Signature")
  valid_607197 = validateParameter(valid_607197, JString, required = false,
                                 default = nil)
  if valid_607197 != nil:
    section.add "X-Amz-Signature", valid_607197
  var valid_607198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607198 = validateParameter(valid_607198, JString, required = false,
                                 default = nil)
  if valid_607198 != nil:
    section.add "X-Amz-Content-Sha256", valid_607198
  var valid_607199 = header.getOrDefault("X-Amz-Date")
  valid_607199 = validateParameter(valid_607199, JString, required = false,
                                 default = nil)
  if valid_607199 != nil:
    section.add "X-Amz-Date", valid_607199
  var valid_607200 = header.getOrDefault("X-Amz-Credential")
  valid_607200 = validateParameter(valid_607200, JString, required = false,
                                 default = nil)
  if valid_607200 != nil:
    section.add "X-Amz-Credential", valid_607200
  var valid_607201 = header.getOrDefault("X-Amz-Security-Token")
  valid_607201 = validateParameter(valid_607201, JString, required = false,
                                 default = nil)
  if valid_607201 != nil:
    section.add "X-Amz-Security-Token", valid_607201
  var valid_607202 = header.getOrDefault("X-Amz-Algorithm")
  valid_607202 = validateParameter(valid_607202, JString, required = false,
                                 default = nil)
  if valid_607202 != nil:
    section.add "X-Amz-Algorithm", valid_607202
  var valid_607203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607203 = validateParameter(valid_607203, JString, required = false,
                                 default = nil)
  if valid_607203 != nil:
    section.add "X-Amz-SignedHeaders", valid_607203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607204: Call_GetSetSubscriptionAttributes_607189; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ## 
  let valid = call_607204.validator(path, query, header, formData, body)
  let scheme = call_607204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607204.url(scheme.get, call_607204.host, call_607204.base,
                         call_607204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607204, url, valid)

proc call*(call_607205: Call_GetSetSubscriptionAttributes_607189;
          SubscriptionArn: string; AttributeName: string;
          AttributeValue: string = ""; Action: string = "SetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getSetSubscriptionAttributes
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to modify.
  ##   AttributeValue: string
  ##                 : The new value for the attribute in JSON format.
  ##   Action: string (required)
  ##   AttributeName: string (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>FilterPolicy</code> – The simple JSON object that lets your subscriber receive only a subset of messages, rather than receiving every message published to the topic.</p> </li> <li> <p> <code>RawMessageDelivery</code> – When set to <code>true</code>, enables raw message delivery to Amazon SQS or HTTP/S endpoints. This eliminates the need for the endpoints to process JSON formatting, which is otherwise created for Amazon SNS metadata.</p> </li> <li> <p> <code>RedrivePolicy</code> – When specified, sends undeliverable messages to the specified Amazon SQS dead-letter queue. Messages that can't be delivered due to client errors (for example, when the subscribed endpoint is unreachable) or server errors (for example, when the service that powers the subscribed endpoint becomes unavailable) are held in the dead-letter queue for further analysis or reprocessing.</p> </li> </ul>
  ##   Version: string (required)
  var query_607206 = newJObject()
  add(query_607206, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_607206, "AttributeValue", newJString(AttributeValue))
  add(query_607206, "Action", newJString(Action))
  add(query_607206, "AttributeName", newJString(AttributeName))
  add(query_607206, "Version", newJString(Version))
  result = call_607205.call(nil, query_607206, nil, nil, nil)

var getSetSubscriptionAttributes* = Call_GetSetSubscriptionAttributes_607189(
    name: "getSetSubscriptionAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetSubscriptionAttributes",
    validator: validate_GetSetSubscriptionAttributes_607190, base: "/",
    url: url_GetSetSubscriptionAttributes_607191,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetTopicAttributes_607244 = ref object of OpenApiRestCall_605589
proc url_PostSetTopicAttributes_607246(protocol: Scheme; host: string; base: string;
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

proc validate_PostSetTopicAttributes_607245(path: JsonNode; query: JsonNode;
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
  var valid_607247 = query.getOrDefault("Action")
  valid_607247 = validateParameter(valid_607247, JString, required = true,
                                 default = newJString("SetTopicAttributes"))
  if valid_607247 != nil:
    section.add "Action", valid_607247
  var valid_607248 = query.getOrDefault("Version")
  valid_607248 = validateParameter(valid_607248, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_607248 != nil:
    section.add "Version", valid_607248
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607249 = header.getOrDefault("X-Amz-Signature")
  valid_607249 = validateParameter(valid_607249, JString, required = false,
                                 default = nil)
  if valid_607249 != nil:
    section.add "X-Amz-Signature", valid_607249
  var valid_607250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607250 = validateParameter(valid_607250, JString, required = false,
                                 default = nil)
  if valid_607250 != nil:
    section.add "X-Amz-Content-Sha256", valid_607250
  var valid_607251 = header.getOrDefault("X-Amz-Date")
  valid_607251 = validateParameter(valid_607251, JString, required = false,
                                 default = nil)
  if valid_607251 != nil:
    section.add "X-Amz-Date", valid_607251
  var valid_607252 = header.getOrDefault("X-Amz-Credential")
  valid_607252 = validateParameter(valid_607252, JString, required = false,
                                 default = nil)
  if valid_607252 != nil:
    section.add "X-Amz-Credential", valid_607252
  var valid_607253 = header.getOrDefault("X-Amz-Security-Token")
  valid_607253 = validateParameter(valid_607253, JString, required = false,
                                 default = nil)
  if valid_607253 != nil:
    section.add "X-Amz-Security-Token", valid_607253
  var valid_607254 = header.getOrDefault("X-Amz-Algorithm")
  valid_607254 = validateParameter(valid_607254, JString, required = false,
                                 default = nil)
  if valid_607254 != nil:
    section.add "X-Amz-Algorithm", valid_607254
  var valid_607255 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607255 = validateParameter(valid_607255, JString, required = false,
                                 default = nil)
  if valid_607255 != nil:
    section.add "X-Amz-SignedHeaders", valid_607255
  result.add "header", section
  ## parameters in `formData` object:
  ##   AttributeName: JString (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>DisplayName</code> – The display name to use for a topic with SMS subscriptions.</p> </li> <li> <p> <code>Policy</code> – The policy that defines who can access your topic. By default, only the topic owner can publish or subscribe to the topic.</p> </li> </ul> <p>The following attribute applies only to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html">server-side-encryption</a>:</p> <ul> <li> <p> <code>KmsMasterKeyId</code> - The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK. For more information, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms">Key Terms</a>. For more examples, see <a 
  ## href="https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters">KeyId</a> in the <i>AWS Key Management Service API Reference</i>. </p> </li> </ul>
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic to modify.
  ##   AttributeValue: JString
  ##                 : The new value for the attribute.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AttributeName` field"
  var valid_607256 = formData.getOrDefault("AttributeName")
  valid_607256 = validateParameter(valid_607256, JString, required = true,
                                 default = nil)
  if valid_607256 != nil:
    section.add "AttributeName", valid_607256
  var valid_607257 = formData.getOrDefault("TopicArn")
  valid_607257 = validateParameter(valid_607257, JString, required = true,
                                 default = nil)
  if valid_607257 != nil:
    section.add "TopicArn", valid_607257
  var valid_607258 = formData.getOrDefault("AttributeValue")
  valid_607258 = validateParameter(valid_607258, JString, required = false,
                                 default = nil)
  if valid_607258 != nil:
    section.add "AttributeValue", valid_607258
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607259: Call_PostSetTopicAttributes_607244; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  let valid = call_607259.validator(path, query, header, formData, body)
  let scheme = call_607259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607259.url(scheme.get, call_607259.host, call_607259.base,
                         call_607259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607259, url, valid)

proc call*(call_607260: Call_PostSetTopicAttributes_607244; AttributeName: string;
          TopicArn: string; AttributeValue: string = "";
          Action: string = "SetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## postSetTopicAttributes
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ##   AttributeName: string (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>DisplayName</code> – The display name to use for a topic with SMS subscriptions.</p> </li> <li> <p> <code>Policy</code> – The policy that defines who can access your topic. By default, only the topic owner can publish or subscribe to the topic.</p> </li> </ul> <p>The following attribute applies only to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html">server-side-encryption</a>:</p> <ul> <li> <p> <code>KmsMasterKeyId</code> - The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK. For more information, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms">Key Terms</a>. For more examples, see <a 
  ## href="https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters">KeyId</a> in the <i>AWS Key Management Service API Reference</i>. </p> </li> </ul>
  ##   TopicArn: string (required)
  ##           : The ARN of the topic to modify.
  ##   AttributeValue: string
  ##                 : The new value for the attribute.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607261 = newJObject()
  var formData_607262 = newJObject()
  add(formData_607262, "AttributeName", newJString(AttributeName))
  add(formData_607262, "TopicArn", newJString(TopicArn))
  add(formData_607262, "AttributeValue", newJString(AttributeValue))
  add(query_607261, "Action", newJString(Action))
  add(query_607261, "Version", newJString(Version))
  result = call_607260.call(nil, query_607261, nil, formData_607262, nil)

var postSetTopicAttributes* = Call_PostSetTopicAttributes_607244(
    name: "postSetTopicAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetTopicAttributes",
    validator: validate_PostSetTopicAttributes_607245, base: "/",
    url: url_PostSetTopicAttributes_607246, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetTopicAttributes_607226 = ref object of OpenApiRestCall_605589
proc url_GetSetTopicAttributes_607228(protocol: Scheme; host: string; base: string;
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

proc validate_GetSetTopicAttributes_607227(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   AttributeValue: JString
  ##                 : The new value for the attribute.
  ##   Action: JString (required)
  ##   AttributeName: JString (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>DisplayName</code> – The display name to use for a topic with SMS subscriptions.</p> </li> <li> <p> <code>Policy</code> – The policy that defines who can access your topic. By default, only the topic owner can publish or subscribe to the topic.</p> </li> </ul> <p>The following attribute applies only to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html">server-side-encryption</a>:</p> <ul> <li> <p> <code>KmsMasterKeyId</code> - The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK. For more information, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms">Key Terms</a>. For more examples, see <a 
  ## href="https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters">KeyId</a> in the <i>AWS Key Management Service API Reference</i>. </p> </li> </ul>
  ##   Version: JString (required)
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic to modify.
  section = newJObject()
  var valid_607229 = query.getOrDefault("AttributeValue")
  valid_607229 = validateParameter(valid_607229, JString, required = false,
                                 default = nil)
  if valid_607229 != nil:
    section.add "AttributeValue", valid_607229
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607230 = query.getOrDefault("Action")
  valid_607230 = validateParameter(valid_607230, JString, required = true,
                                 default = newJString("SetTopicAttributes"))
  if valid_607230 != nil:
    section.add "Action", valid_607230
  var valid_607231 = query.getOrDefault("AttributeName")
  valid_607231 = validateParameter(valid_607231, JString, required = true,
                                 default = nil)
  if valid_607231 != nil:
    section.add "AttributeName", valid_607231
  var valid_607232 = query.getOrDefault("Version")
  valid_607232 = validateParameter(valid_607232, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_607232 != nil:
    section.add "Version", valid_607232
  var valid_607233 = query.getOrDefault("TopicArn")
  valid_607233 = validateParameter(valid_607233, JString, required = true,
                                 default = nil)
  if valid_607233 != nil:
    section.add "TopicArn", valid_607233
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607234 = header.getOrDefault("X-Amz-Signature")
  valid_607234 = validateParameter(valid_607234, JString, required = false,
                                 default = nil)
  if valid_607234 != nil:
    section.add "X-Amz-Signature", valid_607234
  var valid_607235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607235 = validateParameter(valid_607235, JString, required = false,
                                 default = nil)
  if valid_607235 != nil:
    section.add "X-Amz-Content-Sha256", valid_607235
  var valid_607236 = header.getOrDefault("X-Amz-Date")
  valid_607236 = validateParameter(valid_607236, JString, required = false,
                                 default = nil)
  if valid_607236 != nil:
    section.add "X-Amz-Date", valid_607236
  var valid_607237 = header.getOrDefault("X-Amz-Credential")
  valid_607237 = validateParameter(valid_607237, JString, required = false,
                                 default = nil)
  if valid_607237 != nil:
    section.add "X-Amz-Credential", valid_607237
  var valid_607238 = header.getOrDefault("X-Amz-Security-Token")
  valid_607238 = validateParameter(valid_607238, JString, required = false,
                                 default = nil)
  if valid_607238 != nil:
    section.add "X-Amz-Security-Token", valid_607238
  var valid_607239 = header.getOrDefault("X-Amz-Algorithm")
  valid_607239 = validateParameter(valid_607239, JString, required = false,
                                 default = nil)
  if valid_607239 != nil:
    section.add "X-Amz-Algorithm", valid_607239
  var valid_607240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607240 = validateParameter(valid_607240, JString, required = false,
                                 default = nil)
  if valid_607240 != nil:
    section.add "X-Amz-SignedHeaders", valid_607240
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607241: Call_GetSetTopicAttributes_607226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  let valid = call_607241.validator(path, query, header, formData, body)
  let scheme = call_607241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607241.url(scheme.get, call_607241.host, call_607241.base,
                         call_607241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607241, url, valid)

proc call*(call_607242: Call_GetSetTopicAttributes_607226; AttributeName: string;
          TopicArn: string; AttributeValue: string = "";
          Action: string = "SetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## getSetTopicAttributes
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ##   AttributeValue: string
  ##                 : The new value for the attribute.
  ##   Action: string (required)
  ##   AttributeName: string (required)
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>DisplayName</code> – The display name to use for a topic with SMS subscriptions.</p> </li> <li> <p> <code>Policy</code> – The policy that defines who can access your topic. By default, only the topic owner can publish or subscribe to the topic.</p> </li> </ul> <p>The following attribute applies only to <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html">server-side-encryption</a>:</p> <ul> <li> <p> <code>KmsMasterKeyId</code> - The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK. For more information, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms">Key Terms</a>. For more examples, see <a 
  ## href="https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters">KeyId</a> in the <i>AWS Key Management Service API Reference</i>. </p> </li> </ul>
  ##   Version: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic to modify.
  var query_607243 = newJObject()
  add(query_607243, "AttributeValue", newJString(AttributeValue))
  add(query_607243, "Action", newJString(Action))
  add(query_607243, "AttributeName", newJString(AttributeName))
  add(query_607243, "Version", newJString(Version))
  add(query_607243, "TopicArn", newJString(TopicArn))
  result = call_607242.call(nil, query_607243, nil, nil, nil)

var getSetTopicAttributes* = Call_GetSetTopicAttributes_607226(
    name: "getSetTopicAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetTopicAttributes",
    validator: validate_GetSetTopicAttributes_607227, base: "/",
    url: url_GetSetTopicAttributes_607228, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSubscribe_607288 = ref object of OpenApiRestCall_605589
proc url_PostSubscribe_607290(protocol: Scheme; host: string; base: string;
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

proc validate_PostSubscribe_607289(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_607291 = query.getOrDefault("Action")
  valid_607291 = validateParameter(valid_607291, JString, required = true,
                                 default = newJString("Subscribe"))
  if valid_607291 != nil:
    section.add "Action", valid_607291
  var valid_607292 = query.getOrDefault("Version")
  valid_607292 = validateParameter(valid_607292, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_607292 != nil:
    section.add "Version", valid_607292
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607293 = header.getOrDefault("X-Amz-Signature")
  valid_607293 = validateParameter(valid_607293, JString, required = false,
                                 default = nil)
  if valid_607293 != nil:
    section.add "X-Amz-Signature", valid_607293
  var valid_607294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607294 = validateParameter(valid_607294, JString, required = false,
                                 default = nil)
  if valid_607294 != nil:
    section.add "X-Amz-Content-Sha256", valid_607294
  var valid_607295 = header.getOrDefault("X-Amz-Date")
  valid_607295 = validateParameter(valid_607295, JString, required = false,
                                 default = nil)
  if valid_607295 != nil:
    section.add "X-Amz-Date", valid_607295
  var valid_607296 = header.getOrDefault("X-Amz-Credential")
  valid_607296 = validateParameter(valid_607296, JString, required = false,
                                 default = nil)
  if valid_607296 != nil:
    section.add "X-Amz-Credential", valid_607296
  var valid_607297 = header.getOrDefault("X-Amz-Security-Token")
  valid_607297 = validateParameter(valid_607297, JString, required = false,
                                 default = nil)
  if valid_607297 != nil:
    section.add "X-Amz-Security-Token", valid_607297
  var valid_607298 = header.getOrDefault("X-Amz-Algorithm")
  valid_607298 = validateParameter(valid_607298, JString, required = false,
                                 default = nil)
  if valid_607298 != nil:
    section.add "X-Amz-Algorithm", valid_607298
  var valid_607299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607299 = validateParameter(valid_607299, JString, required = false,
                                 default = nil)
  if valid_607299 != nil:
    section.add "X-Amz-SignedHeaders", valid_607299
  result.add "header", section
  ## parameters in `formData` object:
  ##   Endpoint: JString
  ##           : <p>The endpoint that you want to receive notifications. Endpoints vary by protocol:</p> <ul> <li> <p>For the <code>http</code> protocol, the endpoint is an URL beginning with <code>http://</code> </p> </li> <li> <p>For the <code>https</code> protocol, the endpoint is a URL beginning with <code>https://</code> </p> </li> <li> <p>For the <code>email</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>email-json</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>sms</code> protocol, the endpoint is a phone number of an SMS-enabled device</p> </li> <li> <p>For the <code>sqs</code> protocol, the endpoint is the ARN of an Amazon SQS queue</p> </li> <li> <p>For the <code>application</code> protocol, the endpoint is the EndpointArn of a mobile app and device.</p> </li> <li> <p>For the <code>lambda</code> protocol, the endpoint is the ARN of an Amazon Lambda function.</p> </li> </ul>
  ##   Attributes.0.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.2.key: JString
  ##   Protocol: JString (required)
  ##           : <p>The protocol you want to use. Supported protocols include:</p> <ul> <li> <p> <code>http</code> – delivery of JSON-encoded message via HTTP POST</p> </li> <li> <p> <code>https</code> – delivery of JSON-encoded message via HTTPS POST</p> </li> <li> <p> <code>email</code> – delivery of message via SMTP</p> </li> <li> <p> <code>email-json</code> – delivery of JSON-encoded message via SMTP</p> </li> <li> <p> <code>sms</code> – delivery of message via SMS</p> </li> <li> <p> <code>sqs</code> – delivery of JSON-encoded message to an Amazon SQS queue</p> </li> <li> <p> <code>application</code> – delivery of JSON-encoded message to an EndpointArn for a mobile app and device.</p> </li> <li> <p> <code>lambda</code> – delivery of JSON-encoded message to an Amazon Lambda function.</p> </li> </ul>
  ##   Attributes.0.value: JString
  ##   Attributes.1.key: JString
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic you want to subscribe to.
  ##   ReturnSubscriptionArn: JBool
  ##                        : <p>Sets whether the response from the <code>Subscribe</code> request includes the subscription ARN, even if the subscription is not yet confirmed.</p> <ul> <li> <p>If you have the subscription ARN returned, the response includes the ARN in all cases, even if the subscription is not yet confirmed.</p> </li> <li> <p>If you don't have the subscription ARN returned, in addition to the ARN for confirmed subscriptions, the response also includes the <code>pending subscription</code> ARN value for subscriptions that aren't yet confirmed. A subscription becomes confirmed when the subscriber calls the <code>ConfirmSubscription</code> action with a confirmation token.</p> </li> </ul> <p>If you set this parameter to <code>true</code>, .</p> <p>The default value is <code>false</code>.</p>
  ##   Attributes.1.value: JString
  section = newJObject()
  var valid_607300 = formData.getOrDefault("Endpoint")
  valid_607300 = validateParameter(valid_607300, JString, required = false,
                                 default = nil)
  if valid_607300 != nil:
    section.add "Endpoint", valid_607300
  var valid_607301 = formData.getOrDefault("Attributes.0.key")
  valid_607301 = validateParameter(valid_607301, JString, required = false,
                                 default = nil)
  if valid_607301 != nil:
    section.add "Attributes.0.key", valid_607301
  var valid_607302 = formData.getOrDefault("Attributes.2.value")
  valid_607302 = validateParameter(valid_607302, JString, required = false,
                                 default = nil)
  if valid_607302 != nil:
    section.add "Attributes.2.value", valid_607302
  var valid_607303 = formData.getOrDefault("Attributes.2.key")
  valid_607303 = validateParameter(valid_607303, JString, required = false,
                                 default = nil)
  if valid_607303 != nil:
    section.add "Attributes.2.key", valid_607303
  assert formData != nil,
        "formData argument is necessary due to required `Protocol` field"
  var valid_607304 = formData.getOrDefault("Protocol")
  valid_607304 = validateParameter(valid_607304, JString, required = true,
                                 default = nil)
  if valid_607304 != nil:
    section.add "Protocol", valid_607304
  var valid_607305 = formData.getOrDefault("Attributes.0.value")
  valid_607305 = validateParameter(valid_607305, JString, required = false,
                                 default = nil)
  if valid_607305 != nil:
    section.add "Attributes.0.value", valid_607305
  var valid_607306 = formData.getOrDefault("Attributes.1.key")
  valid_607306 = validateParameter(valid_607306, JString, required = false,
                                 default = nil)
  if valid_607306 != nil:
    section.add "Attributes.1.key", valid_607306
  var valid_607307 = formData.getOrDefault("TopicArn")
  valid_607307 = validateParameter(valid_607307, JString, required = true,
                                 default = nil)
  if valid_607307 != nil:
    section.add "TopicArn", valid_607307
  var valid_607308 = formData.getOrDefault("ReturnSubscriptionArn")
  valid_607308 = validateParameter(valid_607308, JBool, required = false, default = nil)
  if valid_607308 != nil:
    section.add "ReturnSubscriptionArn", valid_607308
  var valid_607309 = formData.getOrDefault("Attributes.1.value")
  valid_607309 = validateParameter(valid_607309, JString, required = false,
                                 default = nil)
  if valid_607309 != nil:
    section.add "Attributes.1.value", valid_607309
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607310: Call_PostSubscribe_607288; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_607310.validator(path, query, header, formData, body)
  let scheme = call_607310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607310.url(scheme.get, call_607310.host, call_607310.base,
                         call_607310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607310, url, valid)

proc call*(call_607311: Call_PostSubscribe_607288; Protocol: string;
          TopicArn: string; Endpoint: string = ""; Attributes0Key: string = "";
          Attributes2Value: string = ""; Attributes2Key: string = "";
          Attributes0Value: string = ""; Attributes1Key: string = "";
          ReturnSubscriptionArn: bool = false; Action: string = "Subscribe";
          Version: string = "2010-03-31"; Attributes1Value: string = ""): Recallable =
  ## postSubscribe
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   Endpoint: string
  ##           : <p>The endpoint that you want to receive notifications. Endpoints vary by protocol:</p> <ul> <li> <p>For the <code>http</code> protocol, the endpoint is an URL beginning with <code>http://</code> </p> </li> <li> <p>For the <code>https</code> protocol, the endpoint is a URL beginning with <code>https://</code> </p> </li> <li> <p>For the <code>email</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>email-json</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>sms</code> protocol, the endpoint is a phone number of an SMS-enabled device</p> </li> <li> <p>For the <code>sqs</code> protocol, the endpoint is the ARN of an Amazon SQS queue</p> </li> <li> <p>For the <code>application</code> protocol, the endpoint is the EndpointArn of a mobile app and device.</p> </li> <li> <p>For the <code>lambda</code> protocol, the endpoint is the ARN of an Amazon Lambda function.</p> </li> </ul>
  ##   Attributes0Key: string
  ##   Attributes2Value: string
  ##   Attributes2Key: string
  ##   Protocol: string (required)
  ##           : <p>The protocol you want to use. Supported protocols include:</p> <ul> <li> <p> <code>http</code> – delivery of JSON-encoded message via HTTP POST</p> </li> <li> <p> <code>https</code> – delivery of JSON-encoded message via HTTPS POST</p> </li> <li> <p> <code>email</code> – delivery of message via SMTP</p> </li> <li> <p> <code>email-json</code> – delivery of JSON-encoded message via SMTP</p> </li> <li> <p> <code>sms</code> – delivery of message via SMS</p> </li> <li> <p> <code>sqs</code> – delivery of JSON-encoded message to an Amazon SQS queue</p> </li> <li> <p> <code>application</code> – delivery of JSON-encoded message to an EndpointArn for a mobile app and device.</p> </li> <li> <p> <code>lambda</code> – delivery of JSON-encoded message to an Amazon Lambda function.</p> </li> </ul>
  ##   Attributes0Value: string
  ##   Attributes1Key: string
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to subscribe to.
  ##   ReturnSubscriptionArn: bool
  ##                        : <p>Sets whether the response from the <code>Subscribe</code> request includes the subscription ARN, even if the subscription is not yet confirmed.</p> <ul> <li> <p>If you have the subscription ARN returned, the response includes the ARN in all cases, even if the subscription is not yet confirmed.</p> </li> <li> <p>If you don't have the subscription ARN returned, in addition to the ARN for confirmed subscriptions, the response also includes the <code>pending subscription</code> ARN value for subscriptions that aren't yet confirmed. A subscription becomes confirmed when the subscriber calls the <code>ConfirmSubscription</code> action with a confirmation token.</p> </li> </ul> <p>If you set this parameter to <code>true</code>, .</p> <p>The default value is <code>false</code>.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Attributes1Value: string
  var query_607312 = newJObject()
  var formData_607313 = newJObject()
  add(formData_607313, "Endpoint", newJString(Endpoint))
  add(formData_607313, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_607313, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_607313, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_607313, "Protocol", newJString(Protocol))
  add(formData_607313, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_607313, "Attributes.1.key", newJString(Attributes1Key))
  add(formData_607313, "TopicArn", newJString(TopicArn))
  add(formData_607313, "ReturnSubscriptionArn", newJBool(ReturnSubscriptionArn))
  add(query_607312, "Action", newJString(Action))
  add(query_607312, "Version", newJString(Version))
  add(formData_607313, "Attributes.1.value", newJString(Attributes1Value))
  result = call_607311.call(nil, query_607312, nil, formData_607313, nil)

var postSubscribe* = Call_PostSubscribe_607288(name: "postSubscribe",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=Subscribe", validator: validate_PostSubscribe_607289,
    base: "/", url: url_PostSubscribe_607290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSubscribe_607263 = ref object of OpenApiRestCall_605589
proc url_GetSubscribe_607265(protocol: Scheme; host: string; base: string;
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

proc validate_GetSubscribe_607264(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Attributes.1.key: JString
  ##   Attributes.0.value: JString
  ##   Endpoint: JString
  ##           : <p>The endpoint that you want to receive notifications. Endpoints vary by protocol:</p> <ul> <li> <p>For the <code>http</code> protocol, the endpoint is an URL beginning with <code>http://</code> </p> </li> <li> <p>For the <code>https</code> protocol, the endpoint is a URL beginning with <code>https://</code> </p> </li> <li> <p>For the <code>email</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>email-json</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>sms</code> protocol, the endpoint is a phone number of an SMS-enabled device</p> </li> <li> <p>For the <code>sqs</code> protocol, the endpoint is the ARN of an Amazon SQS queue</p> </li> <li> <p>For the <code>application</code> protocol, the endpoint is the EndpointArn of a mobile app and device.</p> </li> <li> <p>For the <code>lambda</code> protocol, the endpoint is the ARN of an Amazon Lambda function.</p> </li> </ul>
  ##   Attributes.0.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.1.value: JString
  ##   Action: JString (required)
  ##   Protocol: JString (required)
  ##           : <p>The protocol you want to use. Supported protocols include:</p> <ul> <li> <p> <code>http</code> – delivery of JSON-encoded message via HTTP POST</p> </li> <li> <p> <code>https</code> – delivery of JSON-encoded message via HTTPS POST</p> </li> <li> <p> <code>email</code> – delivery of message via SMTP</p> </li> <li> <p> <code>email-json</code> – delivery of JSON-encoded message via SMTP</p> </li> <li> <p> <code>sms</code> – delivery of message via SMS</p> </li> <li> <p> <code>sqs</code> – delivery of JSON-encoded message to an Amazon SQS queue</p> </li> <li> <p> <code>application</code> – delivery of JSON-encoded message to an EndpointArn for a mobile app and device.</p> </li> <li> <p> <code>lambda</code> – delivery of JSON-encoded message to an Amazon Lambda function.</p> </li> </ul>
  ##   ReturnSubscriptionArn: JBool
  ##                        : <p>Sets whether the response from the <code>Subscribe</code> request includes the subscription ARN, even if the subscription is not yet confirmed.</p> <ul> <li> <p>If you have the subscription ARN returned, the response includes the ARN in all cases, even if the subscription is not yet confirmed.</p> </li> <li> <p>If you don't have the subscription ARN returned, in addition to the ARN for confirmed subscriptions, the response also includes the <code>pending subscription</code> ARN value for subscriptions that aren't yet confirmed. A subscription becomes confirmed when the subscriber calls the <code>ConfirmSubscription</code> action with a confirmation token.</p> </li> </ul> <p>If you set this parameter to <code>true</code>, .</p> <p>The default value is <code>false</code>.</p>
  ##   Version: JString (required)
  ##   Attributes.2.key: JString
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic you want to subscribe to.
  section = newJObject()
  var valid_607266 = query.getOrDefault("Attributes.1.key")
  valid_607266 = validateParameter(valid_607266, JString, required = false,
                                 default = nil)
  if valid_607266 != nil:
    section.add "Attributes.1.key", valid_607266
  var valid_607267 = query.getOrDefault("Attributes.0.value")
  valid_607267 = validateParameter(valid_607267, JString, required = false,
                                 default = nil)
  if valid_607267 != nil:
    section.add "Attributes.0.value", valid_607267
  var valid_607268 = query.getOrDefault("Endpoint")
  valid_607268 = validateParameter(valid_607268, JString, required = false,
                                 default = nil)
  if valid_607268 != nil:
    section.add "Endpoint", valid_607268
  var valid_607269 = query.getOrDefault("Attributes.0.key")
  valid_607269 = validateParameter(valid_607269, JString, required = false,
                                 default = nil)
  if valid_607269 != nil:
    section.add "Attributes.0.key", valid_607269
  var valid_607270 = query.getOrDefault("Attributes.2.value")
  valid_607270 = validateParameter(valid_607270, JString, required = false,
                                 default = nil)
  if valid_607270 != nil:
    section.add "Attributes.2.value", valid_607270
  var valid_607271 = query.getOrDefault("Attributes.1.value")
  valid_607271 = validateParameter(valid_607271, JString, required = false,
                                 default = nil)
  if valid_607271 != nil:
    section.add "Attributes.1.value", valid_607271
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607272 = query.getOrDefault("Action")
  valid_607272 = validateParameter(valid_607272, JString, required = true,
                                 default = newJString("Subscribe"))
  if valid_607272 != nil:
    section.add "Action", valid_607272
  var valid_607273 = query.getOrDefault("Protocol")
  valid_607273 = validateParameter(valid_607273, JString, required = true,
                                 default = nil)
  if valid_607273 != nil:
    section.add "Protocol", valid_607273
  var valid_607274 = query.getOrDefault("ReturnSubscriptionArn")
  valid_607274 = validateParameter(valid_607274, JBool, required = false, default = nil)
  if valid_607274 != nil:
    section.add "ReturnSubscriptionArn", valid_607274
  var valid_607275 = query.getOrDefault("Version")
  valid_607275 = validateParameter(valid_607275, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_607275 != nil:
    section.add "Version", valid_607275
  var valid_607276 = query.getOrDefault("Attributes.2.key")
  valid_607276 = validateParameter(valid_607276, JString, required = false,
                                 default = nil)
  if valid_607276 != nil:
    section.add "Attributes.2.key", valid_607276
  var valid_607277 = query.getOrDefault("TopicArn")
  valid_607277 = validateParameter(valid_607277, JString, required = true,
                                 default = nil)
  if valid_607277 != nil:
    section.add "TopicArn", valid_607277
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607278 = header.getOrDefault("X-Amz-Signature")
  valid_607278 = validateParameter(valid_607278, JString, required = false,
                                 default = nil)
  if valid_607278 != nil:
    section.add "X-Amz-Signature", valid_607278
  var valid_607279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607279 = validateParameter(valid_607279, JString, required = false,
                                 default = nil)
  if valid_607279 != nil:
    section.add "X-Amz-Content-Sha256", valid_607279
  var valid_607280 = header.getOrDefault("X-Amz-Date")
  valid_607280 = validateParameter(valid_607280, JString, required = false,
                                 default = nil)
  if valid_607280 != nil:
    section.add "X-Amz-Date", valid_607280
  var valid_607281 = header.getOrDefault("X-Amz-Credential")
  valid_607281 = validateParameter(valid_607281, JString, required = false,
                                 default = nil)
  if valid_607281 != nil:
    section.add "X-Amz-Credential", valid_607281
  var valid_607282 = header.getOrDefault("X-Amz-Security-Token")
  valid_607282 = validateParameter(valid_607282, JString, required = false,
                                 default = nil)
  if valid_607282 != nil:
    section.add "X-Amz-Security-Token", valid_607282
  var valid_607283 = header.getOrDefault("X-Amz-Algorithm")
  valid_607283 = validateParameter(valid_607283, JString, required = false,
                                 default = nil)
  if valid_607283 != nil:
    section.add "X-Amz-Algorithm", valid_607283
  var valid_607284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607284 = validateParameter(valid_607284, JString, required = false,
                                 default = nil)
  if valid_607284 != nil:
    section.add "X-Amz-SignedHeaders", valid_607284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607285: Call_GetSubscribe_607263; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_607285.validator(path, query, header, formData, body)
  let scheme = call_607285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607285.url(scheme.get, call_607285.host, call_607285.base,
                         call_607285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607285, url, valid)

proc call*(call_607286: Call_GetSubscribe_607263; Protocol: string; TopicArn: string;
          Attributes1Key: string = ""; Attributes0Value: string = "";
          Endpoint: string = ""; Attributes0Key: string = "";
          Attributes2Value: string = ""; Attributes1Value: string = "";
          Action: string = "Subscribe"; ReturnSubscriptionArn: bool = false;
          Version: string = "2010-03-31"; Attributes2Key: string = ""): Recallable =
  ## getSubscribe
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   Attributes1Key: string
  ##   Attributes0Value: string
  ##   Endpoint: string
  ##           : <p>The endpoint that you want to receive notifications. Endpoints vary by protocol:</p> <ul> <li> <p>For the <code>http</code> protocol, the endpoint is an URL beginning with <code>http://</code> </p> </li> <li> <p>For the <code>https</code> protocol, the endpoint is a URL beginning with <code>https://</code> </p> </li> <li> <p>For the <code>email</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>email-json</code> protocol, the endpoint is an email address</p> </li> <li> <p>For the <code>sms</code> protocol, the endpoint is a phone number of an SMS-enabled device</p> </li> <li> <p>For the <code>sqs</code> protocol, the endpoint is the ARN of an Amazon SQS queue</p> </li> <li> <p>For the <code>application</code> protocol, the endpoint is the EndpointArn of a mobile app and device.</p> </li> <li> <p>For the <code>lambda</code> protocol, the endpoint is the ARN of an Amazon Lambda function.</p> </li> </ul>
  ##   Attributes0Key: string
  ##   Attributes2Value: string
  ##   Attributes1Value: string
  ##   Action: string (required)
  ##   Protocol: string (required)
  ##           : <p>The protocol you want to use. Supported protocols include:</p> <ul> <li> <p> <code>http</code> – delivery of JSON-encoded message via HTTP POST</p> </li> <li> <p> <code>https</code> – delivery of JSON-encoded message via HTTPS POST</p> </li> <li> <p> <code>email</code> – delivery of message via SMTP</p> </li> <li> <p> <code>email-json</code> – delivery of JSON-encoded message via SMTP</p> </li> <li> <p> <code>sms</code> – delivery of message via SMS</p> </li> <li> <p> <code>sqs</code> – delivery of JSON-encoded message to an Amazon SQS queue</p> </li> <li> <p> <code>application</code> – delivery of JSON-encoded message to an EndpointArn for a mobile app and device.</p> </li> <li> <p> <code>lambda</code> – delivery of JSON-encoded message to an Amazon Lambda function.</p> </li> </ul>
  ##   ReturnSubscriptionArn: bool
  ##                        : <p>Sets whether the response from the <code>Subscribe</code> request includes the subscription ARN, even if the subscription is not yet confirmed.</p> <ul> <li> <p>If you have the subscription ARN returned, the response includes the ARN in all cases, even if the subscription is not yet confirmed.</p> </li> <li> <p>If you don't have the subscription ARN returned, in addition to the ARN for confirmed subscriptions, the response also includes the <code>pending subscription</code> ARN value for subscriptions that aren't yet confirmed. A subscription becomes confirmed when the subscriber calls the <code>ConfirmSubscription</code> action with a confirmation token.</p> </li> </ul> <p>If you set this parameter to <code>true</code>, .</p> <p>The default value is <code>false</code>.</p>
  ##   Version: string (required)
  ##   Attributes2Key: string
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to subscribe to.
  var query_607287 = newJObject()
  add(query_607287, "Attributes.1.key", newJString(Attributes1Key))
  add(query_607287, "Attributes.0.value", newJString(Attributes0Value))
  add(query_607287, "Endpoint", newJString(Endpoint))
  add(query_607287, "Attributes.0.key", newJString(Attributes0Key))
  add(query_607287, "Attributes.2.value", newJString(Attributes2Value))
  add(query_607287, "Attributes.1.value", newJString(Attributes1Value))
  add(query_607287, "Action", newJString(Action))
  add(query_607287, "Protocol", newJString(Protocol))
  add(query_607287, "ReturnSubscriptionArn", newJBool(ReturnSubscriptionArn))
  add(query_607287, "Version", newJString(Version))
  add(query_607287, "Attributes.2.key", newJString(Attributes2Key))
  add(query_607287, "TopicArn", newJString(TopicArn))
  result = call_607286.call(nil, query_607287, nil, nil, nil)

var getSubscribe* = Call_GetSubscribe_607263(name: "getSubscribe",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=Subscribe", validator: validate_GetSubscribe_607264, base: "/",
    url: url_GetSubscribe_607265, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTagResource_607331 = ref object of OpenApiRestCall_605589
proc url_PostTagResource_607333(protocol: Scheme; host: string; base: string;
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

proc validate_PostTagResource_607332(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607334 = query.getOrDefault("Action")
  valid_607334 = validateParameter(valid_607334, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_607334 != nil:
    section.add "Action", valid_607334
  var valid_607335 = query.getOrDefault("Version")
  valid_607335 = validateParameter(valid_607335, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_607335 != nil:
    section.add "Version", valid_607335
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607336 = header.getOrDefault("X-Amz-Signature")
  valid_607336 = validateParameter(valid_607336, JString, required = false,
                                 default = nil)
  if valid_607336 != nil:
    section.add "X-Amz-Signature", valid_607336
  var valid_607337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607337 = validateParameter(valid_607337, JString, required = false,
                                 default = nil)
  if valid_607337 != nil:
    section.add "X-Amz-Content-Sha256", valid_607337
  var valid_607338 = header.getOrDefault("X-Amz-Date")
  valid_607338 = validateParameter(valid_607338, JString, required = false,
                                 default = nil)
  if valid_607338 != nil:
    section.add "X-Amz-Date", valid_607338
  var valid_607339 = header.getOrDefault("X-Amz-Credential")
  valid_607339 = validateParameter(valid_607339, JString, required = false,
                                 default = nil)
  if valid_607339 != nil:
    section.add "X-Amz-Credential", valid_607339
  var valid_607340 = header.getOrDefault("X-Amz-Security-Token")
  valid_607340 = validateParameter(valid_607340, JString, required = false,
                                 default = nil)
  if valid_607340 != nil:
    section.add "X-Amz-Security-Token", valid_607340
  var valid_607341 = header.getOrDefault("X-Amz-Algorithm")
  valid_607341 = validateParameter(valid_607341, JString, required = false,
                                 default = nil)
  if valid_607341 != nil:
    section.add "X-Amz-Algorithm", valid_607341
  var valid_607342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607342 = validateParameter(valid_607342, JString, required = false,
                                 default = nil)
  if valid_607342 != nil:
    section.add "X-Amz-SignedHeaders", valid_607342
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic to which to add tags.
  ##   Tags: JArray (required)
  ##       : The tags to be added to the specified topic. A tag consists of a required key and an optional value.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_607343 = formData.getOrDefault("ResourceArn")
  valid_607343 = validateParameter(valid_607343, JString, required = true,
                                 default = nil)
  if valid_607343 != nil:
    section.add "ResourceArn", valid_607343
  var valid_607344 = formData.getOrDefault("Tags")
  valid_607344 = validateParameter(valid_607344, JArray, required = true, default = nil)
  if valid_607344 != nil:
    section.add "Tags", valid_607344
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607345: Call_PostTagResource_607331; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account, per AWS region. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul>
  ## 
  let valid = call_607345.validator(path, query, header, formData, body)
  let scheme = call_607345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607345.url(scheme.get, call_607345.host, call_607345.base,
                         call_607345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607345, url, valid)

proc call*(call_607346: Call_PostTagResource_607331; ResourceArn: string;
          Tags: JsonNode; Action: string = "TagResource";
          Version: string = "2010-03-31"): Recallable =
  ## postTagResource
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account, per AWS region. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul>
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic to which to add tags.
  ##   Action: string (required)
  ##   Tags: JArray (required)
  ##       : The tags to be added to the specified topic. A tag consists of a required key and an optional value.
  ##   Version: string (required)
  var query_607347 = newJObject()
  var formData_607348 = newJObject()
  add(formData_607348, "ResourceArn", newJString(ResourceArn))
  add(query_607347, "Action", newJString(Action))
  if Tags != nil:
    formData_607348.add "Tags", Tags
  add(query_607347, "Version", newJString(Version))
  result = call_607346.call(nil, query_607347, nil, formData_607348, nil)

var postTagResource* = Call_PostTagResource_607331(name: "postTagResource",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_PostTagResource_607332,
    base: "/", url: url_PostTagResource_607333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagResource_607314 = ref object of OpenApiRestCall_605589
proc url_GetTagResource_607316(protocol: Scheme; host: string; base: string;
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

proc validate_GetTagResource_607315(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account, per AWS region. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray (required)
  ##       : The tags to be added to the specified topic. A tag consists of a required key and an optional value.
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic to which to add tags.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Tags` field"
  var valid_607317 = query.getOrDefault("Tags")
  valid_607317 = validateParameter(valid_607317, JArray, required = true, default = nil)
  if valid_607317 != nil:
    section.add "Tags", valid_607317
  var valid_607318 = query.getOrDefault("ResourceArn")
  valid_607318 = validateParameter(valid_607318, JString, required = true,
                                 default = nil)
  if valid_607318 != nil:
    section.add "ResourceArn", valid_607318
  var valid_607319 = query.getOrDefault("Action")
  valid_607319 = validateParameter(valid_607319, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_607319 != nil:
    section.add "Action", valid_607319
  var valid_607320 = query.getOrDefault("Version")
  valid_607320 = validateParameter(valid_607320, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_607320 != nil:
    section.add "Version", valid_607320
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607321 = header.getOrDefault("X-Amz-Signature")
  valid_607321 = validateParameter(valid_607321, JString, required = false,
                                 default = nil)
  if valid_607321 != nil:
    section.add "X-Amz-Signature", valid_607321
  var valid_607322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607322 = validateParameter(valid_607322, JString, required = false,
                                 default = nil)
  if valid_607322 != nil:
    section.add "X-Amz-Content-Sha256", valid_607322
  var valid_607323 = header.getOrDefault("X-Amz-Date")
  valid_607323 = validateParameter(valid_607323, JString, required = false,
                                 default = nil)
  if valid_607323 != nil:
    section.add "X-Amz-Date", valid_607323
  var valid_607324 = header.getOrDefault("X-Amz-Credential")
  valid_607324 = validateParameter(valid_607324, JString, required = false,
                                 default = nil)
  if valid_607324 != nil:
    section.add "X-Amz-Credential", valid_607324
  var valid_607325 = header.getOrDefault("X-Amz-Security-Token")
  valid_607325 = validateParameter(valid_607325, JString, required = false,
                                 default = nil)
  if valid_607325 != nil:
    section.add "X-Amz-Security-Token", valid_607325
  var valid_607326 = header.getOrDefault("X-Amz-Algorithm")
  valid_607326 = validateParameter(valid_607326, JString, required = false,
                                 default = nil)
  if valid_607326 != nil:
    section.add "X-Amz-Algorithm", valid_607326
  var valid_607327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607327 = validateParameter(valid_607327, JString, required = false,
                                 default = nil)
  if valid_607327 != nil:
    section.add "X-Amz-SignedHeaders", valid_607327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607328: Call_GetTagResource_607314; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account, per AWS region. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul>
  ## 
  let valid = call_607328.validator(path, query, header, formData, body)
  let scheme = call_607328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607328.url(scheme.get, call_607328.host, call_607328.base,
                         call_607328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607328, url, valid)

proc call*(call_607329: Call_GetTagResource_607314; Tags: JsonNode;
          ResourceArn: string; Action: string = "TagResource";
          Version: string = "2010-03-31"): Recallable =
  ## getTagResource
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account, per AWS region. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul>
  ##   Tags: JArray (required)
  ##       : The tags to be added to the specified topic. A tag consists of a required key and an optional value.
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic to which to add tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607330 = newJObject()
  if Tags != nil:
    query_607330.add "Tags", Tags
  add(query_607330, "ResourceArn", newJString(ResourceArn))
  add(query_607330, "Action", newJString(Action))
  add(query_607330, "Version", newJString(Version))
  result = call_607329.call(nil, query_607330, nil, nil, nil)

var getTagResource* = Call_GetTagResource_607314(name: "getTagResource",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_GetTagResource_607315,
    base: "/", url: url_GetTagResource_607316, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUnsubscribe_607365 = ref object of OpenApiRestCall_605589
proc url_PostUnsubscribe_607367(protocol: Scheme; host: string; base: string;
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

proc validate_PostUnsubscribe_607366(path: JsonNode; query: JsonNode;
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
  var valid_607368 = query.getOrDefault("Action")
  valid_607368 = validateParameter(valid_607368, JString, required = true,
                                 default = newJString("Unsubscribe"))
  if valid_607368 != nil:
    section.add "Action", valid_607368
  var valid_607369 = query.getOrDefault("Version")
  valid_607369 = validateParameter(valid_607369, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_607369 != nil:
    section.add "Version", valid_607369
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607370 = header.getOrDefault("X-Amz-Signature")
  valid_607370 = validateParameter(valid_607370, JString, required = false,
                                 default = nil)
  if valid_607370 != nil:
    section.add "X-Amz-Signature", valid_607370
  var valid_607371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607371 = validateParameter(valid_607371, JString, required = false,
                                 default = nil)
  if valid_607371 != nil:
    section.add "X-Amz-Content-Sha256", valid_607371
  var valid_607372 = header.getOrDefault("X-Amz-Date")
  valid_607372 = validateParameter(valid_607372, JString, required = false,
                                 default = nil)
  if valid_607372 != nil:
    section.add "X-Amz-Date", valid_607372
  var valid_607373 = header.getOrDefault("X-Amz-Credential")
  valid_607373 = validateParameter(valid_607373, JString, required = false,
                                 default = nil)
  if valid_607373 != nil:
    section.add "X-Amz-Credential", valid_607373
  var valid_607374 = header.getOrDefault("X-Amz-Security-Token")
  valid_607374 = validateParameter(valid_607374, JString, required = false,
                                 default = nil)
  if valid_607374 != nil:
    section.add "X-Amz-Security-Token", valid_607374
  var valid_607375 = header.getOrDefault("X-Amz-Algorithm")
  valid_607375 = validateParameter(valid_607375, JString, required = false,
                                 default = nil)
  if valid_607375 != nil:
    section.add "X-Amz-Algorithm", valid_607375
  var valid_607376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607376 = validateParameter(valid_607376, JString, required = false,
                                 default = nil)
  if valid_607376 != nil:
    section.add "X-Amz-SignedHeaders", valid_607376
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription to be deleted.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionArn` field"
  var valid_607377 = formData.getOrDefault("SubscriptionArn")
  valid_607377 = validateParameter(valid_607377, JString, required = true,
                                 default = nil)
  if valid_607377 != nil:
    section.add "SubscriptionArn", valid_607377
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607378: Call_PostUnsubscribe_607365; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_607378.validator(path, query, header, formData, body)
  let scheme = call_607378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607378.url(scheme.get, call_607378.host, call_607378.base,
                         call_607378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607378, url, valid)

proc call*(call_607379: Call_PostUnsubscribe_607365; SubscriptionArn: string;
          Action: string = "Unsubscribe"; Version: string = "2010-03-31"): Recallable =
  ## postUnsubscribe
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to be deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607380 = newJObject()
  var formData_607381 = newJObject()
  add(formData_607381, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_607380, "Action", newJString(Action))
  add(query_607380, "Version", newJString(Version))
  result = call_607379.call(nil, query_607380, nil, formData_607381, nil)

var postUnsubscribe* = Call_PostUnsubscribe_607365(name: "postUnsubscribe",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=Unsubscribe", validator: validate_PostUnsubscribe_607366,
    base: "/", url: url_PostUnsubscribe_607367, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUnsubscribe_607349 = ref object of OpenApiRestCall_605589
proc url_GetUnsubscribe_607351(protocol: Scheme; host: string; base: string;
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

proc validate_GetUnsubscribe_607350(path: JsonNode; query: JsonNode;
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
  var valid_607352 = query.getOrDefault("SubscriptionArn")
  valid_607352 = validateParameter(valid_607352, JString, required = true,
                                 default = nil)
  if valid_607352 != nil:
    section.add "SubscriptionArn", valid_607352
  var valid_607353 = query.getOrDefault("Action")
  valid_607353 = validateParameter(valid_607353, JString, required = true,
                                 default = newJString("Unsubscribe"))
  if valid_607353 != nil:
    section.add "Action", valid_607353
  var valid_607354 = query.getOrDefault("Version")
  valid_607354 = validateParameter(valid_607354, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_607354 != nil:
    section.add "Version", valid_607354
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607355 = header.getOrDefault("X-Amz-Signature")
  valid_607355 = validateParameter(valid_607355, JString, required = false,
                                 default = nil)
  if valid_607355 != nil:
    section.add "X-Amz-Signature", valid_607355
  var valid_607356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607356 = validateParameter(valid_607356, JString, required = false,
                                 default = nil)
  if valid_607356 != nil:
    section.add "X-Amz-Content-Sha256", valid_607356
  var valid_607357 = header.getOrDefault("X-Amz-Date")
  valid_607357 = validateParameter(valid_607357, JString, required = false,
                                 default = nil)
  if valid_607357 != nil:
    section.add "X-Amz-Date", valid_607357
  var valid_607358 = header.getOrDefault("X-Amz-Credential")
  valid_607358 = validateParameter(valid_607358, JString, required = false,
                                 default = nil)
  if valid_607358 != nil:
    section.add "X-Amz-Credential", valid_607358
  var valid_607359 = header.getOrDefault("X-Amz-Security-Token")
  valid_607359 = validateParameter(valid_607359, JString, required = false,
                                 default = nil)
  if valid_607359 != nil:
    section.add "X-Amz-Security-Token", valid_607359
  var valid_607360 = header.getOrDefault("X-Amz-Algorithm")
  valid_607360 = validateParameter(valid_607360, JString, required = false,
                                 default = nil)
  if valid_607360 != nil:
    section.add "X-Amz-Algorithm", valid_607360
  var valid_607361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607361 = validateParameter(valid_607361, JString, required = false,
                                 default = nil)
  if valid_607361 != nil:
    section.add "X-Amz-SignedHeaders", valid_607361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607362: Call_GetUnsubscribe_607349; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_607362.validator(path, query, header, formData, body)
  let scheme = call_607362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607362.url(scheme.get, call_607362.host, call_607362.base,
                         call_607362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607362, url, valid)

proc call*(call_607363: Call_GetUnsubscribe_607349; SubscriptionArn: string;
          Action: string = "Unsubscribe"; Version: string = "2010-03-31"): Recallable =
  ## getUnsubscribe
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to be deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607364 = newJObject()
  add(query_607364, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_607364, "Action", newJString(Action))
  add(query_607364, "Version", newJString(Version))
  result = call_607363.call(nil, query_607364, nil, nil, nil)

var getUnsubscribe* = Call_GetUnsubscribe_607349(name: "getUnsubscribe",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=Unsubscribe", validator: validate_GetUnsubscribe_607350,
    base: "/", url: url_GetUnsubscribe_607351, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUntagResource_607399 = ref object of OpenApiRestCall_605589
proc url_PostUntagResource_607401(protocol: Scheme; host: string; base: string;
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

proc validate_PostUntagResource_607400(path: JsonNode; query: JsonNode;
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
  var valid_607402 = query.getOrDefault("Action")
  valid_607402 = validateParameter(valid_607402, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_607402 != nil:
    section.add "Action", valid_607402
  var valid_607403 = query.getOrDefault("Version")
  valid_607403 = validateParameter(valid_607403, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_607403 != nil:
    section.add "Version", valid_607403
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607404 = header.getOrDefault("X-Amz-Signature")
  valid_607404 = validateParameter(valid_607404, JString, required = false,
                                 default = nil)
  if valid_607404 != nil:
    section.add "X-Amz-Signature", valid_607404
  var valid_607405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607405 = validateParameter(valid_607405, JString, required = false,
                                 default = nil)
  if valid_607405 != nil:
    section.add "X-Amz-Content-Sha256", valid_607405
  var valid_607406 = header.getOrDefault("X-Amz-Date")
  valid_607406 = validateParameter(valid_607406, JString, required = false,
                                 default = nil)
  if valid_607406 != nil:
    section.add "X-Amz-Date", valid_607406
  var valid_607407 = header.getOrDefault("X-Amz-Credential")
  valid_607407 = validateParameter(valid_607407, JString, required = false,
                                 default = nil)
  if valid_607407 != nil:
    section.add "X-Amz-Credential", valid_607407
  var valid_607408 = header.getOrDefault("X-Amz-Security-Token")
  valid_607408 = validateParameter(valid_607408, JString, required = false,
                                 default = nil)
  if valid_607408 != nil:
    section.add "X-Amz-Security-Token", valid_607408
  var valid_607409 = header.getOrDefault("X-Amz-Algorithm")
  valid_607409 = validateParameter(valid_607409, JString, required = false,
                                 default = nil)
  if valid_607409 != nil:
    section.add "X-Amz-Algorithm", valid_607409
  var valid_607410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607410 = validateParameter(valid_607410, JString, required = false,
                                 default = nil)
  if valid_607410 != nil:
    section.add "X-Amz-SignedHeaders", valid_607410
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the specified topic.
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic from which to remove tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_607411 = formData.getOrDefault("TagKeys")
  valid_607411 = validateParameter(valid_607411, JArray, required = true, default = nil)
  if valid_607411 != nil:
    section.add "TagKeys", valid_607411
  var valid_607412 = formData.getOrDefault("ResourceArn")
  valid_607412 = validateParameter(valid_607412, JString, required = true,
                                 default = nil)
  if valid_607412 != nil:
    section.add "ResourceArn", valid_607412
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607413: Call_PostUntagResource_607399; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  let valid = call_607413.validator(path, query, header, formData, body)
  let scheme = call_607413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607413.url(scheme.get, call_607413.host, call_607413.base,
                         call_607413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607413, url, valid)

proc call*(call_607414: Call_PostUntagResource_607399; TagKeys: JsonNode;
          ResourceArn: string; Action: string = "UntagResource";
          Version: string = "2010-03-31"): Recallable =
  ## postUntagResource
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the specified topic.
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic from which to remove tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607415 = newJObject()
  var formData_607416 = newJObject()
  if TagKeys != nil:
    formData_607416.add "TagKeys", TagKeys
  add(formData_607416, "ResourceArn", newJString(ResourceArn))
  add(query_607415, "Action", newJString(Action))
  add(query_607415, "Version", newJString(Version))
  result = call_607414.call(nil, query_607415, nil, formData_607416, nil)

var postUntagResource* = Call_PostUntagResource_607399(name: "postUntagResource",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_PostUntagResource_607400,
    base: "/", url: url_PostUntagResource_607401,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUntagResource_607382 = ref object of OpenApiRestCall_605589
proc url_GetUntagResource_607384(protocol: Scheme; host: string; base: string;
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

proc validate_GetUntagResource_607383(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the specified topic.
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic from which to remove tags.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `TagKeys` field"
  var valid_607385 = query.getOrDefault("TagKeys")
  valid_607385 = validateParameter(valid_607385, JArray, required = true, default = nil)
  if valid_607385 != nil:
    section.add "TagKeys", valid_607385
  var valid_607386 = query.getOrDefault("ResourceArn")
  valid_607386 = validateParameter(valid_607386, JString, required = true,
                                 default = nil)
  if valid_607386 != nil:
    section.add "ResourceArn", valid_607386
  var valid_607387 = query.getOrDefault("Action")
  valid_607387 = validateParameter(valid_607387, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_607387 != nil:
    section.add "Action", valid_607387
  var valid_607388 = query.getOrDefault("Version")
  valid_607388 = validateParameter(valid_607388, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_607388 != nil:
    section.add "Version", valid_607388
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607389 = header.getOrDefault("X-Amz-Signature")
  valid_607389 = validateParameter(valid_607389, JString, required = false,
                                 default = nil)
  if valid_607389 != nil:
    section.add "X-Amz-Signature", valid_607389
  var valid_607390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607390 = validateParameter(valid_607390, JString, required = false,
                                 default = nil)
  if valid_607390 != nil:
    section.add "X-Amz-Content-Sha256", valid_607390
  var valid_607391 = header.getOrDefault("X-Amz-Date")
  valid_607391 = validateParameter(valid_607391, JString, required = false,
                                 default = nil)
  if valid_607391 != nil:
    section.add "X-Amz-Date", valid_607391
  var valid_607392 = header.getOrDefault("X-Amz-Credential")
  valid_607392 = validateParameter(valid_607392, JString, required = false,
                                 default = nil)
  if valid_607392 != nil:
    section.add "X-Amz-Credential", valid_607392
  var valid_607393 = header.getOrDefault("X-Amz-Security-Token")
  valid_607393 = validateParameter(valid_607393, JString, required = false,
                                 default = nil)
  if valid_607393 != nil:
    section.add "X-Amz-Security-Token", valid_607393
  var valid_607394 = header.getOrDefault("X-Amz-Algorithm")
  valid_607394 = validateParameter(valid_607394, JString, required = false,
                                 default = nil)
  if valid_607394 != nil:
    section.add "X-Amz-Algorithm", valid_607394
  var valid_607395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607395 = validateParameter(valid_607395, JString, required = false,
                                 default = nil)
  if valid_607395 != nil:
    section.add "X-Amz-SignedHeaders", valid_607395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607396: Call_GetUntagResource_607382; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  let valid = call_607396.validator(path, query, header, formData, body)
  let scheme = call_607396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607396.url(scheme.get, call_607396.host, call_607396.base,
                         call_607396.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607396, url, valid)

proc call*(call_607397: Call_GetUntagResource_607382; TagKeys: JsonNode;
          ResourceArn: string; Action: string = "UntagResource";
          Version: string = "2010-03-31"): Recallable =
  ## getUntagResource
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the specified topic.
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic from which to remove tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607398 = newJObject()
  if TagKeys != nil:
    query_607398.add "TagKeys", TagKeys
  add(query_607398, "ResourceArn", newJString(ResourceArn))
  add(query_607398, "Action", newJString(Action))
  add(query_607398, "Version", newJString(Version))
  result = call_607397.call(nil, query_607398, nil, nil, nil)

var getUntagResource* = Call_GetUntagResource_607382(name: "getUntagResource",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_GetUntagResource_607383,
    base: "/", url: url_GetUntagResource_607384,
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
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
