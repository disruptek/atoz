
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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
  Call_PostAddPermission_613270 = ref object of OpenApiRestCall_612658
proc url_PostAddPermission_613272(protocol: Scheme; host: string; base: string;
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

proc validate_PostAddPermission_613271(path: JsonNode; query: JsonNode;
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
  var valid_613273 = query.getOrDefault("Action")
  valid_613273 = validateParameter(valid_613273, JString, required = true,
                                 default = newJString("AddPermission"))
  if valid_613273 != nil:
    section.add "Action", valid_613273
  var valid_613274 = query.getOrDefault("Version")
  valid_613274 = validateParameter(valid_613274, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613274 != nil:
    section.add "Version", valid_613274
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613275 = header.getOrDefault("X-Amz-Signature")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Signature", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-Content-Sha256", valid_613276
  var valid_613277 = header.getOrDefault("X-Amz-Date")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-Date", valid_613277
  var valid_613278 = header.getOrDefault("X-Amz-Credential")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-Credential", valid_613278
  var valid_613279 = header.getOrDefault("X-Amz-Security-Token")
  valid_613279 = validateParameter(valid_613279, JString, required = false,
                                 default = nil)
  if valid_613279 != nil:
    section.add "X-Amz-Security-Token", valid_613279
  var valid_613280 = header.getOrDefault("X-Amz-Algorithm")
  valid_613280 = validateParameter(valid_613280, JString, required = false,
                                 default = nil)
  if valid_613280 != nil:
    section.add "X-Amz-Algorithm", valid_613280
  var valid_613281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613281 = validateParameter(valid_613281, JString, required = false,
                                 default = nil)
  if valid_613281 != nil:
    section.add "X-Amz-SignedHeaders", valid_613281
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
  var valid_613282 = formData.getOrDefault("TopicArn")
  valid_613282 = validateParameter(valid_613282, JString, required = true,
                                 default = nil)
  if valid_613282 != nil:
    section.add "TopicArn", valid_613282
  var valid_613283 = formData.getOrDefault("AWSAccountId")
  valid_613283 = validateParameter(valid_613283, JArray, required = true, default = nil)
  if valid_613283 != nil:
    section.add "AWSAccountId", valid_613283
  var valid_613284 = formData.getOrDefault("Label")
  valid_613284 = validateParameter(valid_613284, JString, required = true,
                                 default = nil)
  if valid_613284 != nil:
    section.add "Label", valid_613284
  var valid_613285 = formData.getOrDefault("ActionName")
  valid_613285 = validateParameter(valid_613285, JArray, required = true, default = nil)
  if valid_613285 != nil:
    section.add "ActionName", valid_613285
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613286: Call_PostAddPermission_613270; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  let valid = call_613286.validator(path, query, header, formData, body)
  let scheme = call_613286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613286.url(scheme.get, call_613286.host, call_613286.base,
                         call_613286.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613286, url, valid)

proc call*(call_613287: Call_PostAddPermission_613270; TopicArn: string;
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
  var query_613288 = newJObject()
  var formData_613289 = newJObject()
  add(formData_613289, "TopicArn", newJString(TopicArn))
  add(query_613288, "Action", newJString(Action))
  if AWSAccountId != nil:
    formData_613289.add "AWSAccountId", AWSAccountId
  add(formData_613289, "Label", newJString(Label))
  if ActionName != nil:
    formData_613289.add "ActionName", ActionName
  add(query_613288, "Version", newJString(Version))
  result = call_613287.call(nil, query_613288, nil, formData_613289, nil)

var postAddPermission* = Call_PostAddPermission_613270(name: "postAddPermission",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=AddPermission", validator: validate_PostAddPermission_613271,
    base: "/", url: url_PostAddPermission_613272,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddPermission_612996 = ref object of OpenApiRestCall_612658
proc url_GetAddPermission_612998(protocol: Scheme; host: string; base: string;
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

proc validate_GetAddPermission_612997(path: JsonNode; query: JsonNode;
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
  var valid_613110 = query.getOrDefault("TopicArn")
  valid_613110 = validateParameter(valid_613110, JString, required = true,
                                 default = nil)
  if valid_613110 != nil:
    section.add "TopicArn", valid_613110
  var valid_613124 = query.getOrDefault("Action")
  valid_613124 = validateParameter(valid_613124, JString, required = true,
                                 default = newJString("AddPermission"))
  if valid_613124 != nil:
    section.add "Action", valid_613124
  var valid_613125 = query.getOrDefault("ActionName")
  valid_613125 = validateParameter(valid_613125, JArray, required = true, default = nil)
  if valid_613125 != nil:
    section.add "ActionName", valid_613125
  var valid_613126 = query.getOrDefault("Version")
  valid_613126 = validateParameter(valid_613126, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613126 != nil:
    section.add "Version", valid_613126
  var valid_613127 = query.getOrDefault("AWSAccountId")
  valid_613127 = validateParameter(valid_613127, JArray, required = true, default = nil)
  if valid_613127 != nil:
    section.add "AWSAccountId", valid_613127
  var valid_613128 = query.getOrDefault("Label")
  valid_613128 = validateParameter(valid_613128, JString, required = true,
                                 default = nil)
  if valid_613128 != nil:
    section.add "Label", valid_613128
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613129 = header.getOrDefault("X-Amz-Signature")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Signature", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-Content-Sha256", valid_613130
  var valid_613131 = header.getOrDefault("X-Amz-Date")
  valid_613131 = validateParameter(valid_613131, JString, required = false,
                                 default = nil)
  if valid_613131 != nil:
    section.add "X-Amz-Date", valid_613131
  var valid_613132 = header.getOrDefault("X-Amz-Credential")
  valid_613132 = validateParameter(valid_613132, JString, required = false,
                                 default = nil)
  if valid_613132 != nil:
    section.add "X-Amz-Credential", valid_613132
  var valid_613133 = header.getOrDefault("X-Amz-Security-Token")
  valid_613133 = validateParameter(valid_613133, JString, required = false,
                                 default = nil)
  if valid_613133 != nil:
    section.add "X-Amz-Security-Token", valid_613133
  var valid_613134 = header.getOrDefault("X-Amz-Algorithm")
  valid_613134 = validateParameter(valid_613134, JString, required = false,
                                 default = nil)
  if valid_613134 != nil:
    section.add "X-Amz-Algorithm", valid_613134
  var valid_613135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613135 = validateParameter(valid_613135, JString, required = false,
                                 default = nil)
  if valid_613135 != nil:
    section.add "X-Amz-SignedHeaders", valid_613135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613158: Call_GetAddPermission_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  let valid = call_613158.validator(path, query, header, formData, body)
  let scheme = call_613158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613158.url(scheme.get, call_613158.host, call_613158.base,
                         call_613158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613158, url, valid)

proc call*(call_613229: Call_GetAddPermission_612996; TopicArn: string;
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
  var query_613230 = newJObject()
  add(query_613230, "TopicArn", newJString(TopicArn))
  add(query_613230, "Action", newJString(Action))
  if ActionName != nil:
    query_613230.add "ActionName", ActionName
  add(query_613230, "Version", newJString(Version))
  if AWSAccountId != nil:
    query_613230.add "AWSAccountId", AWSAccountId
  add(query_613230, "Label", newJString(Label))
  result = call_613229.call(nil, query_613230, nil, nil, nil)

var getAddPermission* = Call_GetAddPermission_612996(name: "getAddPermission",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=AddPermission", validator: validate_GetAddPermission_612997,
    base: "/", url: url_GetAddPermission_612998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCheckIfPhoneNumberIsOptedOut_613306 = ref object of OpenApiRestCall_612658
proc url_PostCheckIfPhoneNumberIsOptedOut_613308(protocol: Scheme; host: string;
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

proc validate_PostCheckIfPhoneNumberIsOptedOut_613307(path: JsonNode;
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
  var valid_613309 = query.getOrDefault("Action")
  valid_613309 = validateParameter(valid_613309, JString, required = true, default = newJString(
      "CheckIfPhoneNumberIsOptedOut"))
  if valid_613309 != nil:
    section.add "Action", valid_613309
  var valid_613310 = query.getOrDefault("Version")
  valid_613310 = validateParameter(valid_613310, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613310 != nil:
    section.add "Version", valid_613310
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613311 = header.getOrDefault("X-Amz-Signature")
  valid_613311 = validateParameter(valid_613311, JString, required = false,
                                 default = nil)
  if valid_613311 != nil:
    section.add "X-Amz-Signature", valid_613311
  var valid_613312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613312 = validateParameter(valid_613312, JString, required = false,
                                 default = nil)
  if valid_613312 != nil:
    section.add "X-Amz-Content-Sha256", valid_613312
  var valid_613313 = header.getOrDefault("X-Amz-Date")
  valid_613313 = validateParameter(valid_613313, JString, required = false,
                                 default = nil)
  if valid_613313 != nil:
    section.add "X-Amz-Date", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-Credential")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-Credential", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-Security-Token")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Security-Token", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-Algorithm")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Algorithm", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-SignedHeaders", valid_613317
  result.add "header", section
  ## parameters in `formData` object:
  ##   phoneNumber: JString (required)
  ##              : The phone number for which you want to check the opt out status.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `phoneNumber` field"
  var valid_613318 = formData.getOrDefault("phoneNumber")
  valid_613318 = validateParameter(valid_613318, JString, required = true,
                                 default = nil)
  if valid_613318 != nil:
    section.add "phoneNumber", valid_613318
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613319: Call_PostCheckIfPhoneNumberIsOptedOut_613306;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ## 
  let valid = call_613319.validator(path, query, header, formData, body)
  let scheme = call_613319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613319.url(scheme.get, call_613319.host, call_613319.base,
                         call_613319.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613319, url, valid)

proc call*(call_613320: Call_PostCheckIfPhoneNumberIsOptedOut_613306;
          phoneNumber: string; Action: string = "CheckIfPhoneNumberIsOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## postCheckIfPhoneNumberIsOptedOut
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number for which you want to check the opt out status.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613321 = newJObject()
  var formData_613322 = newJObject()
  add(formData_613322, "phoneNumber", newJString(phoneNumber))
  add(query_613321, "Action", newJString(Action))
  add(query_613321, "Version", newJString(Version))
  result = call_613320.call(nil, query_613321, nil, formData_613322, nil)

var postCheckIfPhoneNumberIsOptedOut* = Call_PostCheckIfPhoneNumberIsOptedOut_613306(
    name: "postCheckIfPhoneNumberIsOptedOut", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CheckIfPhoneNumberIsOptedOut",
    validator: validate_PostCheckIfPhoneNumberIsOptedOut_613307, base: "/",
    url: url_PostCheckIfPhoneNumberIsOptedOut_613308,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCheckIfPhoneNumberIsOptedOut_613290 = ref object of OpenApiRestCall_612658
proc url_GetCheckIfPhoneNumberIsOptedOut_613292(protocol: Scheme; host: string;
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

proc validate_GetCheckIfPhoneNumberIsOptedOut_613291(path: JsonNode;
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
  var valid_613293 = query.getOrDefault("phoneNumber")
  valid_613293 = validateParameter(valid_613293, JString, required = true,
                                 default = nil)
  if valid_613293 != nil:
    section.add "phoneNumber", valid_613293
  var valid_613294 = query.getOrDefault("Action")
  valid_613294 = validateParameter(valid_613294, JString, required = true, default = newJString(
      "CheckIfPhoneNumberIsOptedOut"))
  if valid_613294 != nil:
    section.add "Action", valid_613294
  var valid_613295 = query.getOrDefault("Version")
  valid_613295 = validateParameter(valid_613295, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613295 != nil:
    section.add "Version", valid_613295
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613296 = header.getOrDefault("X-Amz-Signature")
  valid_613296 = validateParameter(valid_613296, JString, required = false,
                                 default = nil)
  if valid_613296 != nil:
    section.add "X-Amz-Signature", valid_613296
  var valid_613297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613297 = validateParameter(valid_613297, JString, required = false,
                                 default = nil)
  if valid_613297 != nil:
    section.add "X-Amz-Content-Sha256", valid_613297
  var valid_613298 = header.getOrDefault("X-Amz-Date")
  valid_613298 = validateParameter(valid_613298, JString, required = false,
                                 default = nil)
  if valid_613298 != nil:
    section.add "X-Amz-Date", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-Credential")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-Credential", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Security-Token")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Security-Token", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Algorithm")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Algorithm", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-SignedHeaders", valid_613302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613303: Call_GetCheckIfPhoneNumberIsOptedOut_613290;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ## 
  let valid = call_613303.validator(path, query, header, formData, body)
  let scheme = call_613303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613303.url(scheme.get, call_613303.host, call_613303.base,
                         call_613303.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613303, url, valid)

proc call*(call_613304: Call_GetCheckIfPhoneNumberIsOptedOut_613290;
          phoneNumber: string; Action: string = "CheckIfPhoneNumberIsOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## getCheckIfPhoneNumberIsOptedOut
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number for which you want to check the opt out status.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613305 = newJObject()
  add(query_613305, "phoneNumber", newJString(phoneNumber))
  add(query_613305, "Action", newJString(Action))
  add(query_613305, "Version", newJString(Version))
  result = call_613304.call(nil, query_613305, nil, nil, nil)

var getCheckIfPhoneNumberIsOptedOut* = Call_GetCheckIfPhoneNumberIsOptedOut_613290(
    name: "getCheckIfPhoneNumberIsOptedOut", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CheckIfPhoneNumberIsOptedOut",
    validator: validate_GetCheckIfPhoneNumberIsOptedOut_613291, base: "/",
    url: url_GetCheckIfPhoneNumberIsOptedOut_613292,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostConfirmSubscription_613341 = ref object of OpenApiRestCall_612658
proc url_PostConfirmSubscription_613343(protocol: Scheme; host: string; base: string;
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

proc validate_PostConfirmSubscription_613342(path: JsonNode; query: JsonNode;
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
  var valid_613344 = query.getOrDefault("Action")
  valid_613344 = validateParameter(valid_613344, JString, required = true,
                                 default = newJString("ConfirmSubscription"))
  if valid_613344 != nil:
    section.add "Action", valid_613344
  var valid_613345 = query.getOrDefault("Version")
  valid_613345 = validateParameter(valid_613345, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613345 != nil:
    section.add "Version", valid_613345
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613346 = header.getOrDefault("X-Amz-Signature")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-Signature", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Content-Sha256", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Date")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Date", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-Credential")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-Credential", valid_613349
  var valid_613350 = header.getOrDefault("X-Amz-Security-Token")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-Security-Token", valid_613350
  var valid_613351 = header.getOrDefault("X-Amz-Algorithm")
  valid_613351 = validateParameter(valid_613351, JString, required = false,
                                 default = nil)
  if valid_613351 != nil:
    section.add "X-Amz-Algorithm", valid_613351
  var valid_613352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613352 = validateParameter(valid_613352, JString, required = false,
                                 default = nil)
  if valid_613352 != nil:
    section.add "X-Amz-SignedHeaders", valid_613352
  result.add "header", section
  ## parameters in `formData` object:
  ##   AuthenticateOnUnsubscribe: JString
  ##                            : Disallows unauthenticated unsubscribes of the subscription. If the value of this parameter is <code>true</code> and the request has an AWS signature, then only the topic owner and the subscription owner can unsubscribe the endpoint. The unsubscribe action requires AWS authentication. 
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic for which you wish to confirm a subscription.
  ##   Token: JString (required)
  ##        : Short-lived token sent to an endpoint during the <code>Subscribe</code> action.
  section = newJObject()
  var valid_613353 = formData.getOrDefault("AuthenticateOnUnsubscribe")
  valid_613353 = validateParameter(valid_613353, JString, required = false,
                                 default = nil)
  if valid_613353 != nil:
    section.add "AuthenticateOnUnsubscribe", valid_613353
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_613354 = formData.getOrDefault("TopicArn")
  valid_613354 = validateParameter(valid_613354, JString, required = true,
                                 default = nil)
  if valid_613354 != nil:
    section.add "TopicArn", valid_613354
  var valid_613355 = formData.getOrDefault("Token")
  valid_613355 = validateParameter(valid_613355, JString, required = true,
                                 default = nil)
  if valid_613355 != nil:
    section.add "Token", valid_613355
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613356: Call_PostConfirmSubscription_613341; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  let valid = call_613356.validator(path, query, header, formData, body)
  let scheme = call_613356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613356.url(scheme.get, call_613356.host, call_613356.base,
                         call_613356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613356, url, valid)

proc call*(call_613357: Call_PostConfirmSubscription_613341; TopicArn: string;
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
  var query_613358 = newJObject()
  var formData_613359 = newJObject()
  add(formData_613359, "AuthenticateOnUnsubscribe",
      newJString(AuthenticateOnUnsubscribe))
  add(formData_613359, "TopicArn", newJString(TopicArn))
  add(formData_613359, "Token", newJString(Token))
  add(query_613358, "Action", newJString(Action))
  add(query_613358, "Version", newJString(Version))
  result = call_613357.call(nil, query_613358, nil, formData_613359, nil)

var postConfirmSubscription* = Call_PostConfirmSubscription_613341(
    name: "postConfirmSubscription", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ConfirmSubscription",
    validator: validate_PostConfirmSubscription_613342, base: "/",
    url: url_PostConfirmSubscription_613343, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfirmSubscription_613323 = ref object of OpenApiRestCall_612658
proc url_GetConfirmSubscription_613325(protocol: Scheme; host: string; base: string;
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

proc validate_GetConfirmSubscription_613324(path: JsonNode; query: JsonNode;
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
  var valid_613326 = query.getOrDefault("AuthenticateOnUnsubscribe")
  valid_613326 = validateParameter(valid_613326, JString, required = false,
                                 default = nil)
  if valid_613326 != nil:
    section.add "AuthenticateOnUnsubscribe", valid_613326
  assert query != nil, "query argument is necessary due to required `Token` field"
  var valid_613327 = query.getOrDefault("Token")
  valid_613327 = validateParameter(valid_613327, JString, required = true,
                                 default = nil)
  if valid_613327 != nil:
    section.add "Token", valid_613327
  var valid_613328 = query.getOrDefault("Action")
  valid_613328 = validateParameter(valid_613328, JString, required = true,
                                 default = newJString("ConfirmSubscription"))
  if valid_613328 != nil:
    section.add "Action", valid_613328
  var valid_613329 = query.getOrDefault("Version")
  valid_613329 = validateParameter(valid_613329, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613329 != nil:
    section.add "Version", valid_613329
  var valid_613330 = query.getOrDefault("TopicArn")
  valid_613330 = validateParameter(valid_613330, JString, required = true,
                                 default = nil)
  if valid_613330 != nil:
    section.add "TopicArn", valid_613330
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613331 = header.getOrDefault("X-Amz-Signature")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Signature", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Content-Sha256", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Date")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Date", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-Credential")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Credential", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-Security-Token")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-Security-Token", valid_613335
  var valid_613336 = header.getOrDefault("X-Amz-Algorithm")
  valid_613336 = validateParameter(valid_613336, JString, required = false,
                                 default = nil)
  if valid_613336 != nil:
    section.add "X-Amz-Algorithm", valid_613336
  var valid_613337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613337 = validateParameter(valid_613337, JString, required = false,
                                 default = nil)
  if valid_613337 != nil:
    section.add "X-Amz-SignedHeaders", valid_613337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613338: Call_GetConfirmSubscription_613323; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  let valid = call_613338.validator(path, query, header, formData, body)
  let scheme = call_613338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613338.url(scheme.get, call_613338.host, call_613338.base,
                         call_613338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613338, url, valid)

proc call*(call_613339: Call_GetConfirmSubscription_613323; Token: string;
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
  var query_613340 = newJObject()
  add(query_613340, "AuthenticateOnUnsubscribe",
      newJString(AuthenticateOnUnsubscribe))
  add(query_613340, "Token", newJString(Token))
  add(query_613340, "Action", newJString(Action))
  add(query_613340, "Version", newJString(Version))
  add(query_613340, "TopicArn", newJString(TopicArn))
  result = call_613339.call(nil, query_613340, nil, nil, nil)

var getConfirmSubscription* = Call_GetConfirmSubscription_613323(
    name: "getConfirmSubscription", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ConfirmSubscription",
    validator: validate_GetConfirmSubscription_613324, base: "/",
    url: url_GetConfirmSubscription_613325, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformApplication_613383 = ref object of OpenApiRestCall_612658
proc url_PostCreatePlatformApplication_613385(protocol: Scheme; host: string;
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

proc validate_PostCreatePlatformApplication_613384(path: JsonNode; query: JsonNode;
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
  var valid_613386 = query.getOrDefault("Action")
  valid_613386 = validateParameter(valid_613386, JString, required = true, default = newJString(
      "CreatePlatformApplication"))
  if valid_613386 != nil:
    section.add "Action", valid_613386
  var valid_613387 = query.getOrDefault("Version")
  valid_613387 = validateParameter(valid_613387, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613387 != nil:
    section.add "Version", valid_613387
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613388 = header.getOrDefault("X-Amz-Signature")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "X-Amz-Signature", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-Content-Sha256", valid_613389
  var valid_613390 = header.getOrDefault("X-Amz-Date")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Date", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-Credential")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Credential", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Security-Token")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Security-Token", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-Algorithm")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Algorithm", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-SignedHeaders", valid_613394
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
  var valid_613395 = formData.getOrDefault("Attributes.0.key")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "Attributes.0.key", valid_613395
  assert formData != nil,
        "formData argument is necessary due to required `Platform` field"
  var valid_613396 = formData.getOrDefault("Platform")
  valid_613396 = validateParameter(valid_613396, JString, required = true,
                                 default = nil)
  if valid_613396 != nil:
    section.add "Platform", valid_613396
  var valid_613397 = formData.getOrDefault("Attributes.2.value")
  valid_613397 = validateParameter(valid_613397, JString, required = false,
                                 default = nil)
  if valid_613397 != nil:
    section.add "Attributes.2.value", valid_613397
  var valid_613398 = formData.getOrDefault("Attributes.2.key")
  valid_613398 = validateParameter(valid_613398, JString, required = false,
                                 default = nil)
  if valid_613398 != nil:
    section.add "Attributes.2.key", valid_613398
  var valid_613399 = formData.getOrDefault("Attributes.0.value")
  valid_613399 = validateParameter(valid_613399, JString, required = false,
                                 default = nil)
  if valid_613399 != nil:
    section.add "Attributes.0.value", valid_613399
  var valid_613400 = formData.getOrDefault("Attributes.1.key")
  valid_613400 = validateParameter(valid_613400, JString, required = false,
                                 default = nil)
  if valid_613400 != nil:
    section.add "Attributes.1.key", valid_613400
  var valid_613401 = formData.getOrDefault("Name")
  valid_613401 = validateParameter(valid_613401, JString, required = true,
                                 default = nil)
  if valid_613401 != nil:
    section.add "Name", valid_613401
  var valid_613402 = formData.getOrDefault("Attributes.1.value")
  valid_613402 = validateParameter(valid_613402, JString, required = false,
                                 default = nil)
  if valid_613402 != nil:
    section.add "Attributes.1.value", valid_613402
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613403: Call_PostCreatePlatformApplication_613383; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For FCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For FCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action.</p>
  ## 
  let valid = call_613403.validator(path, query, header, formData, body)
  let scheme = call_613403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613403.url(scheme.get, call_613403.host, call_613403.base,
                         call_613403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613403, url, valid)

proc call*(call_613404: Call_PostCreatePlatformApplication_613383;
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
  var query_613405 = newJObject()
  var formData_613406 = newJObject()
  add(formData_613406, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_613406, "Platform", newJString(Platform))
  add(formData_613406, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_613406, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_613406, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_613406, "Attributes.1.key", newJString(Attributes1Key))
  add(query_613405, "Action", newJString(Action))
  add(formData_613406, "Name", newJString(Name))
  add(query_613405, "Version", newJString(Version))
  add(formData_613406, "Attributes.1.value", newJString(Attributes1Value))
  result = call_613404.call(nil, query_613405, nil, formData_613406, nil)

var postCreatePlatformApplication* = Call_PostCreatePlatformApplication_613383(
    name: "postCreatePlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformApplication",
    validator: validate_PostCreatePlatformApplication_613384, base: "/",
    url: url_PostCreatePlatformApplication_613385,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformApplication_613360 = ref object of OpenApiRestCall_612658
proc url_GetCreatePlatformApplication_613362(protocol: Scheme; host: string;
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

proc validate_GetCreatePlatformApplication_613361(path: JsonNode; query: JsonNode;
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
  var valid_613363 = query.getOrDefault("Attributes.1.key")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "Attributes.1.key", valid_613363
  var valid_613364 = query.getOrDefault("Attributes.0.value")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "Attributes.0.value", valid_613364
  var valid_613365 = query.getOrDefault("Attributes.0.key")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "Attributes.0.key", valid_613365
  assert query != nil,
        "query argument is necessary due to required `Platform` field"
  var valid_613366 = query.getOrDefault("Platform")
  valid_613366 = validateParameter(valid_613366, JString, required = true,
                                 default = nil)
  if valid_613366 != nil:
    section.add "Platform", valid_613366
  var valid_613367 = query.getOrDefault("Attributes.2.value")
  valid_613367 = validateParameter(valid_613367, JString, required = false,
                                 default = nil)
  if valid_613367 != nil:
    section.add "Attributes.2.value", valid_613367
  var valid_613368 = query.getOrDefault("Attributes.1.value")
  valid_613368 = validateParameter(valid_613368, JString, required = false,
                                 default = nil)
  if valid_613368 != nil:
    section.add "Attributes.1.value", valid_613368
  var valid_613369 = query.getOrDefault("Name")
  valid_613369 = validateParameter(valid_613369, JString, required = true,
                                 default = nil)
  if valid_613369 != nil:
    section.add "Name", valid_613369
  var valid_613370 = query.getOrDefault("Action")
  valid_613370 = validateParameter(valid_613370, JString, required = true, default = newJString(
      "CreatePlatformApplication"))
  if valid_613370 != nil:
    section.add "Action", valid_613370
  var valid_613371 = query.getOrDefault("Version")
  valid_613371 = validateParameter(valid_613371, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613371 != nil:
    section.add "Version", valid_613371
  var valid_613372 = query.getOrDefault("Attributes.2.key")
  valid_613372 = validateParameter(valid_613372, JString, required = false,
                                 default = nil)
  if valid_613372 != nil:
    section.add "Attributes.2.key", valid_613372
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613373 = header.getOrDefault("X-Amz-Signature")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "X-Amz-Signature", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Content-Sha256", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Date")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Date", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Credential")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Credential", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Security-Token")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Security-Token", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-Algorithm")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-Algorithm", valid_613378
  var valid_613379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-SignedHeaders", valid_613379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613380: Call_GetCreatePlatformApplication_613360; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For FCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For FCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action.</p>
  ## 
  let valid = call_613380.validator(path, query, header, formData, body)
  let scheme = call_613380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613380.url(scheme.get, call_613380.host, call_613380.base,
                         call_613380.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613380, url, valid)

proc call*(call_613381: Call_GetCreatePlatformApplication_613360; Platform: string;
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
  var query_613382 = newJObject()
  add(query_613382, "Attributes.1.key", newJString(Attributes1Key))
  add(query_613382, "Attributes.0.value", newJString(Attributes0Value))
  add(query_613382, "Attributes.0.key", newJString(Attributes0Key))
  add(query_613382, "Platform", newJString(Platform))
  add(query_613382, "Attributes.2.value", newJString(Attributes2Value))
  add(query_613382, "Attributes.1.value", newJString(Attributes1Value))
  add(query_613382, "Name", newJString(Name))
  add(query_613382, "Action", newJString(Action))
  add(query_613382, "Version", newJString(Version))
  add(query_613382, "Attributes.2.key", newJString(Attributes2Key))
  result = call_613381.call(nil, query_613382, nil, nil, nil)

var getCreatePlatformApplication* = Call_GetCreatePlatformApplication_613360(
    name: "getCreatePlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformApplication",
    validator: validate_GetCreatePlatformApplication_613361, base: "/",
    url: url_GetCreatePlatformApplication_613362,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformEndpoint_613431 = ref object of OpenApiRestCall_612658
proc url_PostCreatePlatformEndpoint_613433(protocol: Scheme; host: string;
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

proc validate_PostCreatePlatformEndpoint_613432(path: JsonNode; query: JsonNode;
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
  var valid_613434 = query.getOrDefault("Action")
  valid_613434 = validateParameter(valid_613434, JString, required = true,
                                 default = newJString("CreatePlatformEndpoint"))
  if valid_613434 != nil:
    section.add "Action", valid_613434
  var valid_613435 = query.getOrDefault("Version")
  valid_613435 = validateParameter(valid_613435, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613435 != nil:
    section.add "Version", valid_613435
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613436 = header.getOrDefault("X-Amz-Signature")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Signature", valid_613436
  var valid_613437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-Content-Sha256", valid_613437
  var valid_613438 = header.getOrDefault("X-Amz-Date")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "X-Amz-Date", valid_613438
  var valid_613439 = header.getOrDefault("X-Amz-Credential")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "X-Amz-Credential", valid_613439
  var valid_613440 = header.getOrDefault("X-Amz-Security-Token")
  valid_613440 = validateParameter(valid_613440, JString, required = false,
                                 default = nil)
  if valid_613440 != nil:
    section.add "X-Amz-Security-Token", valid_613440
  var valid_613441 = header.getOrDefault("X-Amz-Algorithm")
  valid_613441 = validateParameter(valid_613441, JString, required = false,
                                 default = nil)
  if valid_613441 != nil:
    section.add "X-Amz-Algorithm", valid_613441
  var valid_613442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613442 = validateParameter(valid_613442, JString, required = false,
                                 default = nil)
  if valid_613442 != nil:
    section.add "X-Amz-SignedHeaders", valid_613442
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
  var valid_613443 = formData.getOrDefault("PlatformApplicationArn")
  valid_613443 = validateParameter(valid_613443, JString, required = true,
                                 default = nil)
  if valid_613443 != nil:
    section.add "PlatformApplicationArn", valid_613443
  var valid_613444 = formData.getOrDefault("CustomUserData")
  valid_613444 = validateParameter(valid_613444, JString, required = false,
                                 default = nil)
  if valid_613444 != nil:
    section.add "CustomUserData", valid_613444
  var valid_613445 = formData.getOrDefault("Attributes.0.key")
  valid_613445 = validateParameter(valid_613445, JString, required = false,
                                 default = nil)
  if valid_613445 != nil:
    section.add "Attributes.0.key", valid_613445
  var valid_613446 = formData.getOrDefault("Attributes.2.value")
  valid_613446 = validateParameter(valid_613446, JString, required = false,
                                 default = nil)
  if valid_613446 != nil:
    section.add "Attributes.2.value", valid_613446
  var valid_613447 = formData.getOrDefault("Attributes.2.key")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "Attributes.2.key", valid_613447
  var valid_613448 = formData.getOrDefault("Attributes.0.value")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "Attributes.0.value", valid_613448
  var valid_613449 = formData.getOrDefault("Attributes.1.key")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "Attributes.1.key", valid_613449
  var valid_613450 = formData.getOrDefault("Token")
  valid_613450 = validateParameter(valid_613450, JString, required = true,
                                 default = nil)
  if valid_613450 != nil:
    section.add "Token", valid_613450
  var valid_613451 = formData.getOrDefault("Attributes.1.value")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "Attributes.1.value", valid_613451
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613452: Call_PostCreatePlatformEndpoint_613431; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as FCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  let valid = call_613452.validator(path, query, header, formData, body)
  let scheme = call_613452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613452.url(scheme.get, call_613452.host, call_613452.base,
                         call_613452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613452, url, valid)

proc call*(call_613453: Call_PostCreatePlatformEndpoint_613431;
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
  var query_613454 = newJObject()
  var formData_613455 = newJObject()
  add(formData_613455, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(formData_613455, "CustomUserData", newJString(CustomUserData))
  add(formData_613455, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_613455, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_613455, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_613455, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_613455, "Attributes.1.key", newJString(Attributes1Key))
  add(formData_613455, "Token", newJString(Token))
  add(query_613454, "Action", newJString(Action))
  add(query_613454, "Version", newJString(Version))
  add(formData_613455, "Attributes.1.value", newJString(Attributes1Value))
  result = call_613453.call(nil, query_613454, nil, formData_613455, nil)

var postCreatePlatformEndpoint* = Call_PostCreatePlatformEndpoint_613431(
    name: "postCreatePlatformEndpoint", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformEndpoint",
    validator: validate_PostCreatePlatformEndpoint_613432, base: "/",
    url: url_PostCreatePlatformEndpoint_613433,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformEndpoint_613407 = ref object of OpenApiRestCall_612658
proc url_GetCreatePlatformEndpoint_613409(protocol: Scheme; host: string;
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

proc validate_GetCreatePlatformEndpoint_613408(path: JsonNode; query: JsonNode;
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
  var valid_613410 = query.getOrDefault("Attributes.1.key")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "Attributes.1.key", valid_613410
  var valid_613411 = query.getOrDefault("CustomUserData")
  valid_613411 = validateParameter(valid_613411, JString, required = false,
                                 default = nil)
  if valid_613411 != nil:
    section.add "CustomUserData", valid_613411
  var valid_613412 = query.getOrDefault("Attributes.0.value")
  valid_613412 = validateParameter(valid_613412, JString, required = false,
                                 default = nil)
  if valid_613412 != nil:
    section.add "Attributes.0.value", valid_613412
  var valid_613413 = query.getOrDefault("Attributes.0.key")
  valid_613413 = validateParameter(valid_613413, JString, required = false,
                                 default = nil)
  if valid_613413 != nil:
    section.add "Attributes.0.key", valid_613413
  var valid_613414 = query.getOrDefault("Attributes.2.value")
  valid_613414 = validateParameter(valid_613414, JString, required = false,
                                 default = nil)
  if valid_613414 != nil:
    section.add "Attributes.2.value", valid_613414
  assert query != nil, "query argument is necessary due to required `Token` field"
  var valid_613415 = query.getOrDefault("Token")
  valid_613415 = validateParameter(valid_613415, JString, required = true,
                                 default = nil)
  if valid_613415 != nil:
    section.add "Token", valid_613415
  var valid_613416 = query.getOrDefault("Attributes.1.value")
  valid_613416 = validateParameter(valid_613416, JString, required = false,
                                 default = nil)
  if valid_613416 != nil:
    section.add "Attributes.1.value", valid_613416
  var valid_613417 = query.getOrDefault("PlatformApplicationArn")
  valid_613417 = validateParameter(valid_613417, JString, required = true,
                                 default = nil)
  if valid_613417 != nil:
    section.add "PlatformApplicationArn", valid_613417
  var valid_613418 = query.getOrDefault("Action")
  valid_613418 = validateParameter(valid_613418, JString, required = true,
                                 default = newJString("CreatePlatformEndpoint"))
  if valid_613418 != nil:
    section.add "Action", valid_613418
  var valid_613419 = query.getOrDefault("Version")
  valid_613419 = validateParameter(valid_613419, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613419 != nil:
    section.add "Version", valid_613419
  var valid_613420 = query.getOrDefault("Attributes.2.key")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "Attributes.2.key", valid_613420
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613421 = header.getOrDefault("X-Amz-Signature")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-Signature", valid_613421
  var valid_613422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-Content-Sha256", valid_613422
  var valid_613423 = header.getOrDefault("X-Amz-Date")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-Date", valid_613423
  var valid_613424 = header.getOrDefault("X-Amz-Credential")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-Credential", valid_613424
  var valid_613425 = header.getOrDefault("X-Amz-Security-Token")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "X-Amz-Security-Token", valid_613425
  var valid_613426 = header.getOrDefault("X-Amz-Algorithm")
  valid_613426 = validateParameter(valid_613426, JString, required = false,
                                 default = nil)
  if valid_613426 != nil:
    section.add "X-Amz-Algorithm", valid_613426
  var valid_613427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613427 = validateParameter(valid_613427, JString, required = false,
                                 default = nil)
  if valid_613427 != nil:
    section.add "X-Amz-SignedHeaders", valid_613427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613428: Call_GetCreatePlatformEndpoint_613407; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as FCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  let valid = call_613428.validator(path, query, header, formData, body)
  let scheme = call_613428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613428.url(scheme.get, call_613428.host, call_613428.base,
                         call_613428.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613428, url, valid)

proc call*(call_613429: Call_GetCreatePlatformEndpoint_613407; Token: string;
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
  var query_613430 = newJObject()
  add(query_613430, "Attributes.1.key", newJString(Attributes1Key))
  add(query_613430, "CustomUserData", newJString(CustomUserData))
  add(query_613430, "Attributes.0.value", newJString(Attributes0Value))
  add(query_613430, "Attributes.0.key", newJString(Attributes0Key))
  add(query_613430, "Attributes.2.value", newJString(Attributes2Value))
  add(query_613430, "Token", newJString(Token))
  add(query_613430, "Attributes.1.value", newJString(Attributes1Value))
  add(query_613430, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  add(query_613430, "Action", newJString(Action))
  add(query_613430, "Version", newJString(Version))
  add(query_613430, "Attributes.2.key", newJString(Attributes2Key))
  result = call_613429.call(nil, query_613430, nil, nil, nil)

var getCreatePlatformEndpoint* = Call_GetCreatePlatformEndpoint_613407(
    name: "getCreatePlatformEndpoint", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformEndpoint",
    validator: validate_GetCreatePlatformEndpoint_613408, base: "/",
    url: url_GetCreatePlatformEndpoint_613409,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateTopic_613479 = ref object of OpenApiRestCall_612658
proc url_PostCreateTopic_613481(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateTopic_613480(path: JsonNode; query: JsonNode;
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
  var valid_613482 = query.getOrDefault("Action")
  valid_613482 = validateParameter(valid_613482, JString, required = true,
                                 default = newJString("CreateTopic"))
  if valid_613482 != nil:
    section.add "Action", valid_613482
  var valid_613483 = query.getOrDefault("Version")
  valid_613483 = validateParameter(valid_613483, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613483 != nil:
    section.add "Version", valid_613483
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613484 = header.getOrDefault("X-Amz-Signature")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-Signature", valid_613484
  var valid_613485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-Content-Sha256", valid_613485
  var valid_613486 = header.getOrDefault("X-Amz-Date")
  valid_613486 = validateParameter(valid_613486, JString, required = false,
                                 default = nil)
  if valid_613486 != nil:
    section.add "X-Amz-Date", valid_613486
  var valid_613487 = header.getOrDefault("X-Amz-Credential")
  valid_613487 = validateParameter(valid_613487, JString, required = false,
                                 default = nil)
  if valid_613487 != nil:
    section.add "X-Amz-Credential", valid_613487
  var valid_613488 = header.getOrDefault("X-Amz-Security-Token")
  valid_613488 = validateParameter(valid_613488, JString, required = false,
                                 default = nil)
  if valid_613488 != nil:
    section.add "X-Amz-Security-Token", valid_613488
  var valid_613489 = header.getOrDefault("X-Amz-Algorithm")
  valid_613489 = validateParameter(valid_613489, JString, required = false,
                                 default = nil)
  if valid_613489 != nil:
    section.add "X-Amz-Algorithm", valid_613489
  var valid_613490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613490 = validateParameter(valid_613490, JString, required = false,
                                 default = nil)
  if valid_613490 != nil:
    section.add "X-Amz-SignedHeaders", valid_613490
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
  var valid_613491 = formData.getOrDefault("Attributes.0.key")
  valid_613491 = validateParameter(valid_613491, JString, required = false,
                                 default = nil)
  if valid_613491 != nil:
    section.add "Attributes.0.key", valid_613491
  var valid_613492 = formData.getOrDefault("Attributes.2.value")
  valid_613492 = validateParameter(valid_613492, JString, required = false,
                                 default = nil)
  if valid_613492 != nil:
    section.add "Attributes.2.value", valid_613492
  var valid_613493 = formData.getOrDefault("Attributes.2.key")
  valid_613493 = validateParameter(valid_613493, JString, required = false,
                                 default = nil)
  if valid_613493 != nil:
    section.add "Attributes.2.key", valid_613493
  var valid_613494 = formData.getOrDefault("Attributes.0.value")
  valid_613494 = validateParameter(valid_613494, JString, required = false,
                                 default = nil)
  if valid_613494 != nil:
    section.add "Attributes.0.value", valid_613494
  var valid_613495 = formData.getOrDefault("Attributes.1.key")
  valid_613495 = validateParameter(valid_613495, JString, required = false,
                                 default = nil)
  if valid_613495 != nil:
    section.add "Attributes.1.key", valid_613495
  assert formData != nil,
        "formData argument is necessary due to required `Name` field"
  var valid_613496 = formData.getOrDefault("Name")
  valid_613496 = validateParameter(valid_613496, JString, required = true,
                                 default = nil)
  if valid_613496 != nil:
    section.add "Name", valid_613496
  var valid_613497 = formData.getOrDefault("Tags")
  valid_613497 = validateParameter(valid_613497, JArray, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "Tags", valid_613497
  var valid_613498 = formData.getOrDefault("Attributes.1.value")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "Attributes.1.value", valid_613498
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613499: Call_PostCreateTopic_613479; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  let valid = call_613499.validator(path, query, header, formData, body)
  let scheme = call_613499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613499.url(scheme.get, call_613499.host, call_613499.base,
                         call_613499.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613499, url, valid)

proc call*(call_613500: Call_PostCreateTopic_613479; Name: string;
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
  var query_613501 = newJObject()
  var formData_613502 = newJObject()
  add(formData_613502, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_613502, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_613502, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_613502, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_613502, "Attributes.1.key", newJString(Attributes1Key))
  add(query_613501, "Action", newJString(Action))
  add(formData_613502, "Name", newJString(Name))
  if Tags != nil:
    formData_613502.add "Tags", Tags
  add(query_613501, "Version", newJString(Version))
  add(formData_613502, "Attributes.1.value", newJString(Attributes1Value))
  result = call_613500.call(nil, query_613501, nil, formData_613502, nil)

var postCreateTopic* = Call_PostCreateTopic_613479(name: "postCreateTopic",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=CreateTopic", validator: validate_PostCreateTopic_613480,
    base: "/", url: url_PostCreateTopic_613481, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateTopic_613456 = ref object of OpenApiRestCall_612658
proc url_GetCreateTopic_613458(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateTopic_613457(path: JsonNode; query: JsonNode;
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
  var valid_613459 = query.getOrDefault("Attributes.1.key")
  valid_613459 = validateParameter(valid_613459, JString, required = false,
                                 default = nil)
  if valid_613459 != nil:
    section.add "Attributes.1.key", valid_613459
  var valid_613460 = query.getOrDefault("Attributes.0.value")
  valid_613460 = validateParameter(valid_613460, JString, required = false,
                                 default = nil)
  if valid_613460 != nil:
    section.add "Attributes.0.value", valid_613460
  var valid_613461 = query.getOrDefault("Attributes.0.key")
  valid_613461 = validateParameter(valid_613461, JString, required = false,
                                 default = nil)
  if valid_613461 != nil:
    section.add "Attributes.0.key", valid_613461
  var valid_613462 = query.getOrDefault("Tags")
  valid_613462 = validateParameter(valid_613462, JArray, required = false,
                                 default = nil)
  if valid_613462 != nil:
    section.add "Tags", valid_613462
  var valid_613463 = query.getOrDefault("Attributes.2.value")
  valid_613463 = validateParameter(valid_613463, JString, required = false,
                                 default = nil)
  if valid_613463 != nil:
    section.add "Attributes.2.value", valid_613463
  var valid_613464 = query.getOrDefault("Attributes.1.value")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "Attributes.1.value", valid_613464
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_613465 = query.getOrDefault("Name")
  valid_613465 = validateParameter(valid_613465, JString, required = true,
                                 default = nil)
  if valid_613465 != nil:
    section.add "Name", valid_613465
  var valid_613466 = query.getOrDefault("Action")
  valid_613466 = validateParameter(valid_613466, JString, required = true,
                                 default = newJString("CreateTopic"))
  if valid_613466 != nil:
    section.add "Action", valid_613466
  var valid_613467 = query.getOrDefault("Version")
  valid_613467 = validateParameter(valid_613467, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613467 != nil:
    section.add "Version", valid_613467
  var valid_613468 = query.getOrDefault("Attributes.2.key")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "Attributes.2.key", valid_613468
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613469 = header.getOrDefault("X-Amz-Signature")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-Signature", valid_613469
  var valid_613470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613470 = validateParameter(valid_613470, JString, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "X-Amz-Content-Sha256", valid_613470
  var valid_613471 = header.getOrDefault("X-Amz-Date")
  valid_613471 = validateParameter(valid_613471, JString, required = false,
                                 default = nil)
  if valid_613471 != nil:
    section.add "X-Amz-Date", valid_613471
  var valid_613472 = header.getOrDefault("X-Amz-Credential")
  valid_613472 = validateParameter(valid_613472, JString, required = false,
                                 default = nil)
  if valid_613472 != nil:
    section.add "X-Amz-Credential", valid_613472
  var valid_613473 = header.getOrDefault("X-Amz-Security-Token")
  valid_613473 = validateParameter(valid_613473, JString, required = false,
                                 default = nil)
  if valid_613473 != nil:
    section.add "X-Amz-Security-Token", valid_613473
  var valid_613474 = header.getOrDefault("X-Amz-Algorithm")
  valid_613474 = validateParameter(valid_613474, JString, required = false,
                                 default = nil)
  if valid_613474 != nil:
    section.add "X-Amz-Algorithm", valid_613474
  var valid_613475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613475 = validateParameter(valid_613475, JString, required = false,
                                 default = nil)
  if valid_613475 != nil:
    section.add "X-Amz-SignedHeaders", valid_613475
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613476: Call_GetCreateTopic_613456; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  let valid = call_613476.validator(path, query, header, formData, body)
  let scheme = call_613476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613476.url(scheme.get, call_613476.host, call_613476.base,
                         call_613476.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613476, url, valid)

proc call*(call_613477: Call_GetCreateTopic_613456; Name: string;
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
  var query_613478 = newJObject()
  add(query_613478, "Attributes.1.key", newJString(Attributes1Key))
  add(query_613478, "Attributes.0.value", newJString(Attributes0Value))
  add(query_613478, "Attributes.0.key", newJString(Attributes0Key))
  if Tags != nil:
    query_613478.add "Tags", Tags
  add(query_613478, "Attributes.2.value", newJString(Attributes2Value))
  add(query_613478, "Attributes.1.value", newJString(Attributes1Value))
  add(query_613478, "Name", newJString(Name))
  add(query_613478, "Action", newJString(Action))
  add(query_613478, "Version", newJString(Version))
  add(query_613478, "Attributes.2.key", newJString(Attributes2Key))
  result = call_613477.call(nil, query_613478, nil, nil, nil)

var getCreateTopic* = Call_GetCreateTopic_613456(name: "getCreateTopic",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=CreateTopic", validator: validate_GetCreateTopic_613457,
    base: "/", url: url_GetCreateTopic_613458, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEndpoint_613519 = ref object of OpenApiRestCall_612658
proc url_PostDeleteEndpoint_613521(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteEndpoint_613520(path: JsonNode; query: JsonNode;
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
  var valid_613522 = query.getOrDefault("Action")
  valid_613522 = validateParameter(valid_613522, JString, required = true,
                                 default = newJString("DeleteEndpoint"))
  if valid_613522 != nil:
    section.add "Action", valid_613522
  var valid_613523 = query.getOrDefault("Version")
  valid_613523 = validateParameter(valid_613523, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613523 != nil:
    section.add "Version", valid_613523
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613524 = header.getOrDefault("X-Amz-Signature")
  valid_613524 = validateParameter(valid_613524, JString, required = false,
                                 default = nil)
  if valid_613524 != nil:
    section.add "X-Amz-Signature", valid_613524
  var valid_613525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613525 = validateParameter(valid_613525, JString, required = false,
                                 default = nil)
  if valid_613525 != nil:
    section.add "X-Amz-Content-Sha256", valid_613525
  var valid_613526 = header.getOrDefault("X-Amz-Date")
  valid_613526 = validateParameter(valid_613526, JString, required = false,
                                 default = nil)
  if valid_613526 != nil:
    section.add "X-Amz-Date", valid_613526
  var valid_613527 = header.getOrDefault("X-Amz-Credential")
  valid_613527 = validateParameter(valid_613527, JString, required = false,
                                 default = nil)
  if valid_613527 != nil:
    section.add "X-Amz-Credential", valid_613527
  var valid_613528 = header.getOrDefault("X-Amz-Security-Token")
  valid_613528 = validateParameter(valid_613528, JString, required = false,
                                 default = nil)
  if valid_613528 != nil:
    section.add "X-Amz-Security-Token", valid_613528
  var valid_613529 = header.getOrDefault("X-Amz-Algorithm")
  valid_613529 = validateParameter(valid_613529, JString, required = false,
                                 default = nil)
  if valid_613529 != nil:
    section.add "X-Amz-Algorithm", valid_613529
  var valid_613530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "X-Amz-SignedHeaders", valid_613530
  result.add "header", section
  ## parameters in `formData` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn of endpoint to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_613531 = formData.getOrDefault("EndpointArn")
  valid_613531 = validateParameter(valid_613531, JString, required = true,
                                 default = nil)
  if valid_613531 != nil:
    section.add "EndpointArn", valid_613531
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613532: Call_PostDeleteEndpoint_613519; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ## 
  let valid = call_613532.validator(path, query, header, formData, body)
  let scheme = call_613532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613532.url(scheme.get, call_613532.host, call_613532.base,
                         call_613532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613532, url, valid)

proc call*(call_613533: Call_PostDeleteEndpoint_613519; EndpointArn: string;
          Action: string = "DeleteEndpoint"; Version: string = "2010-03-31"): Recallable =
  ## postDeleteEndpoint
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ##   EndpointArn: string (required)
  ##              : EndpointArn of endpoint to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613534 = newJObject()
  var formData_613535 = newJObject()
  add(formData_613535, "EndpointArn", newJString(EndpointArn))
  add(query_613534, "Action", newJString(Action))
  add(query_613534, "Version", newJString(Version))
  result = call_613533.call(nil, query_613534, nil, formData_613535, nil)

var postDeleteEndpoint* = Call_PostDeleteEndpoint_613519(
    name: "postDeleteEndpoint", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=DeleteEndpoint",
    validator: validate_PostDeleteEndpoint_613520, base: "/",
    url: url_PostDeleteEndpoint_613521, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEndpoint_613503 = ref object of OpenApiRestCall_612658
proc url_GetDeleteEndpoint_613505(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteEndpoint_613504(path: JsonNode; query: JsonNode;
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
  var valid_613506 = query.getOrDefault("Action")
  valid_613506 = validateParameter(valid_613506, JString, required = true,
                                 default = newJString("DeleteEndpoint"))
  if valid_613506 != nil:
    section.add "Action", valid_613506
  var valid_613507 = query.getOrDefault("EndpointArn")
  valid_613507 = validateParameter(valid_613507, JString, required = true,
                                 default = nil)
  if valid_613507 != nil:
    section.add "EndpointArn", valid_613507
  var valid_613508 = query.getOrDefault("Version")
  valid_613508 = validateParameter(valid_613508, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613508 != nil:
    section.add "Version", valid_613508
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613509 = header.getOrDefault("X-Amz-Signature")
  valid_613509 = validateParameter(valid_613509, JString, required = false,
                                 default = nil)
  if valid_613509 != nil:
    section.add "X-Amz-Signature", valid_613509
  var valid_613510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613510 = validateParameter(valid_613510, JString, required = false,
                                 default = nil)
  if valid_613510 != nil:
    section.add "X-Amz-Content-Sha256", valid_613510
  var valid_613511 = header.getOrDefault("X-Amz-Date")
  valid_613511 = validateParameter(valid_613511, JString, required = false,
                                 default = nil)
  if valid_613511 != nil:
    section.add "X-Amz-Date", valid_613511
  var valid_613512 = header.getOrDefault("X-Amz-Credential")
  valid_613512 = validateParameter(valid_613512, JString, required = false,
                                 default = nil)
  if valid_613512 != nil:
    section.add "X-Amz-Credential", valid_613512
  var valid_613513 = header.getOrDefault("X-Amz-Security-Token")
  valid_613513 = validateParameter(valid_613513, JString, required = false,
                                 default = nil)
  if valid_613513 != nil:
    section.add "X-Amz-Security-Token", valid_613513
  var valid_613514 = header.getOrDefault("X-Amz-Algorithm")
  valid_613514 = validateParameter(valid_613514, JString, required = false,
                                 default = nil)
  if valid_613514 != nil:
    section.add "X-Amz-Algorithm", valid_613514
  var valid_613515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "X-Amz-SignedHeaders", valid_613515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613516: Call_GetDeleteEndpoint_613503; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ## 
  let valid = call_613516.validator(path, query, header, formData, body)
  let scheme = call_613516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613516.url(scheme.get, call_613516.host, call_613516.base,
                         call_613516.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613516, url, valid)

proc call*(call_613517: Call_GetDeleteEndpoint_613503; EndpointArn: string;
          Action: string = "DeleteEndpoint"; Version: string = "2010-03-31"): Recallable =
  ## getDeleteEndpoint
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ##   Action: string (required)
  ##   EndpointArn: string (required)
  ##              : EndpointArn of endpoint to delete.
  ##   Version: string (required)
  var query_613518 = newJObject()
  add(query_613518, "Action", newJString(Action))
  add(query_613518, "EndpointArn", newJString(EndpointArn))
  add(query_613518, "Version", newJString(Version))
  result = call_613517.call(nil, query_613518, nil, nil, nil)

var getDeleteEndpoint* = Call_GetDeleteEndpoint_613503(name: "getDeleteEndpoint",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=DeleteEndpoint", validator: validate_GetDeleteEndpoint_613504,
    base: "/", url: url_GetDeleteEndpoint_613505,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeletePlatformApplication_613552 = ref object of OpenApiRestCall_612658
proc url_PostDeletePlatformApplication_613554(protocol: Scheme; host: string;
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

proc validate_PostDeletePlatformApplication_613553(path: JsonNode; query: JsonNode;
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
  var valid_613555 = query.getOrDefault("Action")
  valid_613555 = validateParameter(valid_613555, JString, required = true, default = newJString(
      "DeletePlatformApplication"))
  if valid_613555 != nil:
    section.add "Action", valid_613555
  var valid_613556 = query.getOrDefault("Version")
  valid_613556 = validateParameter(valid_613556, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613556 != nil:
    section.add "Version", valid_613556
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613557 = header.getOrDefault("X-Amz-Signature")
  valid_613557 = validateParameter(valid_613557, JString, required = false,
                                 default = nil)
  if valid_613557 != nil:
    section.add "X-Amz-Signature", valid_613557
  var valid_613558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "X-Amz-Content-Sha256", valid_613558
  var valid_613559 = header.getOrDefault("X-Amz-Date")
  valid_613559 = validateParameter(valid_613559, JString, required = false,
                                 default = nil)
  if valid_613559 != nil:
    section.add "X-Amz-Date", valid_613559
  var valid_613560 = header.getOrDefault("X-Amz-Credential")
  valid_613560 = validateParameter(valid_613560, JString, required = false,
                                 default = nil)
  if valid_613560 != nil:
    section.add "X-Amz-Credential", valid_613560
  var valid_613561 = header.getOrDefault("X-Amz-Security-Token")
  valid_613561 = validateParameter(valid_613561, JString, required = false,
                                 default = nil)
  if valid_613561 != nil:
    section.add "X-Amz-Security-Token", valid_613561
  var valid_613562 = header.getOrDefault("X-Amz-Algorithm")
  valid_613562 = validateParameter(valid_613562, JString, required = false,
                                 default = nil)
  if valid_613562 != nil:
    section.add "X-Amz-Algorithm", valid_613562
  var valid_613563 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613563 = validateParameter(valid_613563, JString, required = false,
                                 default = nil)
  if valid_613563 != nil:
    section.add "X-Amz-SignedHeaders", valid_613563
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_613564 = formData.getOrDefault("PlatformApplicationArn")
  valid_613564 = validateParameter(valid_613564, JString, required = true,
                                 default = nil)
  if valid_613564 != nil:
    section.add "PlatformApplicationArn", valid_613564
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613565: Call_PostDeletePlatformApplication_613552; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_613565.validator(path, query, header, formData, body)
  let scheme = call_613565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613565.url(scheme.get, call_613565.host, call_613565.base,
                         call_613565.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613565, url, valid)

proc call*(call_613566: Call_PostDeletePlatformApplication_613552;
          PlatformApplicationArn: string;
          Action: string = "DeletePlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## postDeletePlatformApplication
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613567 = newJObject()
  var formData_613568 = newJObject()
  add(formData_613568, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(query_613567, "Action", newJString(Action))
  add(query_613567, "Version", newJString(Version))
  result = call_613566.call(nil, query_613567, nil, formData_613568, nil)

var postDeletePlatformApplication* = Call_PostDeletePlatformApplication_613552(
    name: "postDeletePlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=DeletePlatformApplication",
    validator: validate_PostDeletePlatformApplication_613553, base: "/",
    url: url_PostDeletePlatformApplication_613554,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeletePlatformApplication_613536 = ref object of OpenApiRestCall_612658
proc url_GetDeletePlatformApplication_613538(protocol: Scheme; host: string;
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

proc validate_GetDeletePlatformApplication_613537(path: JsonNode; query: JsonNode;
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
  var valid_613539 = query.getOrDefault("PlatformApplicationArn")
  valid_613539 = validateParameter(valid_613539, JString, required = true,
                                 default = nil)
  if valid_613539 != nil:
    section.add "PlatformApplicationArn", valid_613539
  var valid_613540 = query.getOrDefault("Action")
  valid_613540 = validateParameter(valid_613540, JString, required = true, default = newJString(
      "DeletePlatformApplication"))
  if valid_613540 != nil:
    section.add "Action", valid_613540
  var valid_613541 = query.getOrDefault("Version")
  valid_613541 = validateParameter(valid_613541, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613541 != nil:
    section.add "Version", valid_613541
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613542 = header.getOrDefault("X-Amz-Signature")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "X-Amz-Signature", valid_613542
  var valid_613543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "X-Amz-Content-Sha256", valid_613543
  var valid_613544 = header.getOrDefault("X-Amz-Date")
  valid_613544 = validateParameter(valid_613544, JString, required = false,
                                 default = nil)
  if valid_613544 != nil:
    section.add "X-Amz-Date", valid_613544
  var valid_613545 = header.getOrDefault("X-Amz-Credential")
  valid_613545 = validateParameter(valid_613545, JString, required = false,
                                 default = nil)
  if valid_613545 != nil:
    section.add "X-Amz-Credential", valid_613545
  var valid_613546 = header.getOrDefault("X-Amz-Security-Token")
  valid_613546 = validateParameter(valid_613546, JString, required = false,
                                 default = nil)
  if valid_613546 != nil:
    section.add "X-Amz-Security-Token", valid_613546
  var valid_613547 = header.getOrDefault("X-Amz-Algorithm")
  valid_613547 = validateParameter(valid_613547, JString, required = false,
                                 default = nil)
  if valid_613547 != nil:
    section.add "X-Amz-Algorithm", valid_613547
  var valid_613548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613548 = validateParameter(valid_613548, JString, required = false,
                                 default = nil)
  if valid_613548 != nil:
    section.add "X-Amz-SignedHeaders", valid_613548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613549: Call_GetDeletePlatformApplication_613536; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_613549.validator(path, query, header, formData, body)
  let scheme = call_613549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613549.url(scheme.get, call_613549.host, call_613549.base,
                         call_613549.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613549, url, valid)

proc call*(call_613550: Call_GetDeletePlatformApplication_613536;
          PlatformApplicationArn: string;
          Action: string = "DeletePlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## getDeletePlatformApplication
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613551 = newJObject()
  add(query_613551, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  add(query_613551, "Action", newJString(Action))
  add(query_613551, "Version", newJString(Version))
  result = call_613550.call(nil, query_613551, nil, nil, nil)

var getDeletePlatformApplication* = Call_GetDeletePlatformApplication_613536(
    name: "getDeletePlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=DeletePlatformApplication",
    validator: validate_GetDeletePlatformApplication_613537, base: "/",
    url: url_GetDeletePlatformApplication_613538,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteTopic_613585 = ref object of OpenApiRestCall_612658
proc url_PostDeleteTopic_613587(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteTopic_613586(path: JsonNode; query: JsonNode;
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
  var valid_613588 = query.getOrDefault("Action")
  valid_613588 = validateParameter(valid_613588, JString, required = true,
                                 default = newJString("DeleteTopic"))
  if valid_613588 != nil:
    section.add "Action", valid_613588
  var valid_613589 = query.getOrDefault("Version")
  valid_613589 = validateParameter(valid_613589, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613589 != nil:
    section.add "Version", valid_613589
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613590 = header.getOrDefault("X-Amz-Signature")
  valid_613590 = validateParameter(valid_613590, JString, required = false,
                                 default = nil)
  if valid_613590 != nil:
    section.add "X-Amz-Signature", valid_613590
  var valid_613591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613591 = validateParameter(valid_613591, JString, required = false,
                                 default = nil)
  if valid_613591 != nil:
    section.add "X-Amz-Content-Sha256", valid_613591
  var valid_613592 = header.getOrDefault("X-Amz-Date")
  valid_613592 = validateParameter(valid_613592, JString, required = false,
                                 default = nil)
  if valid_613592 != nil:
    section.add "X-Amz-Date", valid_613592
  var valid_613593 = header.getOrDefault("X-Amz-Credential")
  valid_613593 = validateParameter(valid_613593, JString, required = false,
                                 default = nil)
  if valid_613593 != nil:
    section.add "X-Amz-Credential", valid_613593
  var valid_613594 = header.getOrDefault("X-Amz-Security-Token")
  valid_613594 = validateParameter(valid_613594, JString, required = false,
                                 default = nil)
  if valid_613594 != nil:
    section.add "X-Amz-Security-Token", valid_613594
  var valid_613595 = header.getOrDefault("X-Amz-Algorithm")
  valid_613595 = validateParameter(valid_613595, JString, required = false,
                                 default = nil)
  if valid_613595 != nil:
    section.add "X-Amz-Algorithm", valid_613595
  var valid_613596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613596 = validateParameter(valid_613596, JString, required = false,
                                 default = nil)
  if valid_613596 != nil:
    section.add "X-Amz-SignedHeaders", valid_613596
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic you want to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_613597 = formData.getOrDefault("TopicArn")
  valid_613597 = validateParameter(valid_613597, JString, required = true,
                                 default = nil)
  if valid_613597 != nil:
    section.add "TopicArn", valid_613597
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613598: Call_PostDeleteTopic_613585; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ## 
  let valid = call_613598.validator(path, query, header, formData, body)
  let scheme = call_613598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613598.url(scheme.get, call_613598.host, call_613598.base,
                         call_613598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613598, url, valid)

proc call*(call_613599: Call_PostDeleteTopic_613585; TopicArn: string;
          Action: string = "DeleteTopic"; Version: string = "2010-03-31"): Recallable =
  ## postDeleteTopic
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613600 = newJObject()
  var formData_613601 = newJObject()
  add(formData_613601, "TopicArn", newJString(TopicArn))
  add(query_613600, "Action", newJString(Action))
  add(query_613600, "Version", newJString(Version))
  result = call_613599.call(nil, query_613600, nil, formData_613601, nil)

var postDeleteTopic* = Call_PostDeleteTopic_613585(name: "postDeleteTopic",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=DeleteTopic", validator: validate_PostDeleteTopic_613586,
    base: "/", url: url_PostDeleteTopic_613587, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteTopic_613569 = ref object of OpenApiRestCall_612658
proc url_GetDeleteTopic_613571(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteTopic_613570(path: JsonNode; query: JsonNode;
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
  var valid_613572 = query.getOrDefault("Action")
  valid_613572 = validateParameter(valid_613572, JString, required = true,
                                 default = newJString("DeleteTopic"))
  if valid_613572 != nil:
    section.add "Action", valid_613572
  var valid_613573 = query.getOrDefault("Version")
  valid_613573 = validateParameter(valid_613573, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613573 != nil:
    section.add "Version", valid_613573
  var valid_613574 = query.getOrDefault("TopicArn")
  valid_613574 = validateParameter(valid_613574, JString, required = true,
                                 default = nil)
  if valid_613574 != nil:
    section.add "TopicArn", valid_613574
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613575 = header.getOrDefault("X-Amz-Signature")
  valid_613575 = validateParameter(valid_613575, JString, required = false,
                                 default = nil)
  if valid_613575 != nil:
    section.add "X-Amz-Signature", valid_613575
  var valid_613576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613576 = validateParameter(valid_613576, JString, required = false,
                                 default = nil)
  if valid_613576 != nil:
    section.add "X-Amz-Content-Sha256", valid_613576
  var valid_613577 = header.getOrDefault("X-Amz-Date")
  valid_613577 = validateParameter(valid_613577, JString, required = false,
                                 default = nil)
  if valid_613577 != nil:
    section.add "X-Amz-Date", valid_613577
  var valid_613578 = header.getOrDefault("X-Amz-Credential")
  valid_613578 = validateParameter(valid_613578, JString, required = false,
                                 default = nil)
  if valid_613578 != nil:
    section.add "X-Amz-Credential", valid_613578
  var valid_613579 = header.getOrDefault("X-Amz-Security-Token")
  valid_613579 = validateParameter(valid_613579, JString, required = false,
                                 default = nil)
  if valid_613579 != nil:
    section.add "X-Amz-Security-Token", valid_613579
  var valid_613580 = header.getOrDefault("X-Amz-Algorithm")
  valid_613580 = validateParameter(valid_613580, JString, required = false,
                                 default = nil)
  if valid_613580 != nil:
    section.add "X-Amz-Algorithm", valid_613580
  var valid_613581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613581 = validateParameter(valid_613581, JString, required = false,
                                 default = nil)
  if valid_613581 != nil:
    section.add "X-Amz-SignedHeaders", valid_613581
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613582: Call_GetDeleteTopic_613569; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ## 
  let valid = call_613582.validator(path, query, header, formData, body)
  let scheme = call_613582.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613582.url(scheme.get, call_613582.host, call_613582.base,
                         call_613582.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613582, url, valid)

proc call*(call_613583: Call_GetDeleteTopic_613569; TopicArn: string;
          Action: string = "DeleteTopic"; Version: string = "2010-03-31"): Recallable =
  ## getDeleteTopic
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to delete.
  var query_613584 = newJObject()
  add(query_613584, "Action", newJString(Action))
  add(query_613584, "Version", newJString(Version))
  add(query_613584, "TopicArn", newJString(TopicArn))
  result = call_613583.call(nil, query_613584, nil, nil, nil)

var getDeleteTopic* = Call_GetDeleteTopic_613569(name: "getDeleteTopic",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=DeleteTopic", validator: validate_GetDeleteTopic_613570,
    base: "/", url: url_GetDeleteTopic_613571, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetEndpointAttributes_613618 = ref object of OpenApiRestCall_612658
proc url_PostGetEndpointAttributes_613620(protocol: Scheme; host: string;
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

proc validate_PostGetEndpointAttributes_613619(path: JsonNode; query: JsonNode;
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
  var valid_613621 = query.getOrDefault("Action")
  valid_613621 = validateParameter(valid_613621, JString, required = true,
                                 default = newJString("GetEndpointAttributes"))
  if valid_613621 != nil:
    section.add "Action", valid_613621
  var valid_613622 = query.getOrDefault("Version")
  valid_613622 = validateParameter(valid_613622, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613622 != nil:
    section.add "Version", valid_613622
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613623 = header.getOrDefault("X-Amz-Signature")
  valid_613623 = validateParameter(valid_613623, JString, required = false,
                                 default = nil)
  if valid_613623 != nil:
    section.add "X-Amz-Signature", valid_613623
  var valid_613624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613624 = validateParameter(valid_613624, JString, required = false,
                                 default = nil)
  if valid_613624 != nil:
    section.add "X-Amz-Content-Sha256", valid_613624
  var valid_613625 = header.getOrDefault("X-Amz-Date")
  valid_613625 = validateParameter(valid_613625, JString, required = false,
                                 default = nil)
  if valid_613625 != nil:
    section.add "X-Amz-Date", valid_613625
  var valid_613626 = header.getOrDefault("X-Amz-Credential")
  valid_613626 = validateParameter(valid_613626, JString, required = false,
                                 default = nil)
  if valid_613626 != nil:
    section.add "X-Amz-Credential", valid_613626
  var valid_613627 = header.getOrDefault("X-Amz-Security-Token")
  valid_613627 = validateParameter(valid_613627, JString, required = false,
                                 default = nil)
  if valid_613627 != nil:
    section.add "X-Amz-Security-Token", valid_613627
  var valid_613628 = header.getOrDefault("X-Amz-Algorithm")
  valid_613628 = validateParameter(valid_613628, JString, required = false,
                                 default = nil)
  if valid_613628 != nil:
    section.add "X-Amz-Algorithm", valid_613628
  var valid_613629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613629 = validateParameter(valid_613629, JString, required = false,
                                 default = nil)
  if valid_613629 != nil:
    section.add "X-Amz-SignedHeaders", valid_613629
  result.add "header", section
  ## parameters in `formData` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_613630 = formData.getOrDefault("EndpointArn")
  valid_613630 = validateParameter(valid_613630, JString, required = true,
                                 default = nil)
  if valid_613630 != nil:
    section.add "EndpointArn", valid_613630
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613631: Call_PostGetEndpointAttributes_613618; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_613631.validator(path, query, header, formData, body)
  let scheme = call_613631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613631.url(scheme.get, call_613631.host, call_613631.base,
                         call_613631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613631, url, valid)

proc call*(call_613632: Call_PostGetEndpointAttributes_613618; EndpointArn: string;
          Action: string = "GetEndpointAttributes"; Version: string = "2010-03-31"): Recallable =
  ## postGetEndpointAttributes
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   EndpointArn: string (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613633 = newJObject()
  var formData_613634 = newJObject()
  add(formData_613634, "EndpointArn", newJString(EndpointArn))
  add(query_613633, "Action", newJString(Action))
  add(query_613633, "Version", newJString(Version))
  result = call_613632.call(nil, query_613633, nil, formData_613634, nil)

var postGetEndpointAttributes* = Call_PostGetEndpointAttributes_613618(
    name: "postGetEndpointAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetEndpointAttributes",
    validator: validate_PostGetEndpointAttributes_613619, base: "/",
    url: url_PostGetEndpointAttributes_613620,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetEndpointAttributes_613602 = ref object of OpenApiRestCall_612658
proc url_GetGetEndpointAttributes_613604(protocol: Scheme; host: string;
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

proc validate_GetGetEndpointAttributes_613603(path: JsonNode; query: JsonNode;
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
  var valid_613605 = query.getOrDefault("Action")
  valid_613605 = validateParameter(valid_613605, JString, required = true,
                                 default = newJString("GetEndpointAttributes"))
  if valid_613605 != nil:
    section.add "Action", valid_613605
  var valid_613606 = query.getOrDefault("EndpointArn")
  valid_613606 = validateParameter(valid_613606, JString, required = true,
                                 default = nil)
  if valid_613606 != nil:
    section.add "EndpointArn", valid_613606
  var valid_613607 = query.getOrDefault("Version")
  valid_613607 = validateParameter(valid_613607, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613607 != nil:
    section.add "Version", valid_613607
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613608 = header.getOrDefault("X-Amz-Signature")
  valid_613608 = validateParameter(valid_613608, JString, required = false,
                                 default = nil)
  if valid_613608 != nil:
    section.add "X-Amz-Signature", valid_613608
  var valid_613609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613609 = validateParameter(valid_613609, JString, required = false,
                                 default = nil)
  if valid_613609 != nil:
    section.add "X-Amz-Content-Sha256", valid_613609
  var valid_613610 = header.getOrDefault("X-Amz-Date")
  valid_613610 = validateParameter(valid_613610, JString, required = false,
                                 default = nil)
  if valid_613610 != nil:
    section.add "X-Amz-Date", valid_613610
  var valid_613611 = header.getOrDefault("X-Amz-Credential")
  valid_613611 = validateParameter(valid_613611, JString, required = false,
                                 default = nil)
  if valid_613611 != nil:
    section.add "X-Amz-Credential", valid_613611
  var valid_613612 = header.getOrDefault("X-Amz-Security-Token")
  valid_613612 = validateParameter(valid_613612, JString, required = false,
                                 default = nil)
  if valid_613612 != nil:
    section.add "X-Amz-Security-Token", valid_613612
  var valid_613613 = header.getOrDefault("X-Amz-Algorithm")
  valid_613613 = validateParameter(valid_613613, JString, required = false,
                                 default = nil)
  if valid_613613 != nil:
    section.add "X-Amz-Algorithm", valid_613613
  var valid_613614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613614 = validateParameter(valid_613614, JString, required = false,
                                 default = nil)
  if valid_613614 != nil:
    section.add "X-Amz-SignedHeaders", valid_613614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613615: Call_GetGetEndpointAttributes_613602; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_613615.validator(path, query, header, formData, body)
  let scheme = call_613615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613615.url(scheme.get, call_613615.host, call_613615.base,
                         call_613615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613615, url, valid)

proc call*(call_613616: Call_GetGetEndpointAttributes_613602; EndpointArn: string;
          Action: string = "GetEndpointAttributes"; Version: string = "2010-03-31"): Recallable =
  ## getGetEndpointAttributes
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   EndpointArn: string (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  ##   Version: string (required)
  var query_613617 = newJObject()
  add(query_613617, "Action", newJString(Action))
  add(query_613617, "EndpointArn", newJString(EndpointArn))
  add(query_613617, "Version", newJString(Version))
  result = call_613616.call(nil, query_613617, nil, nil, nil)

var getGetEndpointAttributes* = Call_GetGetEndpointAttributes_613602(
    name: "getGetEndpointAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetEndpointAttributes",
    validator: validate_GetGetEndpointAttributes_613603, base: "/",
    url: url_GetGetEndpointAttributes_613604, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetPlatformApplicationAttributes_613651 = ref object of OpenApiRestCall_612658
proc url_PostGetPlatformApplicationAttributes_613653(protocol: Scheme;
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

proc validate_PostGetPlatformApplicationAttributes_613652(path: JsonNode;
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
  var valid_613654 = query.getOrDefault("Action")
  valid_613654 = validateParameter(valid_613654, JString, required = true, default = newJString(
      "GetPlatformApplicationAttributes"))
  if valid_613654 != nil:
    section.add "Action", valid_613654
  var valid_613655 = query.getOrDefault("Version")
  valid_613655 = validateParameter(valid_613655, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613655 != nil:
    section.add "Version", valid_613655
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613656 = header.getOrDefault("X-Amz-Signature")
  valid_613656 = validateParameter(valid_613656, JString, required = false,
                                 default = nil)
  if valid_613656 != nil:
    section.add "X-Amz-Signature", valid_613656
  var valid_613657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613657 = validateParameter(valid_613657, JString, required = false,
                                 default = nil)
  if valid_613657 != nil:
    section.add "X-Amz-Content-Sha256", valid_613657
  var valid_613658 = header.getOrDefault("X-Amz-Date")
  valid_613658 = validateParameter(valid_613658, JString, required = false,
                                 default = nil)
  if valid_613658 != nil:
    section.add "X-Amz-Date", valid_613658
  var valid_613659 = header.getOrDefault("X-Amz-Credential")
  valid_613659 = validateParameter(valid_613659, JString, required = false,
                                 default = nil)
  if valid_613659 != nil:
    section.add "X-Amz-Credential", valid_613659
  var valid_613660 = header.getOrDefault("X-Amz-Security-Token")
  valid_613660 = validateParameter(valid_613660, JString, required = false,
                                 default = nil)
  if valid_613660 != nil:
    section.add "X-Amz-Security-Token", valid_613660
  var valid_613661 = header.getOrDefault("X-Amz-Algorithm")
  valid_613661 = validateParameter(valid_613661, JString, required = false,
                                 default = nil)
  if valid_613661 != nil:
    section.add "X-Amz-Algorithm", valid_613661
  var valid_613662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613662 = validateParameter(valid_613662, JString, required = false,
                                 default = nil)
  if valid_613662 != nil:
    section.add "X-Amz-SignedHeaders", valid_613662
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_613663 = formData.getOrDefault("PlatformApplicationArn")
  valid_613663 = validateParameter(valid_613663, JString, required = true,
                                 default = nil)
  if valid_613663 != nil:
    section.add "PlatformApplicationArn", valid_613663
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613664: Call_PostGetPlatformApplicationAttributes_613651;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_613664.validator(path, query, header, formData, body)
  let scheme = call_613664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613664.url(scheme.get, call_613664.host, call_613664.base,
                         call_613664.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613664, url, valid)

proc call*(call_613665: Call_PostGetPlatformApplicationAttributes_613651;
          PlatformApplicationArn: string;
          Action: string = "GetPlatformApplicationAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetPlatformApplicationAttributes
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613666 = newJObject()
  var formData_613667 = newJObject()
  add(formData_613667, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(query_613666, "Action", newJString(Action))
  add(query_613666, "Version", newJString(Version))
  result = call_613665.call(nil, query_613666, nil, formData_613667, nil)

var postGetPlatformApplicationAttributes* = Call_PostGetPlatformApplicationAttributes_613651(
    name: "postGetPlatformApplicationAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetPlatformApplicationAttributes",
    validator: validate_PostGetPlatformApplicationAttributes_613652, base: "/",
    url: url_PostGetPlatformApplicationAttributes_613653,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetPlatformApplicationAttributes_613635 = ref object of OpenApiRestCall_612658
proc url_GetGetPlatformApplicationAttributes_613637(protocol: Scheme; host: string;
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

proc validate_GetGetPlatformApplicationAttributes_613636(path: JsonNode;
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
  var valid_613638 = query.getOrDefault("PlatformApplicationArn")
  valid_613638 = validateParameter(valid_613638, JString, required = true,
                                 default = nil)
  if valid_613638 != nil:
    section.add "PlatformApplicationArn", valid_613638
  var valid_613639 = query.getOrDefault("Action")
  valid_613639 = validateParameter(valid_613639, JString, required = true, default = newJString(
      "GetPlatformApplicationAttributes"))
  if valid_613639 != nil:
    section.add "Action", valid_613639
  var valid_613640 = query.getOrDefault("Version")
  valid_613640 = validateParameter(valid_613640, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613640 != nil:
    section.add "Version", valid_613640
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613641 = header.getOrDefault("X-Amz-Signature")
  valid_613641 = validateParameter(valid_613641, JString, required = false,
                                 default = nil)
  if valid_613641 != nil:
    section.add "X-Amz-Signature", valid_613641
  var valid_613642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613642 = validateParameter(valid_613642, JString, required = false,
                                 default = nil)
  if valid_613642 != nil:
    section.add "X-Amz-Content-Sha256", valid_613642
  var valid_613643 = header.getOrDefault("X-Amz-Date")
  valid_613643 = validateParameter(valid_613643, JString, required = false,
                                 default = nil)
  if valid_613643 != nil:
    section.add "X-Amz-Date", valid_613643
  var valid_613644 = header.getOrDefault("X-Amz-Credential")
  valid_613644 = validateParameter(valid_613644, JString, required = false,
                                 default = nil)
  if valid_613644 != nil:
    section.add "X-Amz-Credential", valid_613644
  var valid_613645 = header.getOrDefault("X-Amz-Security-Token")
  valid_613645 = validateParameter(valid_613645, JString, required = false,
                                 default = nil)
  if valid_613645 != nil:
    section.add "X-Amz-Security-Token", valid_613645
  var valid_613646 = header.getOrDefault("X-Amz-Algorithm")
  valid_613646 = validateParameter(valid_613646, JString, required = false,
                                 default = nil)
  if valid_613646 != nil:
    section.add "X-Amz-Algorithm", valid_613646
  var valid_613647 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613647 = validateParameter(valid_613647, JString, required = false,
                                 default = nil)
  if valid_613647 != nil:
    section.add "X-Amz-SignedHeaders", valid_613647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613648: Call_GetGetPlatformApplicationAttributes_613635;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_613648.validator(path, query, header, formData, body)
  let scheme = call_613648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613648.url(scheme.get, call_613648.host, call_613648.base,
                         call_613648.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613648, url, valid)

proc call*(call_613649: Call_GetGetPlatformApplicationAttributes_613635;
          PlatformApplicationArn: string;
          Action: string = "GetPlatformApplicationAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getGetPlatformApplicationAttributes
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613650 = newJObject()
  add(query_613650, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  add(query_613650, "Action", newJString(Action))
  add(query_613650, "Version", newJString(Version))
  result = call_613649.call(nil, query_613650, nil, nil, nil)

var getGetPlatformApplicationAttributes* = Call_GetGetPlatformApplicationAttributes_613635(
    name: "getGetPlatformApplicationAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetPlatformApplicationAttributes",
    validator: validate_GetGetPlatformApplicationAttributes_613636, base: "/",
    url: url_GetGetPlatformApplicationAttributes_613637,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetSMSAttributes_613684 = ref object of OpenApiRestCall_612658
proc url_PostGetSMSAttributes_613686(protocol: Scheme; host: string; base: string;
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

proc validate_PostGetSMSAttributes_613685(path: JsonNode; query: JsonNode;
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
  var valid_613687 = query.getOrDefault("Action")
  valid_613687 = validateParameter(valid_613687, JString, required = true,
                                 default = newJString("GetSMSAttributes"))
  if valid_613687 != nil:
    section.add "Action", valid_613687
  var valid_613688 = query.getOrDefault("Version")
  valid_613688 = validateParameter(valid_613688, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613688 != nil:
    section.add "Version", valid_613688
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613689 = header.getOrDefault("X-Amz-Signature")
  valid_613689 = validateParameter(valid_613689, JString, required = false,
                                 default = nil)
  if valid_613689 != nil:
    section.add "X-Amz-Signature", valid_613689
  var valid_613690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613690 = validateParameter(valid_613690, JString, required = false,
                                 default = nil)
  if valid_613690 != nil:
    section.add "X-Amz-Content-Sha256", valid_613690
  var valid_613691 = header.getOrDefault("X-Amz-Date")
  valid_613691 = validateParameter(valid_613691, JString, required = false,
                                 default = nil)
  if valid_613691 != nil:
    section.add "X-Amz-Date", valid_613691
  var valid_613692 = header.getOrDefault("X-Amz-Credential")
  valid_613692 = validateParameter(valid_613692, JString, required = false,
                                 default = nil)
  if valid_613692 != nil:
    section.add "X-Amz-Credential", valid_613692
  var valid_613693 = header.getOrDefault("X-Amz-Security-Token")
  valid_613693 = validateParameter(valid_613693, JString, required = false,
                                 default = nil)
  if valid_613693 != nil:
    section.add "X-Amz-Security-Token", valid_613693
  var valid_613694 = header.getOrDefault("X-Amz-Algorithm")
  valid_613694 = validateParameter(valid_613694, JString, required = false,
                                 default = nil)
  if valid_613694 != nil:
    section.add "X-Amz-Algorithm", valid_613694
  var valid_613695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613695 = validateParameter(valid_613695, JString, required = false,
                                 default = nil)
  if valid_613695 != nil:
    section.add "X-Amz-SignedHeaders", valid_613695
  result.add "header", section
  ## parameters in `formData` object:
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  section = newJObject()
  var valid_613696 = formData.getOrDefault("attributes")
  valid_613696 = validateParameter(valid_613696, JArray, required = false,
                                 default = nil)
  if valid_613696 != nil:
    section.add "attributes", valid_613696
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613697: Call_PostGetSMSAttributes_613684; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  let valid = call_613697.validator(path, query, header, formData, body)
  let scheme = call_613697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613697.url(scheme.get, call_613697.host, call_613697.base,
                         call_613697.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613697, url, valid)

proc call*(call_613698: Call_PostGetSMSAttributes_613684;
          attributes: JsonNode = nil; Action: string = "GetSMSAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetSMSAttributes
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613699 = newJObject()
  var formData_613700 = newJObject()
  if attributes != nil:
    formData_613700.add "attributes", attributes
  add(query_613699, "Action", newJString(Action))
  add(query_613699, "Version", newJString(Version))
  result = call_613698.call(nil, query_613699, nil, formData_613700, nil)

var postGetSMSAttributes* = Call_PostGetSMSAttributes_613684(
    name: "postGetSMSAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetSMSAttributes",
    validator: validate_PostGetSMSAttributes_613685, base: "/",
    url: url_PostGetSMSAttributes_613686, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetSMSAttributes_613668 = ref object of OpenApiRestCall_612658
proc url_GetGetSMSAttributes_613670(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetSMSAttributes_613669(path: JsonNode; query: JsonNode;
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
  var valid_613671 = query.getOrDefault("Action")
  valid_613671 = validateParameter(valid_613671, JString, required = true,
                                 default = newJString("GetSMSAttributes"))
  if valid_613671 != nil:
    section.add "Action", valid_613671
  var valid_613672 = query.getOrDefault("attributes")
  valid_613672 = validateParameter(valid_613672, JArray, required = false,
                                 default = nil)
  if valid_613672 != nil:
    section.add "attributes", valid_613672
  var valid_613673 = query.getOrDefault("Version")
  valid_613673 = validateParameter(valid_613673, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613673 != nil:
    section.add "Version", valid_613673
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613674 = header.getOrDefault("X-Amz-Signature")
  valid_613674 = validateParameter(valid_613674, JString, required = false,
                                 default = nil)
  if valid_613674 != nil:
    section.add "X-Amz-Signature", valid_613674
  var valid_613675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613675 = validateParameter(valid_613675, JString, required = false,
                                 default = nil)
  if valid_613675 != nil:
    section.add "X-Amz-Content-Sha256", valid_613675
  var valid_613676 = header.getOrDefault("X-Amz-Date")
  valid_613676 = validateParameter(valid_613676, JString, required = false,
                                 default = nil)
  if valid_613676 != nil:
    section.add "X-Amz-Date", valid_613676
  var valid_613677 = header.getOrDefault("X-Amz-Credential")
  valid_613677 = validateParameter(valid_613677, JString, required = false,
                                 default = nil)
  if valid_613677 != nil:
    section.add "X-Amz-Credential", valid_613677
  var valid_613678 = header.getOrDefault("X-Amz-Security-Token")
  valid_613678 = validateParameter(valid_613678, JString, required = false,
                                 default = nil)
  if valid_613678 != nil:
    section.add "X-Amz-Security-Token", valid_613678
  var valid_613679 = header.getOrDefault("X-Amz-Algorithm")
  valid_613679 = validateParameter(valid_613679, JString, required = false,
                                 default = nil)
  if valid_613679 != nil:
    section.add "X-Amz-Algorithm", valid_613679
  var valid_613680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613680 = validateParameter(valid_613680, JString, required = false,
                                 default = nil)
  if valid_613680 != nil:
    section.add "X-Amz-SignedHeaders", valid_613680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613681: Call_GetGetSMSAttributes_613668; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  let valid = call_613681.validator(path, query, header, formData, body)
  let scheme = call_613681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613681.url(scheme.get, call_613681.host, call_613681.base,
                         call_613681.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613681, url, valid)

proc call*(call_613682: Call_GetGetSMSAttributes_613668;
          Action: string = "GetSMSAttributes"; attributes: JsonNode = nil;
          Version: string = "2010-03-31"): Recallable =
  ## getGetSMSAttributes
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ##   Action: string (required)
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  ##   Version: string (required)
  var query_613683 = newJObject()
  add(query_613683, "Action", newJString(Action))
  if attributes != nil:
    query_613683.add "attributes", attributes
  add(query_613683, "Version", newJString(Version))
  result = call_613682.call(nil, query_613683, nil, nil, nil)

var getGetSMSAttributes* = Call_GetGetSMSAttributes_613668(
    name: "getGetSMSAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetSMSAttributes",
    validator: validate_GetGetSMSAttributes_613669, base: "/",
    url: url_GetGetSMSAttributes_613670, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetSubscriptionAttributes_613717 = ref object of OpenApiRestCall_612658
proc url_PostGetSubscriptionAttributes_613719(protocol: Scheme; host: string;
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

proc validate_PostGetSubscriptionAttributes_613718(path: JsonNode; query: JsonNode;
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
  var valid_613720 = query.getOrDefault("Action")
  valid_613720 = validateParameter(valid_613720, JString, required = true, default = newJString(
      "GetSubscriptionAttributes"))
  if valid_613720 != nil:
    section.add "Action", valid_613720
  var valid_613721 = query.getOrDefault("Version")
  valid_613721 = validateParameter(valid_613721, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613721 != nil:
    section.add "Version", valid_613721
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613722 = header.getOrDefault("X-Amz-Signature")
  valid_613722 = validateParameter(valid_613722, JString, required = false,
                                 default = nil)
  if valid_613722 != nil:
    section.add "X-Amz-Signature", valid_613722
  var valid_613723 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613723 = validateParameter(valid_613723, JString, required = false,
                                 default = nil)
  if valid_613723 != nil:
    section.add "X-Amz-Content-Sha256", valid_613723
  var valid_613724 = header.getOrDefault("X-Amz-Date")
  valid_613724 = validateParameter(valid_613724, JString, required = false,
                                 default = nil)
  if valid_613724 != nil:
    section.add "X-Amz-Date", valid_613724
  var valid_613725 = header.getOrDefault("X-Amz-Credential")
  valid_613725 = validateParameter(valid_613725, JString, required = false,
                                 default = nil)
  if valid_613725 != nil:
    section.add "X-Amz-Credential", valid_613725
  var valid_613726 = header.getOrDefault("X-Amz-Security-Token")
  valid_613726 = validateParameter(valid_613726, JString, required = false,
                                 default = nil)
  if valid_613726 != nil:
    section.add "X-Amz-Security-Token", valid_613726
  var valid_613727 = header.getOrDefault("X-Amz-Algorithm")
  valid_613727 = validateParameter(valid_613727, JString, required = false,
                                 default = nil)
  if valid_613727 != nil:
    section.add "X-Amz-Algorithm", valid_613727
  var valid_613728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613728 = validateParameter(valid_613728, JString, required = false,
                                 default = nil)
  if valid_613728 != nil:
    section.add "X-Amz-SignedHeaders", valid_613728
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionArn` field"
  var valid_613729 = formData.getOrDefault("SubscriptionArn")
  valid_613729 = validateParameter(valid_613729, JString, required = true,
                                 default = nil)
  if valid_613729 != nil:
    section.add "SubscriptionArn", valid_613729
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613730: Call_PostGetSubscriptionAttributes_613717; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a subscription.
  ## 
  let valid = call_613730.validator(path, query, header, formData, body)
  let scheme = call_613730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613730.url(scheme.get, call_613730.host, call_613730.base,
                         call_613730.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613730, url, valid)

proc call*(call_613731: Call_PostGetSubscriptionAttributes_613717;
          SubscriptionArn: string; Action: string = "GetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetSubscriptionAttributes
  ## Returns all of the properties of a subscription.
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613732 = newJObject()
  var formData_613733 = newJObject()
  add(formData_613733, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_613732, "Action", newJString(Action))
  add(query_613732, "Version", newJString(Version))
  result = call_613731.call(nil, query_613732, nil, formData_613733, nil)

var postGetSubscriptionAttributes* = Call_PostGetSubscriptionAttributes_613717(
    name: "postGetSubscriptionAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetSubscriptionAttributes",
    validator: validate_PostGetSubscriptionAttributes_613718, base: "/",
    url: url_PostGetSubscriptionAttributes_613719,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetSubscriptionAttributes_613701 = ref object of OpenApiRestCall_612658
proc url_GetGetSubscriptionAttributes_613703(protocol: Scheme; host: string;
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

proc validate_GetGetSubscriptionAttributes_613702(path: JsonNode; query: JsonNode;
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
  var valid_613704 = query.getOrDefault("SubscriptionArn")
  valid_613704 = validateParameter(valid_613704, JString, required = true,
                                 default = nil)
  if valid_613704 != nil:
    section.add "SubscriptionArn", valid_613704
  var valid_613705 = query.getOrDefault("Action")
  valid_613705 = validateParameter(valid_613705, JString, required = true, default = newJString(
      "GetSubscriptionAttributes"))
  if valid_613705 != nil:
    section.add "Action", valid_613705
  var valid_613706 = query.getOrDefault("Version")
  valid_613706 = validateParameter(valid_613706, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613706 != nil:
    section.add "Version", valid_613706
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613707 = header.getOrDefault("X-Amz-Signature")
  valid_613707 = validateParameter(valid_613707, JString, required = false,
                                 default = nil)
  if valid_613707 != nil:
    section.add "X-Amz-Signature", valid_613707
  var valid_613708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613708 = validateParameter(valid_613708, JString, required = false,
                                 default = nil)
  if valid_613708 != nil:
    section.add "X-Amz-Content-Sha256", valid_613708
  var valid_613709 = header.getOrDefault("X-Amz-Date")
  valid_613709 = validateParameter(valid_613709, JString, required = false,
                                 default = nil)
  if valid_613709 != nil:
    section.add "X-Amz-Date", valid_613709
  var valid_613710 = header.getOrDefault("X-Amz-Credential")
  valid_613710 = validateParameter(valid_613710, JString, required = false,
                                 default = nil)
  if valid_613710 != nil:
    section.add "X-Amz-Credential", valid_613710
  var valid_613711 = header.getOrDefault("X-Amz-Security-Token")
  valid_613711 = validateParameter(valid_613711, JString, required = false,
                                 default = nil)
  if valid_613711 != nil:
    section.add "X-Amz-Security-Token", valid_613711
  var valid_613712 = header.getOrDefault("X-Amz-Algorithm")
  valid_613712 = validateParameter(valid_613712, JString, required = false,
                                 default = nil)
  if valid_613712 != nil:
    section.add "X-Amz-Algorithm", valid_613712
  var valid_613713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613713 = validateParameter(valid_613713, JString, required = false,
                                 default = nil)
  if valid_613713 != nil:
    section.add "X-Amz-SignedHeaders", valid_613713
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613714: Call_GetGetSubscriptionAttributes_613701; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a subscription.
  ## 
  let valid = call_613714.validator(path, query, header, formData, body)
  let scheme = call_613714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613714.url(scheme.get, call_613714.host, call_613714.base,
                         call_613714.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613714, url, valid)

proc call*(call_613715: Call_GetGetSubscriptionAttributes_613701;
          SubscriptionArn: string; Action: string = "GetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getGetSubscriptionAttributes
  ## Returns all of the properties of a subscription.
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613716 = newJObject()
  add(query_613716, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_613716, "Action", newJString(Action))
  add(query_613716, "Version", newJString(Version))
  result = call_613715.call(nil, query_613716, nil, nil, nil)

var getGetSubscriptionAttributes* = Call_GetGetSubscriptionAttributes_613701(
    name: "getGetSubscriptionAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetSubscriptionAttributes",
    validator: validate_GetGetSubscriptionAttributes_613702, base: "/",
    url: url_GetGetSubscriptionAttributes_613703,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetTopicAttributes_613750 = ref object of OpenApiRestCall_612658
proc url_PostGetTopicAttributes_613752(protocol: Scheme; host: string; base: string;
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

proc validate_PostGetTopicAttributes_613751(path: JsonNode; query: JsonNode;
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
  var valid_613753 = query.getOrDefault("Action")
  valid_613753 = validateParameter(valid_613753, JString, required = true,
                                 default = newJString("GetTopicAttributes"))
  if valid_613753 != nil:
    section.add "Action", valid_613753
  var valid_613754 = query.getOrDefault("Version")
  valid_613754 = validateParameter(valid_613754, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613754 != nil:
    section.add "Version", valid_613754
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613755 = header.getOrDefault("X-Amz-Signature")
  valid_613755 = validateParameter(valid_613755, JString, required = false,
                                 default = nil)
  if valid_613755 != nil:
    section.add "X-Amz-Signature", valid_613755
  var valid_613756 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613756 = validateParameter(valid_613756, JString, required = false,
                                 default = nil)
  if valid_613756 != nil:
    section.add "X-Amz-Content-Sha256", valid_613756
  var valid_613757 = header.getOrDefault("X-Amz-Date")
  valid_613757 = validateParameter(valid_613757, JString, required = false,
                                 default = nil)
  if valid_613757 != nil:
    section.add "X-Amz-Date", valid_613757
  var valid_613758 = header.getOrDefault("X-Amz-Credential")
  valid_613758 = validateParameter(valid_613758, JString, required = false,
                                 default = nil)
  if valid_613758 != nil:
    section.add "X-Amz-Credential", valid_613758
  var valid_613759 = header.getOrDefault("X-Amz-Security-Token")
  valid_613759 = validateParameter(valid_613759, JString, required = false,
                                 default = nil)
  if valid_613759 != nil:
    section.add "X-Amz-Security-Token", valid_613759
  var valid_613760 = header.getOrDefault("X-Amz-Algorithm")
  valid_613760 = validateParameter(valid_613760, JString, required = false,
                                 default = nil)
  if valid_613760 != nil:
    section.add "X-Amz-Algorithm", valid_613760
  var valid_613761 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613761 = validateParameter(valid_613761, JString, required = false,
                                 default = nil)
  if valid_613761 != nil:
    section.add "X-Amz-SignedHeaders", valid_613761
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose properties you want to get.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_613762 = formData.getOrDefault("TopicArn")
  valid_613762 = validateParameter(valid_613762, JString, required = true,
                                 default = nil)
  if valid_613762 != nil:
    section.add "TopicArn", valid_613762
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613763: Call_PostGetTopicAttributes_613750; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ## 
  let valid = call_613763.validator(path, query, header, formData, body)
  let scheme = call_613763.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613763.url(scheme.get, call_613763.host, call_613763.base,
                         call_613763.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613763, url, valid)

proc call*(call_613764: Call_PostGetTopicAttributes_613750; TopicArn: string;
          Action: string = "GetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## postGetTopicAttributes
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose properties you want to get.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613765 = newJObject()
  var formData_613766 = newJObject()
  add(formData_613766, "TopicArn", newJString(TopicArn))
  add(query_613765, "Action", newJString(Action))
  add(query_613765, "Version", newJString(Version))
  result = call_613764.call(nil, query_613765, nil, formData_613766, nil)

var postGetTopicAttributes* = Call_PostGetTopicAttributes_613750(
    name: "postGetTopicAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetTopicAttributes",
    validator: validate_PostGetTopicAttributes_613751, base: "/",
    url: url_PostGetTopicAttributes_613752, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetTopicAttributes_613734 = ref object of OpenApiRestCall_612658
proc url_GetGetTopicAttributes_613736(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetTopicAttributes_613735(path: JsonNode; query: JsonNode;
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
  var valid_613737 = query.getOrDefault("Action")
  valid_613737 = validateParameter(valid_613737, JString, required = true,
                                 default = newJString("GetTopicAttributes"))
  if valid_613737 != nil:
    section.add "Action", valid_613737
  var valid_613738 = query.getOrDefault("Version")
  valid_613738 = validateParameter(valid_613738, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613738 != nil:
    section.add "Version", valid_613738
  var valid_613739 = query.getOrDefault("TopicArn")
  valid_613739 = validateParameter(valid_613739, JString, required = true,
                                 default = nil)
  if valid_613739 != nil:
    section.add "TopicArn", valid_613739
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613740 = header.getOrDefault("X-Amz-Signature")
  valid_613740 = validateParameter(valid_613740, JString, required = false,
                                 default = nil)
  if valid_613740 != nil:
    section.add "X-Amz-Signature", valid_613740
  var valid_613741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613741 = validateParameter(valid_613741, JString, required = false,
                                 default = nil)
  if valid_613741 != nil:
    section.add "X-Amz-Content-Sha256", valid_613741
  var valid_613742 = header.getOrDefault("X-Amz-Date")
  valid_613742 = validateParameter(valid_613742, JString, required = false,
                                 default = nil)
  if valid_613742 != nil:
    section.add "X-Amz-Date", valid_613742
  var valid_613743 = header.getOrDefault("X-Amz-Credential")
  valid_613743 = validateParameter(valid_613743, JString, required = false,
                                 default = nil)
  if valid_613743 != nil:
    section.add "X-Amz-Credential", valid_613743
  var valid_613744 = header.getOrDefault("X-Amz-Security-Token")
  valid_613744 = validateParameter(valid_613744, JString, required = false,
                                 default = nil)
  if valid_613744 != nil:
    section.add "X-Amz-Security-Token", valid_613744
  var valid_613745 = header.getOrDefault("X-Amz-Algorithm")
  valid_613745 = validateParameter(valid_613745, JString, required = false,
                                 default = nil)
  if valid_613745 != nil:
    section.add "X-Amz-Algorithm", valid_613745
  var valid_613746 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613746 = validateParameter(valid_613746, JString, required = false,
                                 default = nil)
  if valid_613746 != nil:
    section.add "X-Amz-SignedHeaders", valid_613746
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613747: Call_GetGetTopicAttributes_613734; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ## 
  let valid = call_613747.validator(path, query, header, formData, body)
  let scheme = call_613747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613747.url(scheme.get, call_613747.host, call_613747.base,
                         call_613747.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613747, url, valid)

proc call*(call_613748: Call_GetGetTopicAttributes_613734; TopicArn: string;
          Action: string = "GetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## getGetTopicAttributes
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose properties you want to get.
  var query_613749 = newJObject()
  add(query_613749, "Action", newJString(Action))
  add(query_613749, "Version", newJString(Version))
  add(query_613749, "TopicArn", newJString(TopicArn))
  result = call_613748.call(nil, query_613749, nil, nil, nil)

var getGetTopicAttributes* = Call_GetGetTopicAttributes_613734(
    name: "getGetTopicAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetTopicAttributes",
    validator: validate_GetGetTopicAttributes_613735, base: "/",
    url: url_GetGetTopicAttributes_613736, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListEndpointsByPlatformApplication_613784 = ref object of OpenApiRestCall_612658
proc url_PostListEndpointsByPlatformApplication_613786(protocol: Scheme;
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

proc validate_PostListEndpointsByPlatformApplication_613785(path: JsonNode;
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
  var valid_613787 = query.getOrDefault("Action")
  valid_613787 = validateParameter(valid_613787, JString, required = true, default = newJString(
      "ListEndpointsByPlatformApplication"))
  if valid_613787 != nil:
    section.add "Action", valid_613787
  var valid_613788 = query.getOrDefault("Version")
  valid_613788 = validateParameter(valid_613788, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613788 != nil:
    section.add "Version", valid_613788
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613789 = header.getOrDefault("X-Amz-Signature")
  valid_613789 = validateParameter(valid_613789, JString, required = false,
                                 default = nil)
  if valid_613789 != nil:
    section.add "X-Amz-Signature", valid_613789
  var valid_613790 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613790 = validateParameter(valid_613790, JString, required = false,
                                 default = nil)
  if valid_613790 != nil:
    section.add "X-Amz-Content-Sha256", valid_613790
  var valid_613791 = header.getOrDefault("X-Amz-Date")
  valid_613791 = validateParameter(valid_613791, JString, required = false,
                                 default = nil)
  if valid_613791 != nil:
    section.add "X-Amz-Date", valid_613791
  var valid_613792 = header.getOrDefault("X-Amz-Credential")
  valid_613792 = validateParameter(valid_613792, JString, required = false,
                                 default = nil)
  if valid_613792 != nil:
    section.add "X-Amz-Credential", valid_613792
  var valid_613793 = header.getOrDefault("X-Amz-Security-Token")
  valid_613793 = validateParameter(valid_613793, JString, required = false,
                                 default = nil)
  if valid_613793 != nil:
    section.add "X-Amz-Security-Token", valid_613793
  var valid_613794 = header.getOrDefault("X-Amz-Algorithm")
  valid_613794 = validateParameter(valid_613794, JString, required = false,
                                 default = nil)
  if valid_613794 != nil:
    section.add "X-Amz-Algorithm", valid_613794
  var valid_613795 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613795 = validateParameter(valid_613795, JString, required = false,
                                 default = nil)
  if valid_613795 != nil:
    section.add "X-Amz-SignedHeaders", valid_613795
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListEndpointsByPlatformApplication action to retrieve additional records that are available after the first page results.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_613796 = formData.getOrDefault("PlatformApplicationArn")
  valid_613796 = validateParameter(valid_613796, JString, required = true,
                                 default = nil)
  if valid_613796 != nil:
    section.add "PlatformApplicationArn", valid_613796
  var valid_613797 = formData.getOrDefault("NextToken")
  valid_613797 = validateParameter(valid_613797, JString, required = false,
                                 default = nil)
  if valid_613797 != nil:
    section.add "NextToken", valid_613797
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613798: Call_PostListEndpointsByPlatformApplication_613784;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as FCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_613798.validator(path, query, header, formData, body)
  let scheme = call_613798.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613798.url(scheme.get, call_613798.host, call_613798.base,
                         call_613798.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613798, url, valid)

proc call*(call_613799: Call_PostListEndpointsByPlatformApplication_613784;
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
  var query_613800 = newJObject()
  var formData_613801 = newJObject()
  add(formData_613801, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(formData_613801, "NextToken", newJString(NextToken))
  add(query_613800, "Action", newJString(Action))
  add(query_613800, "Version", newJString(Version))
  result = call_613799.call(nil, query_613800, nil, formData_613801, nil)

var postListEndpointsByPlatformApplication* = Call_PostListEndpointsByPlatformApplication_613784(
    name: "postListEndpointsByPlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com",
    route: "/#Action=ListEndpointsByPlatformApplication",
    validator: validate_PostListEndpointsByPlatformApplication_613785, base: "/",
    url: url_PostListEndpointsByPlatformApplication_613786,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListEndpointsByPlatformApplication_613767 = ref object of OpenApiRestCall_612658
proc url_GetListEndpointsByPlatformApplication_613769(protocol: Scheme;
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

proc validate_GetListEndpointsByPlatformApplication_613768(path: JsonNode;
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
  var valid_613770 = query.getOrDefault("NextToken")
  valid_613770 = validateParameter(valid_613770, JString, required = false,
                                 default = nil)
  if valid_613770 != nil:
    section.add "NextToken", valid_613770
  assert query != nil, "query argument is necessary due to required `PlatformApplicationArn` field"
  var valid_613771 = query.getOrDefault("PlatformApplicationArn")
  valid_613771 = validateParameter(valid_613771, JString, required = true,
                                 default = nil)
  if valid_613771 != nil:
    section.add "PlatformApplicationArn", valid_613771
  var valid_613772 = query.getOrDefault("Action")
  valid_613772 = validateParameter(valid_613772, JString, required = true, default = newJString(
      "ListEndpointsByPlatformApplication"))
  if valid_613772 != nil:
    section.add "Action", valid_613772
  var valid_613773 = query.getOrDefault("Version")
  valid_613773 = validateParameter(valid_613773, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613773 != nil:
    section.add "Version", valid_613773
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613774 = header.getOrDefault("X-Amz-Signature")
  valid_613774 = validateParameter(valid_613774, JString, required = false,
                                 default = nil)
  if valid_613774 != nil:
    section.add "X-Amz-Signature", valid_613774
  var valid_613775 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613775 = validateParameter(valid_613775, JString, required = false,
                                 default = nil)
  if valid_613775 != nil:
    section.add "X-Amz-Content-Sha256", valid_613775
  var valid_613776 = header.getOrDefault("X-Amz-Date")
  valid_613776 = validateParameter(valid_613776, JString, required = false,
                                 default = nil)
  if valid_613776 != nil:
    section.add "X-Amz-Date", valid_613776
  var valid_613777 = header.getOrDefault("X-Amz-Credential")
  valid_613777 = validateParameter(valid_613777, JString, required = false,
                                 default = nil)
  if valid_613777 != nil:
    section.add "X-Amz-Credential", valid_613777
  var valid_613778 = header.getOrDefault("X-Amz-Security-Token")
  valid_613778 = validateParameter(valid_613778, JString, required = false,
                                 default = nil)
  if valid_613778 != nil:
    section.add "X-Amz-Security-Token", valid_613778
  var valid_613779 = header.getOrDefault("X-Amz-Algorithm")
  valid_613779 = validateParameter(valid_613779, JString, required = false,
                                 default = nil)
  if valid_613779 != nil:
    section.add "X-Amz-Algorithm", valid_613779
  var valid_613780 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613780 = validateParameter(valid_613780, JString, required = false,
                                 default = nil)
  if valid_613780 != nil:
    section.add "X-Amz-SignedHeaders", valid_613780
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613781: Call_GetListEndpointsByPlatformApplication_613767;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as FCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_613781.validator(path, query, header, formData, body)
  let scheme = call_613781.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613781.url(scheme.get, call_613781.host, call_613781.base,
                         call_613781.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613781, url, valid)

proc call*(call_613782: Call_GetListEndpointsByPlatformApplication_613767;
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
  var query_613783 = newJObject()
  add(query_613783, "NextToken", newJString(NextToken))
  add(query_613783, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  add(query_613783, "Action", newJString(Action))
  add(query_613783, "Version", newJString(Version))
  result = call_613782.call(nil, query_613783, nil, nil, nil)

var getListEndpointsByPlatformApplication* = Call_GetListEndpointsByPlatformApplication_613767(
    name: "getListEndpointsByPlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com",
    route: "/#Action=ListEndpointsByPlatformApplication",
    validator: validate_GetListEndpointsByPlatformApplication_613768, base: "/",
    url: url_GetListEndpointsByPlatformApplication_613769,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPhoneNumbersOptedOut_613818 = ref object of OpenApiRestCall_612658
proc url_PostListPhoneNumbersOptedOut_613820(protocol: Scheme; host: string;
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

proc validate_PostListPhoneNumbersOptedOut_613819(path: JsonNode; query: JsonNode;
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
  var valid_613821 = query.getOrDefault("Action")
  valid_613821 = validateParameter(valid_613821, JString, required = true, default = newJString(
      "ListPhoneNumbersOptedOut"))
  if valid_613821 != nil:
    section.add "Action", valid_613821
  var valid_613822 = query.getOrDefault("Version")
  valid_613822 = validateParameter(valid_613822, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613822 != nil:
    section.add "Version", valid_613822
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613823 = header.getOrDefault("X-Amz-Signature")
  valid_613823 = validateParameter(valid_613823, JString, required = false,
                                 default = nil)
  if valid_613823 != nil:
    section.add "X-Amz-Signature", valid_613823
  var valid_613824 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613824 = validateParameter(valid_613824, JString, required = false,
                                 default = nil)
  if valid_613824 != nil:
    section.add "X-Amz-Content-Sha256", valid_613824
  var valid_613825 = header.getOrDefault("X-Amz-Date")
  valid_613825 = validateParameter(valid_613825, JString, required = false,
                                 default = nil)
  if valid_613825 != nil:
    section.add "X-Amz-Date", valid_613825
  var valid_613826 = header.getOrDefault("X-Amz-Credential")
  valid_613826 = validateParameter(valid_613826, JString, required = false,
                                 default = nil)
  if valid_613826 != nil:
    section.add "X-Amz-Credential", valid_613826
  var valid_613827 = header.getOrDefault("X-Amz-Security-Token")
  valid_613827 = validateParameter(valid_613827, JString, required = false,
                                 default = nil)
  if valid_613827 != nil:
    section.add "X-Amz-Security-Token", valid_613827
  var valid_613828 = header.getOrDefault("X-Amz-Algorithm")
  valid_613828 = validateParameter(valid_613828, JString, required = false,
                                 default = nil)
  if valid_613828 != nil:
    section.add "X-Amz-Algorithm", valid_613828
  var valid_613829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613829 = validateParameter(valid_613829, JString, required = false,
                                 default = nil)
  if valid_613829 != nil:
    section.add "X-Amz-SignedHeaders", valid_613829
  result.add "header", section
  ## parameters in `formData` object:
  ##   nextToken: JString
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  section = newJObject()
  var valid_613830 = formData.getOrDefault("nextToken")
  valid_613830 = validateParameter(valid_613830, JString, required = false,
                                 default = nil)
  if valid_613830 != nil:
    section.add "nextToken", valid_613830
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613831: Call_PostListPhoneNumbersOptedOut_613818; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ## 
  let valid = call_613831.validator(path, query, header, formData, body)
  let scheme = call_613831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613831.url(scheme.get, call_613831.host, call_613831.base,
                         call_613831.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613831, url, valid)

proc call*(call_613832: Call_PostListPhoneNumbersOptedOut_613818;
          nextToken: string = ""; Action: string = "ListPhoneNumbersOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## postListPhoneNumbersOptedOut
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ##   nextToken: string
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613833 = newJObject()
  var formData_613834 = newJObject()
  add(formData_613834, "nextToken", newJString(nextToken))
  add(query_613833, "Action", newJString(Action))
  add(query_613833, "Version", newJString(Version))
  result = call_613832.call(nil, query_613833, nil, formData_613834, nil)

var postListPhoneNumbersOptedOut* = Call_PostListPhoneNumbersOptedOut_613818(
    name: "postListPhoneNumbersOptedOut", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListPhoneNumbersOptedOut",
    validator: validate_PostListPhoneNumbersOptedOut_613819, base: "/",
    url: url_PostListPhoneNumbersOptedOut_613820,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPhoneNumbersOptedOut_613802 = ref object of OpenApiRestCall_612658
proc url_GetListPhoneNumbersOptedOut_613804(protocol: Scheme; host: string;
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

proc validate_GetListPhoneNumbersOptedOut_613803(path: JsonNode; query: JsonNode;
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
  var valid_613805 = query.getOrDefault("nextToken")
  valid_613805 = validateParameter(valid_613805, JString, required = false,
                                 default = nil)
  if valid_613805 != nil:
    section.add "nextToken", valid_613805
  var valid_613806 = query.getOrDefault("Action")
  valid_613806 = validateParameter(valid_613806, JString, required = true, default = newJString(
      "ListPhoneNumbersOptedOut"))
  if valid_613806 != nil:
    section.add "Action", valid_613806
  var valid_613807 = query.getOrDefault("Version")
  valid_613807 = validateParameter(valid_613807, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613807 != nil:
    section.add "Version", valid_613807
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613808 = header.getOrDefault("X-Amz-Signature")
  valid_613808 = validateParameter(valid_613808, JString, required = false,
                                 default = nil)
  if valid_613808 != nil:
    section.add "X-Amz-Signature", valid_613808
  var valid_613809 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613809 = validateParameter(valid_613809, JString, required = false,
                                 default = nil)
  if valid_613809 != nil:
    section.add "X-Amz-Content-Sha256", valid_613809
  var valid_613810 = header.getOrDefault("X-Amz-Date")
  valid_613810 = validateParameter(valid_613810, JString, required = false,
                                 default = nil)
  if valid_613810 != nil:
    section.add "X-Amz-Date", valid_613810
  var valid_613811 = header.getOrDefault("X-Amz-Credential")
  valid_613811 = validateParameter(valid_613811, JString, required = false,
                                 default = nil)
  if valid_613811 != nil:
    section.add "X-Amz-Credential", valid_613811
  var valid_613812 = header.getOrDefault("X-Amz-Security-Token")
  valid_613812 = validateParameter(valid_613812, JString, required = false,
                                 default = nil)
  if valid_613812 != nil:
    section.add "X-Amz-Security-Token", valid_613812
  var valid_613813 = header.getOrDefault("X-Amz-Algorithm")
  valid_613813 = validateParameter(valid_613813, JString, required = false,
                                 default = nil)
  if valid_613813 != nil:
    section.add "X-Amz-Algorithm", valid_613813
  var valid_613814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613814 = validateParameter(valid_613814, JString, required = false,
                                 default = nil)
  if valid_613814 != nil:
    section.add "X-Amz-SignedHeaders", valid_613814
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613815: Call_GetListPhoneNumbersOptedOut_613802; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ## 
  let valid = call_613815.validator(path, query, header, formData, body)
  let scheme = call_613815.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613815.url(scheme.get, call_613815.host, call_613815.base,
                         call_613815.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613815, url, valid)

proc call*(call_613816: Call_GetListPhoneNumbersOptedOut_613802;
          nextToken: string = ""; Action: string = "ListPhoneNumbersOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## getListPhoneNumbersOptedOut
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ##   nextToken: string
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613817 = newJObject()
  add(query_613817, "nextToken", newJString(nextToken))
  add(query_613817, "Action", newJString(Action))
  add(query_613817, "Version", newJString(Version))
  result = call_613816.call(nil, query_613817, nil, nil, nil)

var getListPhoneNumbersOptedOut* = Call_GetListPhoneNumbersOptedOut_613802(
    name: "getListPhoneNumbersOptedOut", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListPhoneNumbersOptedOut",
    validator: validate_GetListPhoneNumbersOptedOut_613803, base: "/",
    url: url_GetListPhoneNumbersOptedOut_613804,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPlatformApplications_613851 = ref object of OpenApiRestCall_612658
proc url_PostListPlatformApplications_613853(protocol: Scheme; host: string;
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

proc validate_PostListPlatformApplications_613852(path: JsonNode; query: JsonNode;
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
  var valid_613854 = query.getOrDefault("Action")
  valid_613854 = validateParameter(valid_613854, JString, required = true, default = newJString(
      "ListPlatformApplications"))
  if valid_613854 != nil:
    section.add "Action", valid_613854
  var valid_613855 = query.getOrDefault("Version")
  valid_613855 = validateParameter(valid_613855, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613855 != nil:
    section.add "Version", valid_613855
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613856 = header.getOrDefault("X-Amz-Signature")
  valid_613856 = validateParameter(valid_613856, JString, required = false,
                                 default = nil)
  if valid_613856 != nil:
    section.add "X-Amz-Signature", valid_613856
  var valid_613857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613857 = validateParameter(valid_613857, JString, required = false,
                                 default = nil)
  if valid_613857 != nil:
    section.add "X-Amz-Content-Sha256", valid_613857
  var valid_613858 = header.getOrDefault("X-Amz-Date")
  valid_613858 = validateParameter(valid_613858, JString, required = false,
                                 default = nil)
  if valid_613858 != nil:
    section.add "X-Amz-Date", valid_613858
  var valid_613859 = header.getOrDefault("X-Amz-Credential")
  valid_613859 = validateParameter(valid_613859, JString, required = false,
                                 default = nil)
  if valid_613859 != nil:
    section.add "X-Amz-Credential", valid_613859
  var valid_613860 = header.getOrDefault("X-Amz-Security-Token")
  valid_613860 = validateParameter(valid_613860, JString, required = false,
                                 default = nil)
  if valid_613860 != nil:
    section.add "X-Amz-Security-Token", valid_613860
  var valid_613861 = header.getOrDefault("X-Amz-Algorithm")
  valid_613861 = validateParameter(valid_613861, JString, required = false,
                                 default = nil)
  if valid_613861 != nil:
    section.add "X-Amz-Algorithm", valid_613861
  var valid_613862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613862 = validateParameter(valid_613862, JString, required = false,
                                 default = nil)
  if valid_613862 != nil:
    section.add "X-Amz-SignedHeaders", valid_613862
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  section = newJObject()
  var valid_613863 = formData.getOrDefault("NextToken")
  valid_613863 = validateParameter(valid_613863, JString, required = false,
                                 default = nil)
  if valid_613863 != nil:
    section.add "NextToken", valid_613863
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613864: Call_PostListPlatformApplications_613851; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and FCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  let valid = call_613864.validator(path, query, header, formData, body)
  let scheme = call_613864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613864.url(scheme.get, call_613864.host, call_613864.base,
                         call_613864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613864, url, valid)

proc call*(call_613865: Call_PostListPlatformApplications_613851;
          NextToken: string = ""; Action: string = "ListPlatformApplications";
          Version: string = "2010-03-31"): Recallable =
  ## postListPlatformApplications
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and FCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613866 = newJObject()
  var formData_613867 = newJObject()
  add(formData_613867, "NextToken", newJString(NextToken))
  add(query_613866, "Action", newJString(Action))
  add(query_613866, "Version", newJString(Version))
  result = call_613865.call(nil, query_613866, nil, formData_613867, nil)

var postListPlatformApplications* = Call_PostListPlatformApplications_613851(
    name: "postListPlatformApplications", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListPlatformApplications",
    validator: validate_PostListPlatformApplications_613852, base: "/",
    url: url_PostListPlatformApplications_613853,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPlatformApplications_613835 = ref object of OpenApiRestCall_612658
proc url_GetListPlatformApplications_613837(protocol: Scheme; host: string;
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

proc validate_GetListPlatformApplications_613836(path: JsonNode; query: JsonNode;
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
  var valid_613838 = query.getOrDefault("NextToken")
  valid_613838 = validateParameter(valid_613838, JString, required = false,
                                 default = nil)
  if valid_613838 != nil:
    section.add "NextToken", valid_613838
  var valid_613839 = query.getOrDefault("Action")
  valid_613839 = validateParameter(valid_613839, JString, required = true, default = newJString(
      "ListPlatformApplications"))
  if valid_613839 != nil:
    section.add "Action", valid_613839
  var valid_613840 = query.getOrDefault("Version")
  valid_613840 = validateParameter(valid_613840, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613840 != nil:
    section.add "Version", valid_613840
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613841 = header.getOrDefault("X-Amz-Signature")
  valid_613841 = validateParameter(valid_613841, JString, required = false,
                                 default = nil)
  if valid_613841 != nil:
    section.add "X-Amz-Signature", valid_613841
  var valid_613842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613842 = validateParameter(valid_613842, JString, required = false,
                                 default = nil)
  if valid_613842 != nil:
    section.add "X-Amz-Content-Sha256", valid_613842
  var valid_613843 = header.getOrDefault("X-Amz-Date")
  valid_613843 = validateParameter(valid_613843, JString, required = false,
                                 default = nil)
  if valid_613843 != nil:
    section.add "X-Amz-Date", valid_613843
  var valid_613844 = header.getOrDefault("X-Amz-Credential")
  valid_613844 = validateParameter(valid_613844, JString, required = false,
                                 default = nil)
  if valid_613844 != nil:
    section.add "X-Amz-Credential", valid_613844
  var valid_613845 = header.getOrDefault("X-Amz-Security-Token")
  valid_613845 = validateParameter(valid_613845, JString, required = false,
                                 default = nil)
  if valid_613845 != nil:
    section.add "X-Amz-Security-Token", valid_613845
  var valid_613846 = header.getOrDefault("X-Amz-Algorithm")
  valid_613846 = validateParameter(valid_613846, JString, required = false,
                                 default = nil)
  if valid_613846 != nil:
    section.add "X-Amz-Algorithm", valid_613846
  var valid_613847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613847 = validateParameter(valid_613847, JString, required = false,
                                 default = nil)
  if valid_613847 != nil:
    section.add "X-Amz-SignedHeaders", valid_613847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613848: Call_GetListPlatformApplications_613835; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and FCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  let valid = call_613848.validator(path, query, header, formData, body)
  let scheme = call_613848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613848.url(scheme.get, call_613848.host, call_613848.base,
                         call_613848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613848, url, valid)

proc call*(call_613849: Call_GetListPlatformApplications_613835;
          NextToken: string = ""; Action: string = "ListPlatformApplications";
          Version: string = "2010-03-31"): Recallable =
  ## getListPlatformApplications
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and FCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613850 = newJObject()
  add(query_613850, "NextToken", newJString(NextToken))
  add(query_613850, "Action", newJString(Action))
  add(query_613850, "Version", newJString(Version))
  result = call_613849.call(nil, query_613850, nil, nil, nil)

var getListPlatformApplications* = Call_GetListPlatformApplications_613835(
    name: "getListPlatformApplications", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListPlatformApplications",
    validator: validate_GetListPlatformApplications_613836, base: "/",
    url: url_GetListPlatformApplications_613837,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListSubscriptions_613884 = ref object of OpenApiRestCall_612658
proc url_PostListSubscriptions_613886(protocol: Scheme; host: string; base: string;
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

proc validate_PostListSubscriptions_613885(path: JsonNode; query: JsonNode;
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
  var valid_613887 = query.getOrDefault("Action")
  valid_613887 = validateParameter(valid_613887, JString, required = true,
                                 default = newJString("ListSubscriptions"))
  if valid_613887 != nil:
    section.add "Action", valid_613887
  var valid_613888 = query.getOrDefault("Version")
  valid_613888 = validateParameter(valid_613888, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613888 != nil:
    section.add "Version", valid_613888
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613889 = header.getOrDefault("X-Amz-Signature")
  valid_613889 = validateParameter(valid_613889, JString, required = false,
                                 default = nil)
  if valid_613889 != nil:
    section.add "X-Amz-Signature", valid_613889
  var valid_613890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613890 = validateParameter(valid_613890, JString, required = false,
                                 default = nil)
  if valid_613890 != nil:
    section.add "X-Amz-Content-Sha256", valid_613890
  var valid_613891 = header.getOrDefault("X-Amz-Date")
  valid_613891 = validateParameter(valid_613891, JString, required = false,
                                 default = nil)
  if valid_613891 != nil:
    section.add "X-Amz-Date", valid_613891
  var valid_613892 = header.getOrDefault("X-Amz-Credential")
  valid_613892 = validateParameter(valid_613892, JString, required = false,
                                 default = nil)
  if valid_613892 != nil:
    section.add "X-Amz-Credential", valid_613892
  var valid_613893 = header.getOrDefault("X-Amz-Security-Token")
  valid_613893 = validateParameter(valid_613893, JString, required = false,
                                 default = nil)
  if valid_613893 != nil:
    section.add "X-Amz-Security-Token", valid_613893
  var valid_613894 = header.getOrDefault("X-Amz-Algorithm")
  valid_613894 = validateParameter(valid_613894, JString, required = false,
                                 default = nil)
  if valid_613894 != nil:
    section.add "X-Amz-Algorithm", valid_613894
  var valid_613895 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613895 = validateParameter(valid_613895, JString, required = false,
                                 default = nil)
  if valid_613895 != nil:
    section.add "X-Amz-SignedHeaders", valid_613895
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  section = newJObject()
  var valid_613896 = formData.getOrDefault("NextToken")
  valid_613896 = validateParameter(valid_613896, JString, required = false,
                                 default = nil)
  if valid_613896 != nil:
    section.add "NextToken", valid_613896
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613897: Call_PostListSubscriptions_613884; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_613897.validator(path, query, header, formData, body)
  let scheme = call_613897.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613897.url(scheme.get, call_613897.host, call_613897.base,
                         call_613897.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613897, url, valid)

proc call*(call_613898: Call_PostListSubscriptions_613884; NextToken: string = "";
          Action: string = "ListSubscriptions"; Version: string = "2010-03-31"): Recallable =
  ## postListSubscriptions
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613899 = newJObject()
  var formData_613900 = newJObject()
  add(formData_613900, "NextToken", newJString(NextToken))
  add(query_613899, "Action", newJString(Action))
  add(query_613899, "Version", newJString(Version))
  result = call_613898.call(nil, query_613899, nil, formData_613900, nil)

var postListSubscriptions* = Call_PostListSubscriptions_613884(
    name: "postListSubscriptions", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptions",
    validator: validate_PostListSubscriptions_613885, base: "/",
    url: url_PostListSubscriptions_613886, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListSubscriptions_613868 = ref object of OpenApiRestCall_612658
proc url_GetListSubscriptions_613870(protocol: Scheme; host: string; base: string;
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

proc validate_GetListSubscriptions_613869(path: JsonNode; query: JsonNode;
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
  var valid_613871 = query.getOrDefault("NextToken")
  valid_613871 = validateParameter(valid_613871, JString, required = false,
                                 default = nil)
  if valid_613871 != nil:
    section.add "NextToken", valid_613871
  var valid_613872 = query.getOrDefault("Action")
  valid_613872 = validateParameter(valid_613872, JString, required = true,
                                 default = newJString("ListSubscriptions"))
  if valid_613872 != nil:
    section.add "Action", valid_613872
  var valid_613873 = query.getOrDefault("Version")
  valid_613873 = validateParameter(valid_613873, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613873 != nil:
    section.add "Version", valid_613873
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613874 = header.getOrDefault("X-Amz-Signature")
  valid_613874 = validateParameter(valid_613874, JString, required = false,
                                 default = nil)
  if valid_613874 != nil:
    section.add "X-Amz-Signature", valid_613874
  var valid_613875 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613875 = validateParameter(valid_613875, JString, required = false,
                                 default = nil)
  if valid_613875 != nil:
    section.add "X-Amz-Content-Sha256", valid_613875
  var valid_613876 = header.getOrDefault("X-Amz-Date")
  valid_613876 = validateParameter(valid_613876, JString, required = false,
                                 default = nil)
  if valid_613876 != nil:
    section.add "X-Amz-Date", valid_613876
  var valid_613877 = header.getOrDefault("X-Amz-Credential")
  valid_613877 = validateParameter(valid_613877, JString, required = false,
                                 default = nil)
  if valid_613877 != nil:
    section.add "X-Amz-Credential", valid_613877
  var valid_613878 = header.getOrDefault("X-Amz-Security-Token")
  valid_613878 = validateParameter(valid_613878, JString, required = false,
                                 default = nil)
  if valid_613878 != nil:
    section.add "X-Amz-Security-Token", valid_613878
  var valid_613879 = header.getOrDefault("X-Amz-Algorithm")
  valid_613879 = validateParameter(valid_613879, JString, required = false,
                                 default = nil)
  if valid_613879 != nil:
    section.add "X-Amz-Algorithm", valid_613879
  var valid_613880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613880 = validateParameter(valid_613880, JString, required = false,
                                 default = nil)
  if valid_613880 != nil:
    section.add "X-Amz-SignedHeaders", valid_613880
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613881: Call_GetListSubscriptions_613868; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_613881.validator(path, query, header, formData, body)
  let scheme = call_613881.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613881.url(scheme.get, call_613881.host, call_613881.base,
                         call_613881.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613881, url, valid)

proc call*(call_613882: Call_GetListSubscriptions_613868; NextToken: string = "";
          Action: string = "ListSubscriptions"; Version: string = "2010-03-31"): Recallable =
  ## getListSubscriptions
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613883 = newJObject()
  add(query_613883, "NextToken", newJString(NextToken))
  add(query_613883, "Action", newJString(Action))
  add(query_613883, "Version", newJString(Version))
  result = call_613882.call(nil, query_613883, nil, nil, nil)

var getListSubscriptions* = Call_GetListSubscriptions_613868(
    name: "getListSubscriptions", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptions",
    validator: validate_GetListSubscriptions_613869, base: "/",
    url: url_GetListSubscriptions_613870, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListSubscriptionsByTopic_613918 = ref object of OpenApiRestCall_612658
proc url_PostListSubscriptionsByTopic_613920(protocol: Scheme; host: string;
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

proc validate_PostListSubscriptionsByTopic_613919(path: JsonNode; query: JsonNode;
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
  var valid_613921 = query.getOrDefault("Action")
  valid_613921 = validateParameter(valid_613921, JString, required = true, default = newJString(
      "ListSubscriptionsByTopic"))
  if valid_613921 != nil:
    section.add "Action", valid_613921
  var valid_613922 = query.getOrDefault("Version")
  valid_613922 = validateParameter(valid_613922, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613922 != nil:
    section.add "Version", valid_613922
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613923 = header.getOrDefault("X-Amz-Signature")
  valid_613923 = validateParameter(valid_613923, JString, required = false,
                                 default = nil)
  if valid_613923 != nil:
    section.add "X-Amz-Signature", valid_613923
  var valid_613924 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613924 = validateParameter(valid_613924, JString, required = false,
                                 default = nil)
  if valid_613924 != nil:
    section.add "X-Amz-Content-Sha256", valid_613924
  var valid_613925 = header.getOrDefault("X-Amz-Date")
  valid_613925 = validateParameter(valid_613925, JString, required = false,
                                 default = nil)
  if valid_613925 != nil:
    section.add "X-Amz-Date", valid_613925
  var valid_613926 = header.getOrDefault("X-Amz-Credential")
  valid_613926 = validateParameter(valid_613926, JString, required = false,
                                 default = nil)
  if valid_613926 != nil:
    section.add "X-Amz-Credential", valid_613926
  var valid_613927 = header.getOrDefault("X-Amz-Security-Token")
  valid_613927 = validateParameter(valid_613927, JString, required = false,
                                 default = nil)
  if valid_613927 != nil:
    section.add "X-Amz-Security-Token", valid_613927
  var valid_613928 = header.getOrDefault("X-Amz-Algorithm")
  valid_613928 = validateParameter(valid_613928, JString, required = false,
                                 default = nil)
  if valid_613928 != nil:
    section.add "X-Amz-Algorithm", valid_613928
  var valid_613929 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613929 = validateParameter(valid_613929, JString, required = false,
                                 default = nil)
  if valid_613929 != nil:
    section.add "X-Amz-SignedHeaders", valid_613929
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListSubscriptionsByTopic</code> request.
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic for which you wish to find subscriptions.
  section = newJObject()
  var valid_613930 = formData.getOrDefault("NextToken")
  valid_613930 = validateParameter(valid_613930, JString, required = false,
                                 default = nil)
  if valid_613930 != nil:
    section.add "NextToken", valid_613930
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_613931 = formData.getOrDefault("TopicArn")
  valid_613931 = validateParameter(valid_613931, JString, required = true,
                                 default = nil)
  if valid_613931 != nil:
    section.add "TopicArn", valid_613931
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613932: Call_PostListSubscriptionsByTopic_613918; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_613932.validator(path, query, header, formData, body)
  let scheme = call_613932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613932.url(scheme.get, call_613932.host, call_613932.base,
                         call_613932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613932, url, valid)

proc call*(call_613933: Call_PostListSubscriptionsByTopic_613918; TopicArn: string;
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
  var query_613934 = newJObject()
  var formData_613935 = newJObject()
  add(formData_613935, "NextToken", newJString(NextToken))
  add(formData_613935, "TopicArn", newJString(TopicArn))
  add(query_613934, "Action", newJString(Action))
  add(query_613934, "Version", newJString(Version))
  result = call_613933.call(nil, query_613934, nil, formData_613935, nil)

var postListSubscriptionsByTopic* = Call_PostListSubscriptionsByTopic_613918(
    name: "postListSubscriptionsByTopic", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptionsByTopic",
    validator: validate_PostListSubscriptionsByTopic_613919, base: "/",
    url: url_PostListSubscriptionsByTopic_613920,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListSubscriptionsByTopic_613901 = ref object of OpenApiRestCall_612658
proc url_GetListSubscriptionsByTopic_613903(protocol: Scheme; host: string;
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

proc validate_GetListSubscriptionsByTopic_613902(path: JsonNode; query: JsonNode;
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
  var valid_613904 = query.getOrDefault("NextToken")
  valid_613904 = validateParameter(valid_613904, JString, required = false,
                                 default = nil)
  if valid_613904 != nil:
    section.add "NextToken", valid_613904
  var valid_613905 = query.getOrDefault("Action")
  valid_613905 = validateParameter(valid_613905, JString, required = true, default = newJString(
      "ListSubscriptionsByTopic"))
  if valid_613905 != nil:
    section.add "Action", valid_613905
  var valid_613906 = query.getOrDefault("Version")
  valid_613906 = validateParameter(valid_613906, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613906 != nil:
    section.add "Version", valid_613906
  var valid_613907 = query.getOrDefault("TopicArn")
  valid_613907 = validateParameter(valid_613907, JString, required = true,
                                 default = nil)
  if valid_613907 != nil:
    section.add "TopicArn", valid_613907
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613908 = header.getOrDefault("X-Amz-Signature")
  valid_613908 = validateParameter(valid_613908, JString, required = false,
                                 default = nil)
  if valid_613908 != nil:
    section.add "X-Amz-Signature", valid_613908
  var valid_613909 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613909 = validateParameter(valid_613909, JString, required = false,
                                 default = nil)
  if valid_613909 != nil:
    section.add "X-Amz-Content-Sha256", valid_613909
  var valid_613910 = header.getOrDefault("X-Amz-Date")
  valid_613910 = validateParameter(valid_613910, JString, required = false,
                                 default = nil)
  if valid_613910 != nil:
    section.add "X-Amz-Date", valid_613910
  var valid_613911 = header.getOrDefault("X-Amz-Credential")
  valid_613911 = validateParameter(valid_613911, JString, required = false,
                                 default = nil)
  if valid_613911 != nil:
    section.add "X-Amz-Credential", valid_613911
  var valid_613912 = header.getOrDefault("X-Amz-Security-Token")
  valid_613912 = validateParameter(valid_613912, JString, required = false,
                                 default = nil)
  if valid_613912 != nil:
    section.add "X-Amz-Security-Token", valid_613912
  var valid_613913 = header.getOrDefault("X-Amz-Algorithm")
  valid_613913 = validateParameter(valid_613913, JString, required = false,
                                 default = nil)
  if valid_613913 != nil:
    section.add "X-Amz-Algorithm", valid_613913
  var valid_613914 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613914 = validateParameter(valid_613914, JString, required = false,
                                 default = nil)
  if valid_613914 != nil:
    section.add "X-Amz-SignedHeaders", valid_613914
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613915: Call_GetListSubscriptionsByTopic_613901; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_613915.validator(path, query, header, formData, body)
  let scheme = call_613915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613915.url(scheme.get, call_613915.host, call_613915.base,
                         call_613915.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613915, url, valid)

proc call*(call_613916: Call_GetListSubscriptionsByTopic_613901; TopicArn: string;
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
  var query_613917 = newJObject()
  add(query_613917, "NextToken", newJString(NextToken))
  add(query_613917, "Action", newJString(Action))
  add(query_613917, "Version", newJString(Version))
  add(query_613917, "TopicArn", newJString(TopicArn))
  result = call_613916.call(nil, query_613917, nil, nil, nil)

var getListSubscriptionsByTopic* = Call_GetListSubscriptionsByTopic_613901(
    name: "getListSubscriptionsByTopic", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptionsByTopic",
    validator: validate_GetListSubscriptionsByTopic_613902, base: "/",
    url: url_GetListSubscriptionsByTopic_613903,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_613952 = ref object of OpenApiRestCall_612658
proc url_PostListTagsForResource_613954(protocol: Scheme; host: string; base: string;
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

proc validate_PostListTagsForResource_613953(path: JsonNode; query: JsonNode;
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
  var valid_613955 = query.getOrDefault("Action")
  valid_613955 = validateParameter(valid_613955, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_613955 != nil:
    section.add "Action", valid_613955
  var valid_613956 = query.getOrDefault("Version")
  valid_613956 = validateParameter(valid_613956, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613956 != nil:
    section.add "Version", valid_613956
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613957 = header.getOrDefault("X-Amz-Signature")
  valid_613957 = validateParameter(valid_613957, JString, required = false,
                                 default = nil)
  if valid_613957 != nil:
    section.add "X-Amz-Signature", valid_613957
  var valid_613958 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613958 = validateParameter(valid_613958, JString, required = false,
                                 default = nil)
  if valid_613958 != nil:
    section.add "X-Amz-Content-Sha256", valid_613958
  var valid_613959 = header.getOrDefault("X-Amz-Date")
  valid_613959 = validateParameter(valid_613959, JString, required = false,
                                 default = nil)
  if valid_613959 != nil:
    section.add "X-Amz-Date", valid_613959
  var valid_613960 = header.getOrDefault("X-Amz-Credential")
  valid_613960 = validateParameter(valid_613960, JString, required = false,
                                 default = nil)
  if valid_613960 != nil:
    section.add "X-Amz-Credential", valid_613960
  var valid_613961 = header.getOrDefault("X-Amz-Security-Token")
  valid_613961 = validateParameter(valid_613961, JString, required = false,
                                 default = nil)
  if valid_613961 != nil:
    section.add "X-Amz-Security-Token", valid_613961
  var valid_613962 = header.getOrDefault("X-Amz-Algorithm")
  valid_613962 = validateParameter(valid_613962, JString, required = false,
                                 default = nil)
  if valid_613962 != nil:
    section.add "X-Amz-Algorithm", valid_613962
  var valid_613963 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613963 = validateParameter(valid_613963, JString, required = false,
                                 default = nil)
  if valid_613963 != nil:
    section.add "X-Amz-SignedHeaders", valid_613963
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic for which to list tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_613964 = formData.getOrDefault("ResourceArn")
  valid_613964 = validateParameter(valid_613964, JString, required = true,
                                 default = nil)
  if valid_613964 != nil:
    section.add "ResourceArn", valid_613964
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613965: Call_PostListTagsForResource_613952; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ## 
  let valid = call_613965.validator(path, query, header, formData, body)
  let scheme = call_613965.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613965.url(scheme.get, call_613965.host, call_613965.base,
                         call_613965.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613965, url, valid)

proc call*(call_613966: Call_PostListTagsForResource_613952; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-03-31"): Recallable =
  ## postListTagsForResource
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic for which to list tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613967 = newJObject()
  var formData_613968 = newJObject()
  add(formData_613968, "ResourceArn", newJString(ResourceArn))
  add(query_613967, "Action", newJString(Action))
  add(query_613967, "Version", newJString(Version))
  result = call_613966.call(nil, query_613967, nil, formData_613968, nil)

var postListTagsForResource* = Call_PostListTagsForResource_613952(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_613953, base: "/",
    url: url_PostListTagsForResource_613954, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_613936 = ref object of OpenApiRestCall_612658
proc url_GetListTagsForResource_613938(protocol: Scheme; host: string; base: string;
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

proc validate_GetListTagsForResource_613937(path: JsonNode; query: JsonNode;
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
  var valid_613939 = query.getOrDefault("ResourceArn")
  valid_613939 = validateParameter(valid_613939, JString, required = true,
                                 default = nil)
  if valid_613939 != nil:
    section.add "ResourceArn", valid_613939
  var valid_613940 = query.getOrDefault("Action")
  valid_613940 = validateParameter(valid_613940, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_613940 != nil:
    section.add "Action", valid_613940
  var valid_613941 = query.getOrDefault("Version")
  valid_613941 = validateParameter(valid_613941, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613941 != nil:
    section.add "Version", valid_613941
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613942 = header.getOrDefault("X-Amz-Signature")
  valid_613942 = validateParameter(valid_613942, JString, required = false,
                                 default = nil)
  if valid_613942 != nil:
    section.add "X-Amz-Signature", valid_613942
  var valid_613943 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613943 = validateParameter(valid_613943, JString, required = false,
                                 default = nil)
  if valid_613943 != nil:
    section.add "X-Amz-Content-Sha256", valid_613943
  var valid_613944 = header.getOrDefault("X-Amz-Date")
  valid_613944 = validateParameter(valid_613944, JString, required = false,
                                 default = nil)
  if valid_613944 != nil:
    section.add "X-Amz-Date", valid_613944
  var valid_613945 = header.getOrDefault("X-Amz-Credential")
  valid_613945 = validateParameter(valid_613945, JString, required = false,
                                 default = nil)
  if valid_613945 != nil:
    section.add "X-Amz-Credential", valid_613945
  var valid_613946 = header.getOrDefault("X-Amz-Security-Token")
  valid_613946 = validateParameter(valid_613946, JString, required = false,
                                 default = nil)
  if valid_613946 != nil:
    section.add "X-Amz-Security-Token", valid_613946
  var valid_613947 = header.getOrDefault("X-Amz-Algorithm")
  valid_613947 = validateParameter(valid_613947, JString, required = false,
                                 default = nil)
  if valid_613947 != nil:
    section.add "X-Amz-Algorithm", valid_613947
  var valid_613948 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613948 = validateParameter(valid_613948, JString, required = false,
                                 default = nil)
  if valid_613948 != nil:
    section.add "X-Amz-SignedHeaders", valid_613948
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613949: Call_GetListTagsForResource_613936; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ## 
  let valid = call_613949.validator(path, query, header, formData, body)
  let scheme = call_613949.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613949.url(scheme.get, call_613949.host, call_613949.base,
                         call_613949.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613949, url, valid)

proc call*(call_613950: Call_GetListTagsForResource_613936; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-03-31"): Recallable =
  ## getListTagsForResource
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic for which to list tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613951 = newJObject()
  add(query_613951, "ResourceArn", newJString(ResourceArn))
  add(query_613951, "Action", newJString(Action))
  add(query_613951, "Version", newJString(Version))
  result = call_613950.call(nil, query_613951, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_613936(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_613937, base: "/",
    url: url_GetListTagsForResource_613938, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTopics_613985 = ref object of OpenApiRestCall_612658
proc url_PostListTopics_613987(protocol: Scheme; host: string; base: string;
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

proc validate_PostListTopics_613986(path: JsonNode; query: JsonNode;
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
  var valid_613988 = query.getOrDefault("Action")
  valid_613988 = validateParameter(valid_613988, JString, required = true,
                                 default = newJString("ListTopics"))
  if valid_613988 != nil:
    section.add "Action", valid_613988
  var valid_613989 = query.getOrDefault("Version")
  valid_613989 = validateParameter(valid_613989, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613989 != nil:
    section.add "Version", valid_613989
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613990 = header.getOrDefault("X-Amz-Signature")
  valid_613990 = validateParameter(valid_613990, JString, required = false,
                                 default = nil)
  if valid_613990 != nil:
    section.add "X-Amz-Signature", valid_613990
  var valid_613991 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613991 = validateParameter(valid_613991, JString, required = false,
                                 default = nil)
  if valid_613991 != nil:
    section.add "X-Amz-Content-Sha256", valid_613991
  var valid_613992 = header.getOrDefault("X-Amz-Date")
  valid_613992 = validateParameter(valid_613992, JString, required = false,
                                 default = nil)
  if valid_613992 != nil:
    section.add "X-Amz-Date", valid_613992
  var valid_613993 = header.getOrDefault("X-Amz-Credential")
  valid_613993 = validateParameter(valid_613993, JString, required = false,
                                 default = nil)
  if valid_613993 != nil:
    section.add "X-Amz-Credential", valid_613993
  var valid_613994 = header.getOrDefault("X-Amz-Security-Token")
  valid_613994 = validateParameter(valid_613994, JString, required = false,
                                 default = nil)
  if valid_613994 != nil:
    section.add "X-Amz-Security-Token", valid_613994
  var valid_613995 = header.getOrDefault("X-Amz-Algorithm")
  valid_613995 = validateParameter(valid_613995, JString, required = false,
                                 default = nil)
  if valid_613995 != nil:
    section.add "X-Amz-Algorithm", valid_613995
  var valid_613996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613996 = validateParameter(valid_613996, JString, required = false,
                                 default = nil)
  if valid_613996 != nil:
    section.add "X-Amz-SignedHeaders", valid_613996
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListTopics</code> request.
  section = newJObject()
  var valid_613997 = formData.getOrDefault("NextToken")
  valid_613997 = validateParameter(valid_613997, JString, required = false,
                                 default = nil)
  if valid_613997 != nil:
    section.add "NextToken", valid_613997
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613998: Call_PostListTopics_613985; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_613998.validator(path, query, header, formData, body)
  let scheme = call_613998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613998.url(scheme.get, call_613998.host, call_613998.base,
                         call_613998.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613998, url, valid)

proc call*(call_613999: Call_PostListTopics_613985; NextToken: string = "";
          Action: string = "ListTopics"; Version: string = "2010-03-31"): Recallable =
  ## postListTopics
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListTopics</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614000 = newJObject()
  var formData_614001 = newJObject()
  add(formData_614001, "NextToken", newJString(NextToken))
  add(query_614000, "Action", newJString(Action))
  add(query_614000, "Version", newJString(Version))
  result = call_613999.call(nil, query_614000, nil, formData_614001, nil)

var postListTopics* = Call_PostListTopics_613985(name: "postListTopics",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=ListTopics", validator: validate_PostListTopics_613986,
    base: "/", url: url_PostListTopics_613987, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTopics_613969 = ref object of OpenApiRestCall_612658
proc url_GetListTopics_613971(protocol: Scheme; host: string; base: string;
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

proc validate_GetListTopics_613970(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613972 = query.getOrDefault("NextToken")
  valid_613972 = validateParameter(valid_613972, JString, required = false,
                                 default = nil)
  if valid_613972 != nil:
    section.add "NextToken", valid_613972
  var valid_613973 = query.getOrDefault("Action")
  valid_613973 = validateParameter(valid_613973, JString, required = true,
                                 default = newJString("ListTopics"))
  if valid_613973 != nil:
    section.add "Action", valid_613973
  var valid_613974 = query.getOrDefault("Version")
  valid_613974 = validateParameter(valid_613974, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_613974 != nil:
    section.add "Version", valid_613974
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613975 = header.getOrDefault("X-Amz-Signature")
  valid_613975 = validateParameter(valid_613975, JString, required = false,
                                 default = nil)
  if valid_613975 != nil:
    section.add "X-Amz-Signature", valid_613975
  var valid_613976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613976 = validateParameter(valid_613976, JString, required = false,
                                 default = nil)
  if valid_613976 != nil:
    section.add "X-Amz-Content-Sha256", valid_613976
  var valid_613977 = header.getOrDefault("X-Amz-Date")
  valid_613977 = validateParameter(valid_613977, JString, required = false,
                                 default = nil)
  if valid_613977 != nil:
    section.add "X-Amz-Date", valid_613977
  var valid_613978 = header.getOrDefault("X-Amz-Credential")
  valid_613978 = validateParameter(valid_613978, JString, required = false,
                                 default = nil)
  if valid_613978 != nil:
    section.add "X-Amz-Credential", valid_613978
  var valid_613979 = header.getOrDefault("X-Amz-Security-Token")
  valid_613979 = validateParameter(valid_613979, JString, required = false,
                                 default = nil)
  if valid_613979 != nil:
    section.add "X-Amz-Security-Token", valid_613979
  var valid_613980 = header.getOrDefault("X-Amz-Algorithm")
  valid_613980 = validateParameter(valid_613980, JString, required = false,
                                 default = nil)
  if valid_613980 != nil:
    section.add "X-Amz-Algorithm", valid_613980
  var valid_613981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613981 = validateParameter(valid_613981, JString, required = false,
                                 default = nil)
  if valid_613981 != nil:
    section.add "X-Amz-SignedHeaders", valid_613981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613982: Call_GetListTopics_613969; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_613982.validator(path, query, header, formData, body)
  let scheme = call_613982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613982.url(scheme.get, call_613982.host, call_613982.base,
                         call_613982.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613982, url, valid)

proc call*(call_613983: Call_GetListTopics_613969; NextToken: string = "";
          Action: string = "ListTopics"; Version: string = "2010-03-31"): Recallable =
  ## getListTopics
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListTopics</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613984 = newJObject()
  add(query_613984, "NextToken", newJString(NextToken))
  add(query_613984, "Action", newJString(Action))
  add(query_613984, "Version", newJString(Version))
  result = call_613983.call(nil, query_613984, nil, nil, nil)

var getListTopics* = Call_GetListTopics_613969(name: "getListTopics",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=ListTopics", validator: validate_GetListTopics_613970,
    base: "/", url: url_GetListTopics_613971, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostOptInPhoneNumber_614018 = ref object of OpenApiRestCall_612658
proc url_PostOptInPhoneNumber_614020(protocol: Scheme; host: string; base: string;
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

proc validate_PostOptInPhoneNumber_614019(path: JsonNode; query: JsonNode;
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
  var valid_614021 = query.getOrDefault("Action")
  valid_614021 = validateParameter(valid_614021, JString, required = true,
                                 default = newJString("OptInPhoneNumber"))
  if valid_614021 != nil:
    section.add "Action", valid_614021
  var valid_614022 = query.getOrDefault("Version")
  valid_614022 = validateParameter(valid_614022, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_614022 != nil:
    section.add "Version", valid_614022
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614023 = header.getOrDefault("X-Amz-Signature")
  valid_614023 = validateParameter(valid_614023, JString, required = false,
                                 default = nil)
  if valid_614023 != nil:
    section.add "X-Amz-Signature", valid_614023
  var valid_614024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614024 = validateParameter(valid_614024, JString, required = false,
                                 default = nil)
  if valid_614024 != nil:
    section.add "X-Amz-Content-Sha256", valid_614024
  var valid_614025 = header.getOrDefault("X-Amz-Date")
  valid_614025 = validateParameter(valid_614025, JString, required = false,
                                 default = nil)
  if valid_614025 != nil:
    section.add "X-Amz-Date", valid_614025
  var valid_614026 = header.getOrDefault("X-Amz-Credential")
  valid_614026 = validateParameter(valid_614026, JString, required = false,
                                 default = nil)
  if valid_614026 != nil:
    section.add "X-Amz-Credential", valid_614026
  var valid_614027 = header.getOrDefault("X-Amz-Security-Token")
  valid_614027 = validateParameter(valid_614027, JString, required = false,
                                 default = nil)
  if valid_614027 != nil:
    section.add "X-Amz-Security-Token", valid_614027
  var valid_614028 = header.getOrDefault("X-Amz-Algorithm")
  valid_614028 = validateParameter(valid_614028, JString, required = false,
                                 default = nil)
  if valid_614028 != nil:
    section.add "X-Amz-Algorithm", valid_614028
  var valid_614029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614029 = validateParameter(valid_614029, JString, required = false,
                                 default = nil)
  if valid_614029 != nil:
    section.add "X-Amz-SignedHeaders", valid_614029
  result.add "header", section
  ## parameters in `formData` object:
  ##   phoneNumber: JString (required)
  ##              : The phone number to opt in.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `phoneNumber` field"
  var valid_614030 = formData.getOrDefault("phoneNumber")
  valid_614030 = validateParameter(valid_614030, JString, required = true,
                                 default = nil)
  if valid_614030 != nil:
    section.add "phoneNumber", valid_614030
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614031: Call_PostOptInPhoneNumber_614018; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ## 
  let valid = call_614031.validator(path, query, header, formData, body)
  let scheme = call_614031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614031.url(scheme.get, call_614031.host, call_614031.base,
                         call_614031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614031, url, valid)

proc call*(call_614032: Call_PostOptInPhoneNumber_614018; phoneNumber: string;
          Action: string = "OptInPhoneNumber"; Version: string = "2010-03-31"): Recallable =
  ## postOptInPhoneNumber
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number to opt in.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614033 = newJObject()
  var formData_614034 = newJObject()
  add(formData_614034, "phoneNumber", newJString(phoneNumber))
  add(query_614033, "Action", newJString(Action))
  add(query_614033, "Version", newJString(Version))
  result = call_614032.call(nil, query_614033, nil, formData_614034, nil)

var postOptInPhoneNumber* = Call_PostOptInPhoneNumber_614018(
    name: "postOptInPhoneNumber", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=OptInPhoneNumber",
    validator: validate_PostOptInPhoneNumber_614019, base: "/",
    url: url_PostOptInPhoneNumber_614020, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOptInPhoneNumber_614002 = ref object of OpenApiRestCall_612658
proc url_GetOptInPhoneNumber_614004(protocol: Scheme; host: string; base: string;
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

proc validate_GetOptInPhoneNumber_614003(path: JsonNode; query: JsonNode;
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
  var valid_614005 = query.getOrDefault("phoneNumber")
  valid_614005 = validateParameter(valid_614005, JString, required = true,
                                 default = nil)
  if valid_614005 != nil:
    section.add "phoneNumber", valid_614005
  var valid_614006 = query.getOrDefault("Action")
  valid_614006 = validateParameter(valid_614006, JString, required = true,
                                 default = newJString("OptInPhoneNumber"))
  if valid_614006 != nil:
    section.add "Action", valid_614006
  var valid_614007 = query.getOrDefault("Version")
  valid_614007 = validateParameter(valid_614007, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_614007 != nil:
    section.add "Version", valid_614007
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614008 = header.getOrDefault("X-Amz-Signature")
  valid_614008 = validateParameter(valid_614008, JString, required = false,
                                 default = nil)
  if valid_614008 != nil:
    section.add "X-Amz-Signature", valid_614008
  var valid_614009 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614009 = validateParameter(valid_614009, JString, required = false,
                                 default = nil)
  if valid_614009 != nil:
    section.add "X-Amz-Content-Sha256", valid_614009
  var valid_614010 = header.getOrDefault("X-Amz-Date")
  valid_614010 = validateParameter(valid_614010, JString, required = false,
                                 default = nil)
  if valid_614010 != nil:
    section.add "X-Amz-Date", valid_614010
  var valid_614011 = header.getOrDefault("X-Amz-Credential")
  valid_614011 = validateParameter(valid_614011, JString, required = false,
                                 default = nil)
  if valid_614011 != nil:
    section.add "X-Amz-Credential", valid_614011
  var valid_614012 = header.getOrDefault("X-Amz-Security-Token")
  valid_614012 = validateParameter(valid_614012, JString, required = false,
                                 default = nil)
  if valid_614012 != nil:
    section.add "X-Amz-Security-Token", valid_614012
  var valid_614013 = header.getOrDefault("X-Amz-Algorithm")
  valid_614013 = validateParameter(valid_614013, JString, required = false,
                                 default = nil)
  if valid_614013 != nil:
    section.add "X-Amz-Algorithm", valid_614013
  var valid_614014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614014 = validateParameter(valid_614014, JString, required = false,
                                 default = nil)
  if valid_614014 != nil:
    section.add "X-Amz-SignedHeaders", valid_614014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614015: Call_GetOptInPhoneNumber_614002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ## 
  let valid = call_614015.validator(path, query, header, formData, body)
  let scheme = call_614015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614015.url(scheme.get, call_614015.host, call_614015.base,
                         call_614015.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614015, url, valid)

proc call*(call_614016: Call_GetOptInPhoneNumber_614002; phoneNumber: string;
          Action: string = "OptInPhoneNumber"; Version: string = "2010-03-31"): Recallable =
  ## getOptInPhoneNumber
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number to opt in.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614017 = newJObject()
  add(query_614017, "phoneNumber", newJString(phoneNumber))
  add(query_614017, "Action", newJString(Action))
  add(query_614017, "Version", newJString(Version))
  result = call_614016.call(nil, query_614017, nil, nil, nil)

var getOptInPhoneNumber* = Call_GetOptInPhoneNumber_614002(
    name: "getOptInPhoneNumber", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=OptInPhoneNumber",
    validator: validate_GetOptInPhoneNumber_614003, base: "/",
    url: url_GetOptInPhoneNumber_614004, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPublish_614062 = ref object of OpenApiRestCall_612658
proc url_PostPublish_614064(protocol: Scheme; host: string; base: string;
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

proc validate_PostPublish_614063(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614065 = query.getOrDefault("Action")
  valid_614065 = validateParameter(valid_614065, JString, required = true,
                                 default = newJString("Publish"))
  if valid_614065 != nil:
    section.add "Action", valid_614065
  var valid_614066 = query.getOrDefault("Version")
  valid_614066 = validateParameter(valid_614066, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_614066 != nil:
    section.add "Version", valid_614066
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614067 = header.getOrDefault("X-Amz-Signature")
  valid_614067 = validateParameter(valid_614067, JString, required = false,
                                 default = nil)
  if valid_614067 != nil:
    section.add "X-Amz-Signature", valid_614067
  var valid_614068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614068 = validateParameter(valid_614068, JString, required = false,
                                 default = nil)
  if valid_614068 != nil:
    section.add "X-Amz-Content-Sha256", valid_614068
  var valid_614069 = header.getOrDefault("X-Amz-Date")
  valid_614069 = validateParameter(valid_614069, JString, required = false,
                                 default = nil)
  if valid_614069 != nil:
    section.add "X-Amz-Date", valid_614069
  var valid_614070 = header.getOrDefault("X-Amz-Credential")
  valid_614070 = validateParameter(valid_614070, JString, required = false,
                                 default = nil)
  if valid_614070 != nil:
    section.add "X-Amz-Credential", valid_614070
  var valid_614071 = header.getOrDefault("X-Amz-Security-Token")
  valid_614071 = validateParameter(valid_614071, JString, required = false,
                                 default = nil)
  if valid_614071 != nil:
    section.add "X-Amz-Security-Token", valid_614071
  var valid_614072 = header.getOrDefault("X-Amz-Algorithm")
  valid_614072 = validateParameter(valid_614072, JString, required = false,
                                 default = nil)
  if valid_614072 != nil:
    section.add "X-Amz-Algorithm", valid_614072
  var valid_614073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614073 = validateParameter(valid_614073, JString, required = false,
                                 default = nil)
  if valid_614073 != nil:
    section.add "X-Amz-SignedHeaders", valid_614073
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
  var valid_614074 = formData.getOrDefault("MessageAttributes.1.key")
  valid_614074 = validateParameter(valid_614074, JString, required = false,
                                 default = nil)
  if valid_614074 != nil:
    section.add "MessageAttributes.1.key", valid_614074
  var valid_614075 = formData.getOrDefault("PhoneNumber")
  valid_614075 = validateParameter(valid_614075, JString, required = false,
                                 default = nil)
  if valid_614075 != nil:
    section.add "PhoneNumber", valid_614075
  var valid_614076 = formData.getOrDefault("MessageAttributes.2.value")
  valid_614076 = validateParameter(valid_614076, JString, required = false,
                                 default = nil)
  if valid_614076 != nil:
    section.add "MessageAttributes.2.value", valid_614076
  var valid_614077 = formData.getOrDefault("Subject")
  valid_614077 = validateParameter(valid_614077, JString, required = false,
                                 default = nil)
  if valid_614077 != nil:
    section.add "Subject", valid_614077
  var valid_614078 = formData.getOrDefault("MessageAttributes.0.value")
  valid_614078 = validateParameter(valid_614078, JString, required = false,
                                 default = nil)
  if valid_614078 != nil:
    section.add "MessageAttributes.0.value", valid_614078
  var valid_614079 = formData.getOrDefault("MessageAttributes.0.key")
  valid_614079 = validateParameter(valid_614079, JString, required = false,
                                 default = nil)
  if valid_614079 != nil:
    section.add "MessageAttributes.0.key", valid_614079
  var valid_614080 = formData.getOrDefault("MessageAttributes.2.key")
  valid_614080 = validateParameter(valid_614080, JString, required = false,
                                 default = nil)
  if valid_614080 != nil:
    section.add "MessageAttributes.2.key", valid_614080
  assert formData != nil,
        "formData argument is necessary due to required `Message` field"
  var valid_614081 = formData.getOrDefault("Message")
  valid_614081 = validateParameter(valid_614081, JString, required = true,
                                 default = nil)
  if valid_614081 != nil:
    section.add "Message", valid_614081
  var valid_614082 = formData.getOrDefault("TopicArn")
  valid_614082 = validateParameter(valid_614082, JString, required = false,
                                 default = nil)
  if valid_614082 != nil:
    section.add "TopicArn", valid_614082
  var valid_614083 = formData.getOrDefault("MessageStructure")
  valid_614083 = validateParameter(valid_614083, JString, required = false,
                                 default = nil)
  if valid_614083 != nil:
    section.add "MessageStructure", valid_614083
  var valid_614084 = formData.getOrDefault("MessageAttributes.1.value")
  valid_614084 = validateParameter(valid_614084, JString, required = false,
                                 default = nil)
  if valid_614084 != nil:
    section.add "MessageAttributes.1.value", valid_614084
  var valid_614085 = formData.getOrDefault("TargetArn")
  valid_614085 = validateParameter(valid_614085, JString, required = false,
                                 default = nil)
  if valid_614085 != nil:
    section.add "TargetArn", valid_614085
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614086: Call_PostPublish_614062; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  let valid = call_614086.validator(path, query, header, formData, body)
  let scheme = call_614086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614086.url(scheme.get, call_614086.host, call_614086.base,
                         call_614086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614086, url, valid)

proc call*(call_614087: Call_PostPublish_614062; Message: string;
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
  var query_614088 = newJObject()
  var formData_614089 = newJObject()
  add(formData_614089, "MessageAttributes.1.key",
      newJString(MessageAttributes1Key))
  add(formData_614089, "PhoneNumber", newJString(PhoneNumber))
  add(formData_614089, "MessageAttributes.2.value",
      newJString(MessageAttributes2Value))
  add(formData_614089, "Subject", newJString(Subject))
  add(formData_614089, "MessageAttributes.0.value",
      newJString(MessageAttributes0Value))
  add(formData_614089, "MessageAttributes.0.key",
      newJString(MessageAttributes0Key))
  add(formData_614089, "MessageAttributes.2.key",
      newJString(MessageAttributes2Key))
  add(formData_614089, "Message", newJString(Message))
  add(formData_614089, "TopicArn", newJString(TopicArn))
  add(query_614088, "Action", newJString(Action))
  add(formData_614089, "MessageStructure", newJString(MessageStructure))
  add(formData_614089, "MessageAttributes.1.value",
      newJString(MessageAttributes1Value))
  add(formData_614089, "TargetArn", newJString(TargetArn))
  add(query_614088, "Version", newJString(Version))
  result = call_614087.call(nil, query_614088, nil, formData_614089, nil)

var postPublish* = Call_PostPublish_614062(name: "postPublish",
                                        meth: HttpMethod.HttpPost,
                                        host: "sns.amazonaws.com",
                                        route: "/#Action=Publish",
                                        validator: validate_PostPublish_614063,
                                        base: "/", url: url_PostPublish_614064,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublish_614035 = ref object of OpenApiRestCall_612658
proc url_GetPublish_614037(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetPublish_614036(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614038 = query.getOrDefault("PhoneNumber")
  valid_614038 = validateParameter(valid_614038, JString, required = false,
                                 default = nil)
  if valid_614038 != nil:
    section.add "PhoneNumber", valid_614038
  var valid_614039 = query.getOrDefault("MessageStructure")
  valid_614039 = validateParameter(valid_614039, JString, required = false,
                                 default = nil)
  if valid_614039 != nil:
    section.add "MessageStructure", valid_614039
  var valid_614040 = query.getOrDefault("MessageAttributes.0.value")
  valid_614040 = validateParameter(valid_614040, JString, required = false,
                                 default = nil)
  if valid_614040 != nil:
    section.add "MessageAttributes.0.value", valid_614040
  var valid_614041 = query.getOrDefault("MessageAttributes.2.key")
  valid_614041 = validateParameter(valid_614041, JString, required = false,
                                 default = nil)
  if valid_614041 != nil:
    section.add "MessageAttributes.2.key", valid_614041
  assert query != nil, "query argument is necessary due to required `Message` field"
  var valid_614042 = query.getOrDefault("Message")
  valid_614042 = validateParameter(valid_614042, JString, required = true,
                                 default = nil)
  if valid_614042 != nil:
    section.add "Message", valid_614042
  var valid_614043 = query.getOrDefault("MessageAttributes.2.value")
  valid_614043 = validateParameter(valid_614043, JString, required = false,
                                 default = nil)
  if valid_614043 != nil:
    section.add "MessageAttributes.2.value", valid_614043
  var valid_614044 = query.getOrDefault("Action")
  valid_614044 = validateParameter(valid_614044, JString, required = true,
                                 default = newJString("Publish"))
  if valid_614044 != nil:
    section.add "Action", valid_614044
  var valid_614045 = query.getOrDefault("MessageAttributes.1.key")
  valid_614045 = validateParameter(valid_614045, JString, required = false,
                                 default = nil)
  if valid_614045 != nil:
    section.add "MessageAttributes.1.key", valid_614045
  var valid_614046 = query.getOrDefault("MessageAttributes.0.key")
  valid_614046 = validateParameter(valid_614046, JString, required = false,
                                 default = nil)
  if valid_614046 != nil:
    section.add "MessageAttributes.0.key", valid_614046
  var valid_614047 = query.getOrDefault("Subject")
  valid_614047 = validateParameter(valid_614047, JString, required = false,
                                 default = nil)
  if valid_614047 != nil:
    section.add "Subject", valid_614047
  var valid_614048 = query.getOrDefault("MessageAttributes.1.value")
  valid_614048 = validateParameter(valid_614048, JString, required = false,
                                 default = nil)
  if valid_614048 != nil:
    section.add "MessageAttributes.1.value", valid_614048
  var valid_614049 = query.getOrDefault("Version")
  valid_614049 = validateParameter(valid_614049, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_614049 != nil:
    section.add "Version", valid_614049
  var valid_614050 = query.getOrDefault("TargetArn")
  valid_614050 = validateParameter(valid_614050, JString, required = false,
                                 default = nil)
  if valid_614050 != nil:
    section.add "TargetArn", valid_614050
  var valid_614051 = query.getOrDefault("TopicArn")
  valid_614051 = validateParameter(valid_614051, JString, required = false,
                                 default = nil)
  if valid_614051 != nil:
    section.add "TopicArn", valid_614051
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614052 = header.getOrDefault("X-Amz-Signature")
  valid_614052 = validateParameter(valid_614052, JString, required = false,
                                 default = nil)
  if valid_614052 != nil:
    section.add "X-Amz-Signature", valid_614052
  var valid_614053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614053 = validateParameter(valid_614053, JString, required = false,
                                 default = nil)
  if valid_614053 != nil:
    section.add "X-Amz-Content-Sha256", valid_614053
  var valid_614054 = header.getOrDefault("X-Amz-Date")
  valid_614054 = validateParameter(valid_614054, JString, required = false,
                                 default = nil)
  if valid_614054 != nil:
    section.add "X-Amz-Date", valid_614054
  var valid_614055 = header.getOrDefault("X-Amz-Credential")
  valid_614055 = validateParameter(valid_614055, JString, required = false,
                                 default = nil)
  if valid_614055 != nil:
    section.add "X-Amz-Credential", valid_614055
  var valid_614056 = header.getOrDefault("X-Amz-Security-Token")
  valid_614056 = validateParameter(valid_614056, JString, required = false,
                                 default = nil)
  if valid_614056 != nil:
    section.add "X-Amz-Security-Token", valid_614056
  var valid_614057 = header.getOrDefault("X-Amz-Algorithm")
  valid_614057 = validateParameter(valid_614057, JString, required = false,
                                 default = nil)
  if valid_614057 != nil:
    section.add "X-Amz-Algorithm", valid_614057
  var valid_614058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614058 = validateParameter(valid_614058, JString, required = false,
                                 default = nil)
  if valid_614058 != nil:
    section.add "X-Amz-SignedHeaders", valid_614058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614059: Call_GetPublish_614035; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  let valid = call_614059.validator(path, query, header, formData, body)
  let scheme = call_614059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614059.url(scheme.get, call_614059.host, call_614059.base,
                         call_614059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614059, url, valid)

proc call*(call_614060: Call_GetPublish_614035; Message: string;
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
  var query_614061 = newJObject()
  add(query_614061, "PhoneNumber", newJString(PhoneNumber))
  add(query_614061, "MessageStructure", newJString(MessageStructure))
  add(query_614061, "MessageAttributes.0.value",
      newJString(MessageAttributes0Value))
  add(query_614061, "MessageAttributes.2.key", newJString(MessageAttributes2Key))
  add(query_614061, "Message", newJString(Message))
  add(query_614061, "MessageAttributes.2.value",
      newJString(MessageAttributes2Value))
  add(query_614061, "Action", newJString(Action))
  add(query_614061, "MessageAttributes.1.key", newJString(MessageAttributes1Key))
  add(query_614061, "MessageAttributes.0.key", newJString(MessageAttributes0Key))
  add(query_614061, "Subject", newJString(Subject))
  add(query_614061, "MessageAttributes.1.value",
      newJString(MessageAttributes1Value))
  add(query_614061, "Version", newJString(Version))
  add(query_614061, "TargetArn", newJString(TargetArn))
  add(query_614061, "TopicArn", newJString(TopicArn))
  result = call_614060.call(nil, query_614061, nil, nil, nil)

var getPublish* = Call_GetPublish_614035(name: "getPublish",
                                      meth: HttpMethod.HttpGet,
                                      host: "sns.amazonaws.com",
                                      route: "/#Action=Publish",
                                      validator: validate_GetPublish_614036,
                                      base: "/", url: url_GetPublish_614037,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemovePermission_614107 = ref object of OpenApiRestCall_612658
proc url_PostRemovePermission_614109(protocol: Scheme; host: string; base: string;
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

proc validate_PostRemovePermission_614108(path: JsonNode; query: JsonNode;
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
  var valid_614110 = query.getOrDefault("Action")
  valid_614110 = validateParameter(valid_614110, JString, required = true,
                                 default = newJString("RemovePermission"))
  if valid_614110 != nil:
    section.add "Action", valid_614110
  var valid_614111 = query.getOrDefault("Version")
  valid_614111 = validateParameter(valid_614111, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_614111 != nil:
    section.add "Version", valid_614111
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614112 = header.getOrDefault("X-Amz-Signature")
  valid_614112 = validateParameter(valid_614112, JString, required = false,
                                 default = nil)
  if valid_614112 != nil:
    section.add "X-Amz-Signature", valid_614112
  var valid_614113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614113 = validateParameter(valid_614113, JString, required = false,
                                 default = nil)
  if valid_614113 != nil:
    section.add "X-Amz-Content-Sha256", valid_614113
  var valid_614114 = header.getOrDefault("X-Amz-Date")
  valid_614114 = validateParameter(valid_614114, JString, required = false,
                                 default = nil)
  if valid_614114 != nil:
    section.add "X-Amz-Date", valid_614114
  var valid_614115 = header.getOrDefault("X-Amz-Credential")
  valid_614115 = validateParameter(valid_614115, JString, required = false,
                                 default = nil)
  if valid_614115 != nil:
    section.add "X-Amz-Credential", valid_614115
  var valid_614116 = header.getOrDefault("X-Amz-Security-Token")
  valid_614116 = validateParameter(valid_614116, JString, required = false,
                                 default = nil)
  if valid_614116 != nil:
    section.add "X-Amz-Security-Token", valid_614116
  var valid_614117 = header.getOrDefault("X-Amz-Algorithm")
  valid_614117 = validateParameter(valid_614117, JString, required = false,
                                 default = nil)
  if valid_614117 != nil:
    section.add "X-Amz-Algorithm", valid_614117
  var valid_614118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614118 = validateParameter(valid_614118, JString, required = false,
                                 default = nil)
  if valid_614118 != nil:
    section.add "X-Amz-SignedHeaders", valid_614118
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Label: JString (required)
  ##        : The unique label of the statement you want to remove.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_614119 = formData.getOrDefault("TopicArn")
  valid_614119 = validateParameter(valid_614119, JString, required = true,
                                 default = nil)
  if valid_614119 != nil:
    section.add "TopicArn", valid_614119
  var valid_614120 = formData.getOrDefault("Label")
  valid_614120 = validateParameter(valid_614120, JString, required = true,
                                 default = nil)
  if valid_614120 != nil:
    section.add "Label", valid_614120
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614121: Call_PostRemovePermission_614107; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a statement from a topic's access control policy.
  ## 
  let valid = call_614121.validator(path, query, header, formData, body)
  let scheme = call_614121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614121.url(scheme.get, call_614121.host, call_614121.base,
                         call_614121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614121, url, valid)

proc call*(call_614122: Call_PostRemovePermission_614107; TopicArn: string;
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
  var query_614123 = newJObject()
  var formData_614124 = newJObject()
  add(formData_614124, "TopicArn", newJString(TopicArn))
  add(query_614123, "Action", newJString(Action))
  add(formData_614124, "Label", newJString(Label))
  add(query_614123, "Version", newJString(Version))
  result = call_614122.call(nil, query_614123, nil, formData_614124, nil)

var postRemovePermission* = Call_PostRemovePermission_614107(
    name: "postRemovePermission", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=RemovePermission",
    validator: validate_PostRemovePermission_614108, base: "/",
    url: url_PostRemovePermission_614109, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemovePermission_614090 = ref object of OpenApiRestCall_612658
proc url_GetRemovePermission_614092(protocol: Scheme; host: string; base: string;
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

proc validate_GetRemovePermission_614091(path: JsonNode; query: JsonNode;
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
  var valid_614093 = query.getOrDefault("TopicArn")
  valid_614093 = validateParameter(valid_614093, JString, required = true,
                                 default = nil)
  if valid_614093 != nil:
    section.add "TopicArn", valid_614093
  var valid_614094 = query.getOrDefault("Action")
  valid_614094 = validateParameter(valid_614094, JString, required = true,
                                 default = newJString("RemovePermission"))
  if valid_614094 != nil:
    section.add "Action", valid_614094
  var valid_614095 = query.getOrDefault("Version")
  valid_614095 = validateParameter(valid_614095, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_614095 != nil:
    section.add "Version", valid_614095
  var valid_614096 = query.getOrDefault("Label")
  valid_614096 = validateParameter(valid_614096, JString, required = true,
                                 default = nil)
  if valid_614096 != nil:
    section.add "Label", valid_614096
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614097 = header.getOrDefault("X-Amz-Signature")
  valid_614097 = validateParameter(valid_614097, JString, required = false,
                                 default = nil)
  if valid_614097 != nil:
    section.add "X-Amz-Signature", valid_614097
  var valid_614098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614098 = validateParameter(valid_614098, JString, required = false,
                                 default = nil)
  if valid_614098 != nil:
    section.add "X-Amz-Content-Sha256", valid_614098
  var valid_614099 = header.getOrDefault("X-Amz-Date")
  valid_614099 = validateParameter(valid_614099, JString, required = false,
                                 default = nil)
  if valid_614099 != nil:
    section.add "X-Amz-Date", valid_614099
  var valid_614100 = header.getOrDefault("X-Amz-Credential")
  valid_614100 = validateParameter(valid_614100, JString, required = false,
                                 default = nil)
  if valid_614100 != nil:
    section.add "X-Amz-Credential", valid_614100
  var valid_614101 = header.getOrDefault("X-Amz-Security-Token")
  valid_614101 = validateParameter(valid_614101, JString, required = false,
                                 default = nil)
  if valid_614101 != nil:
    section.add "X-Amz-Security-Token", valid_614101
  var valid_614102 = header.getOrDefault("X-Amz-Algorithm")
  valid_614102 = validateParameter(valid_614102, JString, required = false,
                                 default = nil)
  if valid_614102 != nil:
    section.add "X-Amz-Algorithm", valid_614102
  var valid_614103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614103 = validateParameter(valid_614103, JString, required = false,
                                 default = nil)
  if valid_614103 != nil:
    section.add "X-Amz-SignedHeaders", valid_614103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614104: Call_GetRemovePermission_614090; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a statement from a topic's access control policy.
  ## 
  let valid = call_614104.validator(path, query, header, formData, body)
  let scheme = call_614104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614104.url(scheme.get, call_614104.host, call_614104.base,
                         call_614104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614104, url, valid)

proc call*(call_614105: Call_GetRemovePermission_614090; TopicArn: string;
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
  var query_614106 = newJObject()
  add(query_614106, "TopicArn", newJString(TopicArn))
  add(query_614106, "Action", newJString(Action))
  add(query_614106, "Version", newJString(Version))
  add(query_614106, "Label", newJString(Label))
  result = call_614105.call(nil, query_614106, nil, nil, nil)

var getRemovePermission* = Call_GetRemovePermission_614090(
    name: "getRemovePermission", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=RemovePermission",
    validator: validate_GetRemovePermission_614091, base: "/",
    url: url_GetRemovePermission_614092, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetEndpointAttributes_614147 = ref object of OpenApiRestCall_612658
proc url_PostSetEndpointAttributes_614149(protocol: Scheme; host: string;
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

proc validate_PostSetEndpointAttributes_614148(path: JsonNode; query: JsonNode;
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
  var valid_614150 = query.getOrDefault("Action")
  valid_614150 = validateParameter(valid_614150, JString, required = true,
                                 default = newJString("SetEndpointAttributes"))
  if valid_614150 != nil:
    section.add "Action", valid_614150
  var valid_614151 = query.getOrDefault("Version")
  valid_614151 = validateParameter(valid_614151, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_614151 != nil:
    section.add "Version", valid_614151
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614152 = header.getOrDefault("X-Amz-Signature")
  valid_614152 = validateParameter(valid_614152, JString, required = false,
                                 default = nil)
  if valid_614152 != nil:
    section.add "X-Amz-Signature", valid_614152
  var valid_614153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614153 = validateParameter(valid_614153, JString, required = false,
                                 default = nil)
  if valid_614153 != nil:
    section.add "X-Amz-Content-Sha256", valid_614153
  var valid_614154 = header.getOrDefault("X-Amz-Date")
  valid_614154 = validateParameter(valid_614154, JString, required = false,
                                 default = nil)
  if valid_614154 != nil:
    section.add "X-Amz-Date", valid_614154
  var valid_614155 = header.getOrDefault("X-Amz-Credential")
  valid_614155 = validateParameter(valid_614155, JString, required = false,
                                 default = nil)
  if valid_614155 != nil:
    section.add "X-Amz-Credential", valid_614155
  var valid_614156 = header.getOrDefault("X-Amz-Security-Token")
  valid_614156 = validateParameter(valid_614156, JString, required = false,
                                 default = nil)
  if valid_614156 != nil:
    section.add "X-Amz-Security-Token", valid_614156
  var valid_614157 = header.getOrDefault("X-Amz-Algorithm")
  valid_614157 = validateParameter(valid_614157, JString, required = false,
                                 default = nil)
  if valid_614157 != nil:
    section.add "X-Amz-Algorithm", valid_614157
  var valid_614158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614158 = validateParameter(valid_614158, JString, required = false,
                                 default = nil)
  if valid_614158 != nil:
    section.add "X-Amz-SignedHeaders", valid_614158
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
  var valid_614159 = formData.getOrDefault("Attributes.0.key")
  valid_614159 = validateParameter(valid_614159, JString, required = false,
                                 default = nil)
  if valid_614159 != nil:
    section.add "Attributes.0.key", valid_614159
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_614160 = formData.getOrDefault("EndpointArn")
  valid_614160 = validateParameter(valid_614160, JString, required = true,
                                 default = nil)
  if valid_614160 != nil:
    section.add "EndpointArn", valid_614160
  var valid_614161 = formData.getOrDefault("Attributes.2.value")
  valid_614161 = validateParameter(valid_614161, JString, required = false,
                                 default = nil)
  if valid_614161 != nil:
    section.add "Attributes.2.value", valid_614161
  var valid_614162 = formData.getOrDefault("Attributes.2.key")
  valid_614162 = validateParameter(valid_614162, JString, required = false,
                                 default = nil)
  if valid_614162 != nil:
    section.add "Attributes.2.key", valid_614162
  var valid_614163 = formData.getOrDefault("Attributes.0.value")
  valid_614163 = validateParameter(valid_614163, JString, required = false,
                                 default = nil)
  if valid_614163 != nil:
    section.add "Attributes.0.value", valid_614163
  var valid_614164 = formData.getOrDefault("Attributes.1.key")
  valid_614164 = validateParameter(valid_614164, JString, required = false,
                                 default = nil)
  if valid_614164 != nil:
    section.add "Attributes.1.key", valid_614164
  var valid_614165 = formData.getOrDefault("Attributes.1.value")
  valid_614165 = validateParameter(valid_614165, JString, required = false,
                                 default = nil)
  if valid_614165 != nil:
    section.add "Attributes.1.value", valid_614165
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614166: Call_PostSetEndpointAttributes_614147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_614166.validator(path, query, header, formData, body)
  let scheme = call_614166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614166.url(scheme.get, call_614166.host, call_614166.base,
                         call_614166.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614166, url, valid)

proc call*(call_614167: Call_PostSetEndpointAttributes_614147; EndpointArn: string;
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
  var query_614168 = newJObject()
  var formData_614169 = newJObject()
  add(formData_614169, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_614169, "EndpointArn", newJString(EndpointArn))
  add(formData_614169, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_614169, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_614169, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_614169, "Attributes.1.key", newJString(Attributes1Key))
  add(query_614168, "Action", newJString(Action))
  add(query_614168, "Version", newJString(Version))
  add(formData_614169, "Attributes.1.value", newJString(Attributes1Value))
  result = call_614167.call(nil, query_614168, nil, formData_614169, nil)

var postSetEndpointAttributes* = Call_PostSetEndpointAttributes_614147(
    name: "postSetEndpointAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetEndpointAttributes",
    validator: validate_PostSetEndpointAttributes_614148, base: "/",
    url: url_PostSetEndpointAttributes_614149,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetEndpointAttributes_614125 = ref object of OpenApiRestCall_612658
proc url_GetSetEndpointAttributes_614127(protocol: Scheme; host: string;
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

proc validate_GetSetEndpointAttributes_614126(path: JsonNode; query: JsonNode;
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
  var valid_614128 = query.getOrDefault("Attributes.1.key")
  valid_614128 = validateParameter(valid_614128, JString, required = false,
                                 default = nil)
  if valid_614128 != nil:
    section.add "Attributes.1.key", valid_614128
  var valid_614129 = query.getOrDefault("Attributes.0.value")
  valid_614129 = validateParameter(valid_614129, JString, required = false,
                                 default = nil)
  if valid_614129 != nil:
    section.add "Attributes.0.value", valid_614129
  var valid_614130 = query.getOrDefault("Attributes.0.key")
  valid_614130 = validateParameter(valid_614130, JString, required = false,
                                 default = nil)
  if valid_614130 != nil:
    section.add "Attributes.0.key", valid_614130
  var valid_614131 = query.getOrDefault("Attributes.2.value")
  valid_614131 = validateParameter(valid_614131, JString, required = false,
                                 default = nil)
  if valid_614131 != nil:
    section.add "Attributes.2.value", valid_614131
  var valid_614132 = query.getOrDefault("Attributes.1.value")
  valid_614132 = validateParameter(valid_614132, JString, required = false,
                                 default = nil)
  if valid_614132 != nil:
    section.add "Attributes.1.value", valid_614132
  var valid_614133 = query.getOrDefault("Action")
  valid_614133 = validateParameter(valid_614133, JString, required = true,
                                 default = newJString("SetEndpointAttributes"))
  if valid_614133 != nil:
    section.add "Action", valid_614133
  var valid_614134 = query.getOrDefault("EndpointArn")
  valid_614134 = validateParameter(valid_614134, JString, required = true,
                                 default = nil)
  if valid_614134 != nil:
    section.add "EndpointArn", valid_614134
  var valid_614135 = query.getOrDefault("Version")
  valid_614135 = validateParameter(valid_614135, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_614135 != nil:
    section.add "Version", valid_614135
  var valid_614136 = query.getOrDefault("Attributes.2.key")
  valid_614136 = validateParameter(valid_614136, JString, required = false,
                                 default = nil)
  if valid_614136 != nil:
    section.add "Attributes.2.key", valid_614136
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614137 = header.getOrDefault("X-Amz-Signature")
  valid_614137 = validateParameter(valid_614137, JString, required = false,
                                 default = nil)
  if valid_614137 != nil:
    section.add "X-Amz-Signature", valid_614137
  var valid_614138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614138 = validateParameter(valid_614138, JString, required = false,
                                 default = nil)
  if valid_614138 != nil:
    section.add "X-Amz-Content-Sha256", valid_614138
  var valid_614139 = header.getOrDefault("X-Amz-Date")
  valid_614139 = validateParameter(valid_614139, JString, required = false,
                                 default = nil)
  if valid_614139 != nil:
    section.add "X-Amz-Date", valid_614139
  var valid_614140 = header.getOrDefault("X-Amz-Credential")
  valid_614140 = validateParameter(valid_614140, JString, required = false,
                                 default = nil)
  if valid_614140 != nil:
    section.add "X-Amz-Credential", valid_614140
  var valid_614141 = header.getOrDefault("X-Amz-Security-Token")
  valid_614141 = validateParameter(valid_614141, JString, required = false,
                                 default = nil)
  if valid_614141 != nil:
    section.add "X-Amz-Security-Token", valid_614141
  var valid_614142 = header.getOrDefault("X-Amz-Algorithm")
  valid_614142 = validateParameter(valid_614142, JString, required = false,
                                 default = nil)
  if valid_614142 != nil:
    section.add "X-Amz-Algorithm", valid_614142
  var valid_614143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614143 = validateParameter(valid_614143, JString, required = false,
                                 default = nil)
  if valid_614143 != nil:
    section.add "X-Amz-SignedHeaders", valid_614143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614144: Call_GetSetEndpointAttributes_614125; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_614144.validator(path, query, header, formData, body)
  let scheme = call_614144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614144.url(scheme.get, call_614144.host, call_614144.base,
                         call_614144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614144, url, valid)

proc call*(call_614145: Call_GetSetEndpointAttributes_614125; EndpointArn: string;
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
  var query_614146 = newJObject()
  add(query_614146, "Attributes.1.key", newJString(Attributes1Key))
  add(query_614146, "Attributes.0.value", newJString(Attributes0Value))
  add(query_614146, "Attributes.0.key", newJString(Attributes0Key))
  add(query_614146, "Attributes.2.value", newJString(Attributes2Value))
  add(query_614146, "Attributes.1.value", newJString(Attributes1Value))
  add(query_614146, "Action", newJString(Action))
  add(query_614146, "EndpointArn", newJString(EndpointArn))
  add(query_614146, "Version", newJString(Version))
  add(query_614146, "Attributes.2.key", newJString(Attributes2Key))
  result = call_614145.call(nil, query_614146, nil, nil, nil)

var getSetEndpointAttributes* = Call_GetSetEndpointAttributes_614125(
    name: "getSetEndpointAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetEndpointAttributes",
    validator: validate_GetSetEndpointAttributes_614126, base: "/",
    url: url_GetSetEndpointAttributes_614127, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetPlatformApplicationAttributes_614192 = ref object of OpenApiRestCall_612658
proc url_PostSetPlatformApplicationAttributes_614194(protocol: Scheme;
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

proc validate_PostSetPlatformApplicationAttributes_614193(path: JsonNode;
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
  var valid_614195 = query.getOrDefault("Action")
  valid_614195 = validateParameter(valid_614195, JString, required = true, default = newJString(
      "SetPlatformApplicationAttributes"))
  if valid_614195 != nil:
    section.add "Action", valid_614195
  var valid_614196 = query.getOrDefault("Version")
  valid_614196 = validateParameter(valid_614196, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_614196 != nil:
    section.add "Version", valid_614196
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614197 = header.getOrDefault("X-Amz-Signature")
  valid_614197 = validateParameter(valid_614197, JString, required = false,
                                 default = nil)
  if valid_614197 != nil:
    section.add "X-Amz-Signature", valid_614197
  var valid_614198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614198 = validateParameter(valid_614198, JString, required = false,
                                 default = nil)
  if valid_614198 != nil:
    section.add "X-Amz-Content-Sha256", valid_614198
  var valid_614199 = header.getOrDefault("X-Amz-Date")
  valid_614199 = validateParameter(valid_614199, JString, required = false,
                                 default = nil)
  if valid_614199 != nil:
    section.add "X-Amz-Date", valid_614199
  var valid_614200 = header.getOrDefault("X-Amz-Credential")
  valid_614200 = validateParameter(valid_614200, JString, required = false,
                                 default = nil)
  if valid_614200 != nil:
    section.add "X-Amz-Credential", valid_614200
  var valid_614201 = header.getOrDefault("X-Amz-Security-Token")
  valid_614201 = validateParameter(valid_614201, JString, required = false,
                                 default = nil)
  if valid_614201 != nil:
    section.add "X-Amz-Security-Token", valid_614201
  var valid_614202 = header.getOrDefault("X-Amz-Algorithm")
  valid_614202 = validateParameter(valid_614202, JString, required = false,
                                 default = nil)
  if valid_614202 != nil:
    section.add "X-Amz-Algorithm", valid_614202
  var valid_614203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614203 = validateParameter(valid_614203, JString, required = false,
                                 default = nil)
  if valid_614203 != nil:
    section.add "X-Amz-SignedHeaders", valid_614203
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
  var valid_614204 = formData.getOrDefault("PlatformApplicationArn")
  valid_614204 = validateParameter(valid_614204, JString, required = true,
                                 default = nil)
  if valid_614204 != nil:
    section.add "PlatformApplicationArn", valid_614204
  var valid_614205 = formData.getOrDefault("Attributes.0.key")
  valid_614205 = validateParameter(valid_614205, JString, required = false,
                                 default = nil)
  if valid_614205 != nil:
    section.add "Attributes.0.key", valid_614205
  var valid_614206 = formData.getOrDefault("Attributes.2.value")
  valid_614206 = validateParameter(valid_614206, JString, required = false,
                                 default = nil)
  if valid_614206 != nil:
    section.add "Attributes.2.value", valid_614206
  var valid_614207 = formData.getOrDefault("Attributes.2.key")
  valid_614207 = validateParameter(valid_614207, JString, required = false,
                                 default = nil)
  if valid_614207 != nil:
    section.add "Attributes.2.key", valid_614207
  var valid_614208 = formData.getOrDefault("Attributes.0.value")
  valid_614208 = validateParameter(valid_614208, JString, required = false,
                                 default = nil)
  if valid_614208 != nil:
    section.add "Attributes.0.value", valid_614208
  var valid_614209 = formData.getOrDefault("Attributes.1.key")
  valid_614209 = validateParameter(valid_614209, JString, required = false,
                                 default = nil)
  if valid_614209 != nil:
    section.add "Attributes.1.key", valid_614209
  var valid_614210 = formData.getOrDefault("Attributes.1.value")
  valid_614210 = validateParameter(valid_614210, JString, required = false,
                                 default = nil)
  if valid_614210 != nil:
    section.add "Attributes.1.value", valid_614210
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614211: Call_PostSetPlatformApplicationAttributes_614192;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  let valid = call_614211.validator(path, query, header, formData, body)
  let scheme = call_614211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614211.url(scheme.get, call_614211.host, call_614211.base,
                         call_614211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614211, url, valid)

proc call*(call_614212: Call_PostSetPlatformApplicationAttributes_614192;
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
  var query_614213 = newJObject()
  var formData_614214 = newJObject()
  add(formData_614214, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(formData_614214, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_614214, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_614214, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_614214, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_614214, "Attributes.1.key", newJString(Attributes1Key))
  add(query_614213, "Action", newJString(Action))
  add(query_614213, "Version", newJString(Version))
  add(formData_614214, "Attributes.1.value", newJString(Attributes1Value))
  result = call_614212.call(nil, query_614213, nil, formData_614214, nil)

var postSetPlatformApplicationAttributes* = Call_PostSetPlatformApplicationAttributes_614192(
    name: "postSetPlatformApplicationAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetPlatformApplicationAttributes",
    validator: validate_PostSetPlatformApplicationAttributes_614193, base: "/",
    url: url_PostSetPlatformApplicationAttributes_614194,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetPlatformApplicationAttributes_614170 = ref object of OpenApiRestCall_612658
proc url_GetSetPlatformApplicationAttributes_614172(protocol: Scheme; host: string;
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

proc validate_GetSetPlatformApplicationAttributes_614171(path: JsonNode;
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
  var valid_614173 = query.getOrDefault("Attributes.1.key")
  valid_614173 = validateParameter(valid_614173, JString, required = false,
                                 default = nil)
  if valid_614173 != nil:
    section.add "Attributes.1.key", valid_614173
  var valid_614174 = query.getOrDefault("Attributes.0.value")
  valid_614174 = validateParameter(valid_614174, JString, required = false,
                                 default = nil)
  if valid_614174 != nil:
    section.add "Attributes.0.value", valid_614174
  var valid_614175 = query.getOrDefault("Attributes.0.key")
  valid_614175 = validateParameter(valid_614175, JString, required = false,
                                 default = nil)
  if valid_614175 != nil:
    section.add "Attributes.0.key", valid_614175
  var valid_614176 = query.getOrDefault("Attributes.2.value")
  valid_614176 = validateParameter(valid_614176, JString, required = false,
                                 default = nil)
  if valid_614176 != nil:
    section.add "Attributes.2.value", valid_614176
  var valid_614177 = query.getOrDefault("Attributes.1.value")
  valid_614177 = validateParameter(valid_614177, JString, required = false,
                                 default = nil)
  if valid_614177 != nil:
    section.add "Attributes.1.value", valid_614177
  assert query != nil, "query argument is necessary due to required `PlatformApplicationArn` field"
  var valid_614178 = query.getOrDefault("PlatformApplicationArn")
  valid_614178 = validateParameter(valid_614178, JString, required = true,
                                 default = nil)
  if valid_614178 != nil:
    section.add "PlatformApplicationArn", valid_614178
  var valid_614179 = query.getOrDefault("Action")
  valid_614179 = validateParameter(valid_614179, JString, required = true, default = newJString(
      "SetPlatformApplicationAttributes"))
  if valid_614179 != nil:
    section.add "Action", valid_614179
  var valid_614180 = query.getOrDefault("Version")
  valid_614180 = validateParameter(valid_614180, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_614180 != nil:
    section.add "Version", valid_614180
  var valid_614181 = query.getOrDefault("Attributes.2.key")
  valid_614181 = validateParameter(valid_614181, JString, required = false,
                                 default = nil)
  if valid_614181 != nil:
    section.add "Attributes.2.key", valid_614181
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614182 = header.getOrDefault("X-Amz-Signature")
  valid_614182 = validateParameter(valid_614182, JString, required = false,
                                 default = nil)
  if valid_614182 != nil:
    section.add "X-Amz-Signature", valid_614182
  var valid_614183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614183 = validateParameter(valid_614183, JString, required = false,
                                 default = nil)
  if valid_614183 != nil:
    section.add "X-Amz-Content-Sha256", valid_614183
  var valid_614184 = header.getOrDefault("X-Amz-Date")
  valid_614184 = validateParameter(valid_614184, JString, required = false,
                                 default = nil)
  if valid_614184 != nil:
    section.add "X-Amz-Date", valid_614184
  var valid_614185 = header.getOrDefault("X-Amz-Credential")
  valid_614185 = validateParameter(valid_614185, JString, required = false,
                                 default = nil)
  if valid_614185 != nil:
    section.add "X-Amz-Credential", valid_614185
  var valid_614186 = header.getOrDefault("X-Amz-Security-Token")
  valid_614186 = validateParameter(valid_614186, JString, required = false,
                                 default = nil)
  if valid_614186 != nil:
    section.add "X-Amz-Security-Token", valid_614186
  var valid_614187 = header.getOrDefault("X-Amz-Algorithm")
  valid_614187 = validateParameter(valid_614187, JString, required = false,
                                 default = nil)
  if valid_614187 != nil:
    section.add "X-Amz-Algorithm", valid_614187
  var valid_614188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614188 = validateParameter(valid_614188, JString, required = false,
                                 default = nil)
  if valid_614188 != nil:
    section.add "X-Amz-SignedHeaders", valid_614188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614189: Call_GetSetPlatformApplicationAttributes_614170;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  let valid = call_614189.validator(path, query, header, formData, body)
  let scheme = call_614189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614189.url(scheme.get, call_614189.host, call_614189.base,
                         call_614189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614189, url, valid)

proc call*(call_614190: Call_GetSetPlatformApplicationAttributes_614170;
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
  var query_614191 = newJObject()
  add(query_614191, "Attributes.1.key", newJString(Attributes1Key))
  add(query_614191, "Attributes.0.value", newJString(Attributes0Value))
  add(query_614191, "Attributes.0.key", newJString(Attributes0Key))
  add(query_614191, "Attributes.2.value", newJString(Attributes2Value))
  add(query_614191, "Attributes.1.value", newJString(Attributes1Value))
  add(query_614191, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  add(query_614191, "Action", newJString(Action))
  add(query_614191, "Version", newJString(Version))
  add(query_614191, "Attributes.2.key", newJString(Attributes2Key))
  result = call_614190.call(nil, query_614191, nil, nil, nil)

var getSetPlatformApplicationAttributes* = Call_GetSetPlatformApplicationAttributes_614170(
    name: "getSetPlatformApplicationAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetPlatformApplicationAttributes",
    validator: validate_GetSetPlatformApplicationAttributes_614171, base: "/",
    url: url_GetSetPlatformApplicationAttributes_614172,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSMSAttributes_614236 = ref object of OpenApiRestCall_612658
proc url_PostSetSMSAttributes_614238(protocol: Scheme; host: string; base: string;
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

proc validate_PostSetSMSAttributes_614237(path: JsonNode; query: JsonNode;
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
  var valid_614239 = query.getOrDefault("Action")
  valid_614239 = validateParameter(valid_614239, JString, required = true,
                                 default = newJString("SetSMSAttributes"))
  if valid_614239 != nil:
    section.add "Action", valid_614239
  var valid_614240 = query.getOrDefault("Version")
  valid_614240 = validateParameter(valid_614240, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_614240 != nil:
    section.add "Version", valid_614240
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614241 = header.getOrDefault("X-Amz-Signature")
  valid_614241 = validateParameter(valid_614241, JString, required = false,
                                 default = nil)
  if valid_614241 != nil:
    section.add "X-Amz-Signature", valid_614241
  var valid_614242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614242 = validateParameter(valid_614242, JString, required = false,
                                 default = nil)
  if valid_614242 != nil:
    section.add "X-Amz-Content-Sha256", valid_614242
  var valid_614243 = header.getOrDefault("X-Amz-Date")
  valid_614243 = validateParameter(valid_614243, JString, required = false,
                                 default = nil)
  if valid_614243 != nil:
    section.add "X-Amz-Date", valid_614243
  var valid_614244 = header.getOrDefault("X-Amz-Credential")
  valid_614244 = validateParameter(valid_614244, JString, required = false,
                                 default = nil)
  if valid_614244 != nil:
    section.add "X-Amz-Credential", valid_614244
  var valid_614245 = header.getOrDefault("X-Amz-Security-Token")
  valid_614245 = validateParameter(valid_614245, JString, required = false,
                                 default = nil)
  if valid_614245 != nil:
    section.add "X-Amz-Security-Token", valid_614245
  var valid_614246 = header.getOrDefault("X-Amz-Algorithm")
  valid_614246 = validateParameter(valid_614246, JString, required = false,
                                 default = nil)
  if valid_614246 != nil:
    section.add "X-Amz-Algorithm", valid_614246
  var valid_614247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614247 = validateParameter(valid_614247, JString, required = false,
                                 default = nil)
  if valid_614247 != nil:
    section.add "X-Amz-SignedHeaders", valid_614247
  result.add "header", section
  ## parameters in `formData` object:
  ##   attributes.1.key: JString
  ##   attributes.1.value: JString
  ##   attributes.2.key: JString
  ##   attributes.0.value: JString
  ##   attributes.0.key: JString
  ##   attributes.2.value: JString
  section = newJObject()
  var valid_614248 = formData.getOrDefault("attributes.1.key")
  valid_614248 = validateParameter(valid_614248, JString, required = false,
                                 default = nil)
  if valid_614248 != nil:
    section.add "attributes.1.key", valid_614248
  var valid_614249 = formData.getOrDefault("attributes.1.value")
  valid_614249 = validateParameter(valid_614249, JString, required = false,
                                 default = nil)
  if valid_614249 != nil:
    section.add "attributes.1.value", valid_614249
  var valid_614250 = formData.getOrDefault("attributes.2.key")
  valid_614250 = validateParameter(valid_614250, JString, required = false,
                                 default = nil)
  if valid_614250 != nil:
    section.add "attributes.2.key", valid_614250
  var valid_614251 = formData.getOrDefault("attributes.0.value")
  valid_614251 = validateParameter(valid_614251, JString, required = false,
                                 default = nil)
  if valid_614251 != nil:
    section.add "attributes.0.value", valid_614251
  var valid_614252 = formData.getOrDefault("attributes.0.key")
  valid_614252 = validateParameter(valid_614252, JString, required = false,
                                 default = nil)
  if valid_614252 != nil:
    section.add "attributes.0.key", valid_614252
  var valid_614253 = formData.getOrDefault("attributes.2.value")
  valid_614253 = validateParameter(valid_614253, JString, required = false,
                                 default = nil)
  if valid_614253 != nil:
    section.add "attributes.2.value", valid_614253
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614254: Call_PostSetSMSAttributes_614236; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_614254.validator(path, query, header, formData, body)
  let scheme = call_614254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614254.url(scheme.get, call_614254.host, call_614254.base,
                         call_614254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614254, url, valid)

proc call*(call_614255: Call_PostSetSMSAttributes_614236;
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
  var query_614256 = newJObject()
  var formData_614257 = newJObject()
  add(formData_614257, "attributes.1.key", newJString(attributes1Key))
  add(formData_614257, "attributes.1.value", newJString(attributes1Value))
  add(formData_614257, "attributes.2.key", newJString(attributes2Key))
  add(formData_614257, "attributes.0.value", newJString(attributes0Value))
  add(query_614256, "Action", newJString(Action))
  add(query_614256, "Version", newJString(Version))
  add(formData_614257, "attributes.0.key", newJString(attributes0Key))
  add(formData_614257, "attributes.2.value", newJString(attributes2Value))
  result = call_614255.call(nil, query_614256, nil, formData_614257, nil)

var postSetSMSAttributes* = Call_PostSetSMSAttributes_614236(
    name: "postSetSMSAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetSMSAttributes",
    validator: validate_PostSetSMSAttributes_614237, base: "/",
    url: url_PostSetSMSAttributes_614238, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSMSAttributes_614215 = ref object of OpenApiRestCall_612658
proc url_GetSetSMSAttributes_614217(protocol: Scheme; host: string; base: string;
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

proc validate_GetSetSMSAttributes_614216(path: JsonNode; query: JsonNode;
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
  var valid_614218 = query.getOrDefault("attributes.2.key")
  valid_614218 = validateParameter(valid_614218, JString, required = false,
                                 default = nil)
  if valid_614218 != nil:
    section.add "attributes.2.key", valid_614218
  var valid_614219 = query.getOrDefault("attributes.0.key")
  valid_614219 = validateParameter(valid_614219, JString, required = false,
                                 default = nil)
  if valid_614219 != nil:
    section.add "attributes.0.key", valid_614219
  var valid_614220 = query.getOrDefault("Action")
  valid_614220 = validateParameter(valid_614220, JString, required = true,
                                 default = newJString("SetSMSAttributes"))
  if valid_614220 != nil:
    section.add "Action", valid_614220
  var valid_614221 = query.getOrDefault("attributes.1.key")
  valid_614221 = validateParameter(valid_614221, JString, required = false,
                                 default = nil)
  if valid_614221 != nil:
    section.add "attributes.1.key", valid_614221
  var valid_614222 = query.getOrDefault("attributes.0.value")
  valid_614222 = validateParameter(valid_614222, JString, required = false,
                                 default = nil)
  if valid_614222 != nil:
    section.add "attributes.0.value", valid_614222
  var valid_614223 = query.getOrDefault("Version")
  valid_614223 = validateParameter(valid_614223, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_614223 != nil:
    section.add "Version", valid_614223
  var valid_614224 = query.getOrDefault("attributes.1.value")
  valid_614224 = validateParameter(valid_614224, JString, required = false,
                                 default = nil)
  if valid_614224 != nil:
    section.add "attributes.1.value", valid_614224
  var valid_614225 = query.getOrDefault("attributes.2.value")
  valid_614225 = validateParameter(valid_614225, JString, required = false,
                                 default = nil)
  if valid_614225 != nil:
    section.add "attributes.2.value", valid_614225
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614226 = header.getOrDefault("X-Amz-Signature")
  valid_614226 = validateParameter(valid_614226, JString, required = false,
                                 default = nil)
  if valid_614226 != nil:
    section.add "X-Amz-Signature", valid_614226
  var valid_614227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614227 = validateParameter(valid_614227, JString, required = false,
                                 default = nil)
  if valid_614227 != nil:
    section.add "X-Amz-Content-Sha256", valid_614227
  var valid_614228 = header.getOrDefault("X-Amz-Date")
  valid_614228 = validateParameter(valid_614228, JString, required = false,
                                 default = nil)
  if valid_614228 != nil:
    section.add "X-Amz-Date", valid_614228
  var valid_614229 = header.getOrDefault("X-Amz-Credential")
  valid_614229 = validateParameter(valid_614229, JString, required = false,
                                 default = nil)
  if valid_614229 != nil:
    section.add "X-Amz-Credential", valid_614229
  var valid_614230 = header.getOrDefault("X-Amz-Security-Token")
  valid_614230 = validateParameter(valid_614230, JString, required = false,
                                 default = nil)
  if valid_614230 != nil:
    section.add "X-Amz-Security-Token", valid_614230
  var valid_614231 = header.getOrDefault("X-Amz-Algorithm")
  valid_614231 = validateParameter(valid_614231, JString, required = false,
                                 default = nil)
  if valid_614231 != nil:
    section.add "X-Amz-Algorithm", valid_614231
  var valid_614232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614232 = validateParameter(valid_614232, JString, required = false,
                                 default = nil)
  if valid_614232 != nil:
    section.add "X-Amz-SignedHeaders", valid_614232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614233: Call_GetSetSMSAttributes_614215; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_614233.validator(path, query, header, formData, body)
  let scheme = call_614233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614233.url(scheme.get, call_614233.host, call_614233.base,
                         call_614233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614233, url, valid)

proc call*(call_614234: Call_GetSetSMSAttributes_614215;
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
  var query_614235 = newJObject()
  add(query_614235, "attributes.2.key", newJString(attributes2Key))
  add(query_614235, "attributes.0.key", newJString(attributes0Key))
  add(query_614235, "Action", newJString(Action))
  add(query_614235, "attributes.1.key", newJString(attributes1Key))
  add(query_614235, "attributes.0.value", newJString(attributes0Value))
  add(query_614235, "Version", newJString(Version))
  add(query_614235, "attributes.1.value", newJString(attributes1Value))
  add(query_614235, "attributes.2.value", newJString(attributes2Value))
  result = call_614234.call(nil, query_614235, nil, nil, nil)

var getSetSMSAttributes* = Call_GetSetSMSAttributes_614215(
    name: "getSetSMSAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetSMSAttributes",
    validator: validate_GetSetSMSAttributes_614216, base: "/",
    url: url_GetSetSMSAttributes_614217, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSubscriptionAttributes_614276 = ref object of OpenApiRestCall_612658
proc url_PostSetSubscriptionAttributes_614278(protocol: Scheme; host: string;
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

proc validate_PostSetSubscriptionAttributes_614277(path: JsonNode; query: JsonNode;
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
  var valid_614279 = query.getOrDefault("Action")
  valid_614279 = validateParameter(valid_614279, JString, required = true, default = newJString(
      "SetSubscriptionAttributes"))
  if valid_614279 != nil:
    section.add "Action", valid_614279
  var valid_614280 = query.getOrDefault("Version")
  valid_614280 = validateParameter(valid_614280, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_614280 != nil:
    section.add "Version", valid_614280
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614281 = header.getOrDefault("X-Amz-Signature")
  valid_614281 = validateParameter(valid_614281, JString, required = false,
                                 default = nil)
  if valid_614281 != nil:
    section.add "X-Amz-Signature", valid_614281
  var valid_614282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614282 = validateParameter(valid_614282, JString, required = false,
                                 default = nil)
  if valid_614282 != nil:
    section.add "X-Amz-Content-Sha256", valid_614282
  var valid_614283 = header.getOrDefault("X-Amz-Date")
  valid_614283 = validateParameter(valid_614283, JString, required = false,
                                 default = nil)
  if valid_614283 != nil:
    section.add "X-Amz-Date", valid_614283
  var valid_614284 = header.getOrDefault("X-Amz-Credential")
  valid_614284 = validateParameter(valid_614284, JString, required = false,
                                 default = nil)
  if valid_614284 != nil:
    section.add "X-Amz-Credential", valid_614284
  var valid_614285 = header.getOrDefault("X-Amz-Security-Token")
  valid_614285 = validateParameter(valid_614285, JString, required = false,
                                 default = nil)
  if valid_614285 != nil:
    section.add "X-Amz-Security-Token", valid_614285
  var valid_614286 = header.getOrDefault("X-Amz-Algorithm")
  valid_614286 = validateParameter(valid_614286, JString, required = false,
                                 default = nil)
  if valid_614286 != nil:
    section.add "X-Amz-Algorithm", valid_614286
  var valid_614287 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614287 = validateParameter(valid_614287, JString, required = false,
                                 default = nil)
  if valid_614287 != nil:
    section.add "X-Amz-SignedHeaders", valid_614287
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
  var valid_614288 = formData.getOrDefault("AttributeName")
  valid_614288 = validateParameter(valid_614288, JString, required = true,
                                 default = nil)
  if valid_614288 != nil:
    section.add "AttributeName", valid_614288
  var valid_614289 = formData.getOrDefault("SubscriptionArn")
  valid_614289 = validateParameter(valid_614289, JString, required = true,
                                 default = nil)
  if valid_614289 != nil:
    section.add "SubscriptionArn", valid_614289
  var valid_614290 = formData.getOrDefault("AttributeValue")
  valid_614290 = validateParameter(valid_614290, JString, required = false,
                                 default = nil)
  if valid_614290 != nil:
    section.add "AttributeValue", valid_614290
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614291: Call_PostSetSubscriptionAttributes_614276; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ## 
  let valid = call_614291.validator(path, query, header, formData, body)
  let scheme = call_614291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614291.url(scheme.get, call_614291.host, call_614291.base,
                         call_614291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614291, url, valid)

proc call*(call_614292: Call_PostSetSubscriptionAttributes_614276;
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
  var query_614293 = newJObject()
  var formData_614294 = newJObject()
  add(formData_614294, "AttributeName", newJString(AttributeName))
  add(formData_614294, "SubscriptionArn", newJString(SubscriptionArn))
  add(formData_614294, "AttributeValue", newJString(AttributeValue))
  add(query_614293, "Action", newJString(Action))
  add(query_614293, "Version", newJString(Version))
  result = call_614292.call(nil, query_614293, nil, formData_614294, nil)

var postSetSubscriptionAttributes* = Call_PostSetSubscriptionAttributes_614276(
    name: "postSetSubscriptionAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetSubscriptionAttributes",
    validator: validate_PostSetSubscriptionAttributes_614277, base: "/",
    url: url_PostSetSubscriptionAttributes_614278,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSubscriptionAttributes_614258 = ref object of OpenApiRestCall_612658
proc url_GetSetSubscriptionAttributes_614260(protocol: Scheme; host: string;
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

proc validate_GetSetSubscriptionAttributes_614259(path: JsonNode; query: JsonNode;
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
  var valid_614261 = query.getOrDefault("SubscriptionArn")
  valid_614261 = validateParameter(valid_614261, JString, required = true,
                                 default = nil)
  if valid_614261 != nil:
    section.add "SubscriptionArn", valid_614261
  var valid_614262 = query.getOrDefault("AttributeValue")
  valid_614262 = validateParameter(valid_614262, JString, required = false,
                                 default = nil)
  if valid_614262 != nil:
    section.add "AttributeValue", valid_614262
  var valid_614263 = query.getOrDefault("Action")
  valid_614263 = validateParameter(valid_614263, JString, required = true, default = newJString(
      "SetSubscriptionAttributes"))
  if valid_614263 != nil:
    section.add "Action", valid_614263
  var valid_614264 = query.getOrDefault("AttributeName")
  valid_614264 = validateParameter(valid_614264, JString, required = true,
                                 default = nil)
  if valid_614264 != nil:
    section.add "AttributeName", valid_614264
  var valid_614265 = query.getOrDefault("Version")
  valid_614265 = validateParameter(valid_614265, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_614265 != nil:
    section.add "Version", valid_614265
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614266 = header.getOrDefault("X-Amz-Signature")
  valid_614266 = validateParameter(valid_614266, JString, required = false,
                                 default = nil)
  if valid_614266 != nil:
    section.add "X-Amz-Signature", valid_614266
  var valid_614267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614267 = validateParameter(valid_614267, JString, required = false,
                                 default = nil)
  if valid_614267 != nil:
    section.add "X-Amz-Content-Sha256", valid_614267
  var valid_614268 = header.getOrDefault("X-Amz-Date")
  valid_614268 = validateParameter(valid_614268, JString, required = false,
                                 default = nil)
  if valid_614268 != nil:
    section.add "X-Amz-Date", valid_614268
  var valid_614269 = header.getOrDefault("X-Amz-Credential")
  valid_614269 = validateParameter(valid_614269, JString, required = false,
                                 default = nil)
  if valid_614269 != nil:
    section.add "X-Amz-Credential", valid_614269
  var valid_614270 = header.getOrDefault("X-Amz-Security-Token")
  valid_614270 = validateParameter(valid_614270, JString, required = false,
                                 default = nil)
  if valid_614270 != nil:
    section.add "X-Amz-Security-Token", valid_614270
  var valid_614271 = header.getOrDefault("X-Amz-Algorithm")
  valid_614271 = validateParameter(valid_614271, JString, required = false,
                                 default = nil)
  if valid_614271 != nil:
    section.add "X-Amz-Algorithm", valid_614271
  var valid_614272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614272 = validateParameter(valid_614272, JString, required = false,
                                 default = nil)
  if valid_614272 != nil:
    section.add "X-Amz-SignedHeaders", valid_614272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614273: Call_GetSetSubscriptionAttributes_614258; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ## 
  let valid = call_614273.validator(path, query, header, formData, body)
  let scheme = call_614273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614273.url(scheme.get, call_614273.host, call_614273.base,
                         call_614273.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614273, url, valid)

proc call*(call_614274: Call_GetSetSubscriptionAttributes_614258;
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
  var query_614275 = newJObject()
  add(query_614275, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_614275, "AttributeValue", newJString(AttributeValue))
  add(query_614275, "Action", newJString(Action))
  add(query_614275, "AttributeName", newJString(AttributeName))
  add(query_614275, "Version", newJString(Version))
  result = call_614274.call(nil, query_614275, nil, nil, nil)

var getSetSubscriptionAttributes* = Call_GetSetSubscriptionAttributes_614258(
    name: "getSetSubscriptionAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetSubscriptionAttributes",
    validator: validate_GetSetSubscriptionAttributes_614259, base: "/",
    url: url_GetSetSubscriptionAttributes_614260,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetTopicAttributes_614313 = ref object of OpenApiRestCall_612658
proc url_PostSetTopicAttributes_614315(protocol: Scheme; host: string; base: string;
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

proc validate_PostSetTopicAttributes_614314(path: JsonNode; query: JsonNode;
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
  var valid_614316 = query.getOrDefault("Action")
  valid_614316 = validateParameter(valid_614316, JString, required = true,
                                 default = newJString("SetTopicAttributes"))
  if valid_614316 != nil:
    section.add "Action", valid_614316
  var valid_614317 = query.getOrDefault("Version")
  valid_614317 = validateParameter(valid_614317, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_614317 != nil:
    section.add "Version", valid_614317
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614318 = header.getOrDefault("X-Amz-Signature")
  valid_614318 = validateParameter(valid_614318, JString, required = false,
                                 default = nil)
  if valid_614318 != nil:
    section.add "X-Amz-Signature", valid_614318
  var valid_614319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614319 = validateParameter(valid_614319, JString, required = false,
                                 default = nil)
  if valid_614319 != nil:
    section.add "X-Amz-Content-Sha256", valid_614319
  var valid_614320 = header.getOrDefault("X-Amz-Date")
  valid_614320 = validateParameter(valid_614320, JString, required = false,
                                 default = nil)
  if valid_614320 != nil:
    section.add "X-Amz-Date", valid_614320
  var valid_614321 = header.getOrDefault("X-Amz-Credential")
  valid_614321 = validateParameter(valid_614321, JString, required = false,
                                 default = nil)
  if valid_614321 != nil:
    section.add "X-Amz-Credential", valid_614321
  var valid_614322 = header.getOrDefault("X-Amz-Security-Token")
  valid_614322 = validateParameter(valid_614322, JString, required = false,
                                 default = nil)
  if valid_614322 != nil:
    section.add "X-Amz-Security-Token", valid_614322
  var valid_614323 = header.getOrDefault("X-Amz-Algorithm")
  valid_614323 = validateParameter(valid_614323, JString, required = false,
                                 default = nil)
  if valid_614323 != nil:
    section.add "X-Amz-Algorithm", valid_614323
  var valid_614324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614324 = validateParameter(valid_614324, JString, required = false,
                                 default = nil)
  if valid_614324 != nil:
    section.add "X-Amz-SignedHeaders", valid_614324
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
  var valid_614325 = formData.getOrDefault("AttributeName")
  valid_614325 = validateParameter(valid_614325, JString, required = true,
                                 default = nil)
  if valid_614325 != nil:
    section.add "AttributeName", valid_614325
  var valid_614326 = formData.getOrDefault("TopicArn")
  valid_614326 = validateParameter(valid_614326, JString, required = true,
                                 default = nil)
  if valid_614326 != nil:
    section.add "TopicArn", valid_614326
  var valid_614327 = formData.getOrDefault("AttributeValue")
  valid_614327 = validateParameter(valid_614327, JString, required = false,
                                 default = nil)
  if valid_614327 != nil:
    section.add "AttributeValue", valid_614327
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614328: Call_PostSetTopicAttributes_614313; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  let valid = call_614328.validator(path, query, header, formData, body)
  let scheme = call_614328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614328.url(scheme.get, call_614328.host, call_614328.base,
                         call_614328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614328, url, valid)

proc call*(call_614329: Call_PostSetTopicAttributes_614313; AttributeName: string;
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
  var query_614330 = newJObject()
  var formData_614331 = newJObject()
  add(formData_614331, "AttributeName", newJString(AttributeName))
  add(formData_614331, "TopicArn", newJString(TopicArn))
  add(formData_614331, "AttributeValue", newJString(AttributeValue))
  add(query_614330, "Action", newJString(Action))
  add(query_614330, "Version", newJString(Version))
  result = call_614329.call(nil, query_614330, nil, formData_614331, nil)

var postSetTopicAttributes* = Call_PostSetTopicAttributes_614313(
    name: "postSetTopicAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetTopicAttributes",
    validator: validate_PostSetTopicAttributes_614314, base: "/",
    url: url_PostSetTopicAttributes_614315, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetTopicAttributes_614295 = ref object of OpenApiRestCall_612658
proc url_GetSetTopicAttributes_614297(protocol: Scheme; host: string; base: string;
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

proc validate_GetSetTopicAttributes_614296(path: JsonNode; query: JsonNode;
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
  var valid_614298 = query.getOrDefault("AttributeValue")
  valid_614298 = validateParameter(valid_614298, JString, required = false,
                                 default = nil)
  if valid_614298 != nil:
    section.add "AttributeValue", valid_614298
  var valid_614299 = query.getOrDefault("Action")
  valid_614299 = validateParameter(valid_614299, JString, required = true,
                                 default = newJString("SetTopicAttributes"))
  if valid_614299 != nil:
    section.add "Action", valid_614299
  var valid_614300 = query.getOrDefault("AttributeName")
  valid_614300 = validateParameter(valid_614300, JString, required = true,
                                 default = nil)
  if valid_614300 != nil:
    section.add "AttributeName", valid_614300
  var valid_614301 = query.getOrDefault("Version")
  valid_614301 = validateParameter(valid_614301, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_614301 != nil:
    section.add "Version", valid_614301
  var valid_614302 = query.getOrDefault("TopicArn")
  valid_614302 = validateParameter(valid_614302, JString, required = true,
                                 default = nil)
  if valid_614302 != nil:
    section.add "TopicArn", valid_614302
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614303 = header.getOrDefault("X-Amz-Signature")
  valid_614303 = validateParameter(valid_614303, JString, required = false,
                                 default = nil)
  if valid_614303 != nil:
    section.add "X-Amz-Signature", valid_614303
  var valid_614304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614304 = validateParameter(valid_614304, JString, required = false,
                                 default = nil)
  if valid_614304 != nil:
    section.add "X-Amz-Content-Sha256", valid_614304
  var valid_614305 = header.getOrDefault("X-Amz-Date")
  valid_614305 = validateParameter(valid_614305, JString, required = false,
                                 default = nil)
  if valid_614305 != nil:
    section.add "X-Amz-Date", valid_614305
  var valid_614306 = header.getOrDefault("X-Amz-Credential")
  valid_614306 = validateParameter(valid_614306, JString, required = false,
                                 default = nil)
  if valid_614306 != nil:
    section.add "X-Amz-Credential", valid_614306
  var valid_614307 = header.getOrDefault("X-Amz-Security-Token")
  valid_614307 = validateParameter(valid_614307, JString, required = false,
                                 default = nil)
  if valid_614307 != nil:
    section.add "X-Amz-Security-Token", valid_614307
  var valid_614308 = header.getOrDefault("X-Amz-Algorithm")
  valid_614308 = validateParameter(valid_614308, JString, required = false,
                                 default = nil)
  if valid_614308 != nil:
    section.add "X-Amz-Algorithm", valid_614308
  var valid_614309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614309 = validateParameter(valid_614309, JString, required = false,
                                 default = nil)
  if valid_614309 != nil:
    section.add "X-Amz-SignedHeaders", valid_614309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614310: Call_GetSetTopicAttributes_614295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  let valid = call_614310.validator(path, query, header, formData, body)
  let scheme = call_614310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614310.url(scheme.get, call_614310.host, call_614310.base,
                         call_614310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614310, url, valid)

proc call*(call_614311: Call_GetSetTopicAttributes_614295; AttributeName: string;
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
  var query_614312 = newJObject()
  add(query_614312, "AttributeValue", newJString(AttributeValue))
  add(query_614312, "Action", newJString(Action))
  add(query_614312, "AttributeName", newJString(AttributeName))
  add(query_614312, "Version", newJString(Version))
  add(query_614312, "TopicArn", newJString(TopicArn))
  result = call_614311.call(nil, query_614312, nil, nil, nil)

var getSetTopicAttributes* = Call_GetSetTopicAttributes_614295(
    name: "getSetTopicAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetTopicAttributes",
    validator: validate_GetSetTopicAttributes_614296, base: "/",
    url: url_GetSetTopicAttributes_614297, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSubscribe_614357 = ref object of OpenApiRestCall_612658
proc url_PostSubscribe_614359(protocol: Scheme; host: string; base: string;
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

proc validate_PostSubscribe_614358(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614360 = query.getOrDefault("Action")
  valid_614360 = validateParameter(valid_614360, JString, required = true,
                                 default = newJString("Subscribe"))
  if valid_614360 != nil:
    section.add "Action", valid_614360
  var valid_614361 = query.getOrDefault("Version")
  valid_614361 = validateParameter(valid_614361, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_614361 != nil:
    section.add "Version", valid_614361
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614362 = header.getOrDefault("X-Amz-Signature")
  valid_614362 = validateParameter(valid_614362, JString, required = false,
                                 default = nil)
  if valid_614362 != nil:
    section.add "X-Amz-Signature", valid_614362
  var valid_614363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614363 = validateParameter(valid_614363, JString, required = false,
                                 default = nil)
  if valid_614363 != nil:
    section.add "X-Amz-Content-Sha256", valid_614363
  var valid_614364 = header.getOrDefault("X-Amz-Date")
  valid_614364 = validateParameter(valid_614364, JString, required = false,
                                 default = nil)
  if valid_614364 != nil:
    section.add "X-Amz-Date", valid_614364
  var valid_614365 = header.getOrDefault("X-Amz-Credential")
  valid_614365 = validateParameter(valid_614365, JString, required = false,
                                 default = nil)
  if valid_614365 != nil:
    section.add "X-Amz-Credential", valid_614365
  var valid_614366 = header.getOrDefault("X-Amz-Security-Token")
  valid_614366 = validateParameter(valid_614366, JString, required = false,
                                 default = nil)
  if valid_614366 != nil:
    section.add "X-Amz-Security-Token", valid_614366
  var valid_614367 = header.getOrDefault("X-Amz-Algorithm")
  valid_614367 = validateParameter(valid_614367, JString, required = false,
                                 default = nil)
  if valid_614367 != nil:
    section.add "X-Amz-Algorithm", valid_614367
  var valid_614368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614368 = validateParameter(valid_614368, JString, required = false,
                                 default = nil)
  if valid_614368 != nil:
    section.add "X-Amz-SignedHeaders", valid_614368
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
  var valid_614369 = formData.getOrDefault("Endpoint")
  valid_614369 = validateParameter(valid_614369, JString, required = false,
                                 default = nil)
  if valid_614369 != nil:
    section.add "Endpoint", valid_614369
  var valid_614370 = formData.getOrDefault("Attributes.0.key")
  valid_614370 = validateParameter(valid_614370, JString, required = false,
                                 default = nil)
  if valid_614370 != nil:
    section.add "Attributes.0.key", valid_614370
  var valid_614371 = formData.getOrDefault("Attributes.2.value")
  valid_614371 = validateParameter(valid_614371, JString, required = false,
                                 default = nil)
  if valid_614371 != nil:
    section.add "Attributes.2.value", valid_614371
  var valid_614372 = formData.getOrDefault("Attributes.2.key")
  valid_614372 = validateParameter(valid_614372, JString, required = false,
                                 default = nil)
  if valid_614372 != nil:
    section.add "Attributes.2.key", valid_614372
  assert formData != nil,
        "formData argument is necessary due to required `Protocol` field"
  var valid_614373 = formData.getOrDefault("Protocol")
  valid_614373 = validateParameter(valid_614373, JString, required = true,
                                 default = nil)
  if valid_614373 != nil:
    section.add "Protocol", valid_614373
  var valid_614374 = formData.getOrDefault("Attributes.0.value")
  valid_614374 = validateParameter(valid_614374, JString, required = false,
                                 default = nil)
  if valid_614374 != nil:
    section.add "Attributes.0.value", valid_614374
  var valid_614375 = formData.getOrDefault("Attributes.1.key")
  valid_614375 = validateParameter(valid_614375, JString, required = false,
                                 default = nil)
  if valid_614375 != nil:
    section.add "Attributes.1.key", valid_614375
  var valid_614376 = formData.getOrDefault("TopicArn")
  valid_614376 = validateParameter(valid_614376, JString, required = true,
                                 default = nil)
  if valid_614376 != nil:
    section.add "TopicArn", valid_614376
  var valid_614377 = formData.getOrDefault("ReturnSubscriptionArn")
  valid_614377 = validateParameter(valid_614377, JBool, required = false, default = nil)
  if valid_614377 != nil:
    section.add "ReturnSubscriptionArn", valid_614377
  var valid_614378 = formData.getOrDefault("Attributes.1.value")
  valid_614378 = validateParameter(valid_614378, JString, required = false,
                                 default = nil)
  if valid_614378 != nil:
    section.add "Attributes.1.value", valid_614378
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614379: Call_PostSubscribe_614357; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_614379.validator(path, query, header, formData, body)
  let scheme = call_614379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614379.url(scheme.get, call_614379.host, call_614379.base,
                         call_614379.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614379, url, valid)

proc call*(call_614380: Call_PostSubscribe_614357; Protocol: string;
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
  var query_614381 = newJObject()
  var formData_614382 = newJObject()
  add(formData_614382, "Endpoint", newJString(Endpoint))
  add(formData_614382, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_614382, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_614382, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_614382, "Protocol", newJString(Protocol))
  add(formData_614382, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_614382, "Attributes.1.key", newJString(Attributes1Key))
  add(formData_614382, "TopicArn", newJString(TopicArn))
  add(formData_614382, "ReturnSubscriptionArn", newJBool(ReturnSubscriptionArn))
  add(query_614381, "Action", newJString(Action))
  add(query_614381, "Version", newJString(Version))
  add(formData_614382, "Attributes.1.value", newJString(Attributes1Value))
  result = call_614380.call(nil, query_614381, nil, formData_614382, nil)

var postSubscribe* = Call_PostSubscribe_614357(name: "postSubscribe",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=Subscribe", validator: validate_PostSubscribe_614358,
    base: "/", url: url_PostSubscribe_614359, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSubscribe_614332 = ref object of OpenApiRestCall_612658
proc url_GetSubscribe_614334(protocol: Scheme; host: string; base: string;
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

proc validate_GetSubscribe_614333(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614335 = query.getOrDefault("Attributes.1.key")
  valid_614335 = validateParameter(valid_614335, JString, required = false,
                                 default = nil)
  if valid_614335 != nil:
    section.add "Attributes.1.key", valid_614335
  var valid_614336 = query.getOrDefault("Attributes.0.value")
  valid_614336 = validateParameter(valid_614336, JString, required = false,
                                 default = nil)
  if valid_614336 != nil:
    section.add "Attributes.0.value", valid_614336
  var valid_614337 = query.getOrDefault("Endpoint")
  valid_614337 = validateParameter(valid_614337, JString, required = false,
                                 default = nil)
  if valid_614337 != nil:
    section.add "Endpoint", valid_614337
  var valid_614338 = query.getOrDefault("Attributes.0.key")
  valid_614338 = validateParameter(valid_614338, JString, required = false,
                                 default = nil)
  if valid_614338 != nil:
    section.add "Attributes.0.key", valid_614338
  var valid_614339 = query.getOrDefault("Attributes.2.value")
  valid_614339 = validateParameter(valid_614339, JString, required = false,
                                 default = nil)
  if valid_614339 != nil:
    section.add "Attributes.2.value", valid_614339
  var valid_614340 = query.getOrDefault("Attributes.1.value")
  valid_614340 = validateParameter(valid_614340, JString, required = false,
                                 default = nil)
  if valid_614340 != nil:
    section.add "Attributes.1.value", valid_614340
  var valid_614341 = query.getOrDefault("Action")
  valid_614341 = validateParameter(valid_614341, JString, required = true,
                                 default = newJString("Subscribe"))
  if valid_614341 != nil:
    section.add "Action", valid_614341
  var valid_614342 = query.getOrDefault("Protocol")
  valid_614342 = validateParameter(valid_614342, JString, required = true,
                                 default = nil)
  if valid_614342 != nil:
    section.add "Protocol", valid_614342
  var valid_614343 = query.getOrDefault("ReturnSubscriptionArn")
  valid_614343 = validateParameter(valid_614343, JBool, required = false, default = nil)
  if valid_614343 != nil:
    section.add "ReturnSubscriptionArn", valid_614343
  var valid_614344 = query.getOrDefault("Version")
  valid_614344 = validateParameter(valid_614344, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_614344 != nil:
    section.add "Version", valid_614344
  var valid_614345 = query.getOrDefault("Attributes.2.key")
  valid_614345 = validateParameter(valid_614345, JString, required = false,
                                 default = nil)
  if valid_614345 != nil:
    section.add "Attributes.2.key", valid_614345
  var valid_614346 = query.getOrDefault("TopicArn")
  valid_614346 = validateParameter(valid_614346, JString, required = true,
                                 default = nil)
  if valid_614346 != nil:
    section.add "TopicArn", valid_614346
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614347 = header.getOrDefault("X-Amz-Signature")
  valid_614347 = validateParameter(valid_614347, JString, required = false,
                                 default = nil)
  if valid_614347 != nil:
    section.add "X-Amz-Signature", valid_614347
  var valid_614348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614348 = validateParameter(valid_614348, JString, required = false,
                                 default = nil)
  if valid_614348 != nil:
    section.add "X-Amz-Content-Sha256", valid_614348
  var valid_614349 = header.getOrDefault("X-Amz-Date")
  valid_614349 = validateParameter(valid_614349, JString, required = false,
                                 default = nil)
  if valid_614349 != nil:
    section.add "X-Amz-Date", valid_614349
  var valid_614350 = header.getOrDefault("X-Amz-Credential")
  valid_614350 = validateParameter(valid_614350, JString, required = false,
                                 default = nil)
  if valid_614350 != nil:
    section.add "X-Amz-Credential", valid_614350
  var valid_614351 = header.getOrDefault("X-Amz-Security-Token")
  valid_614351 = validateParameter(valid_614351, JString, required = false,
                                 default = nil)
  if valid_614351 != nil:
    section.add "X-Amz-Security-Token", valid_614351
  var valid_614352 = header.getOrDefault("X-Amz-Algorithm")
  valid_614352 = validateParameter(valid_614352, JString, required = false,
                                 default = nil)
  if valid_614352 != nil:
    section.add "X-Amz-Algorithm", valid_614352
  var valid_614353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614353 = validateParameter(valid_614353, JString, required = false,
                                 default = nil)
  if valid_614353 != nil:
    section.add "X-Amz-SignedHeaders", valid_614353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614354: Call_GetSubscribe_614332; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_614354.validator(path, query, header, formData, body)
  let scheme = call_614354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614354.url(scheme.get, call_614354.host, call_614354.base,
                         call_614354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614354, url, valid)

proc call*(call_614355: Call_GetSubscribe_614332; Protocol: string; TopicArn: string;
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
  var query_614356 = newJObject()
  add(query_614356, "Attributes.1.key", newJString(Attributes1Key))
  add(query_614356, "Attributes.0.value", newJString(Attributes0Value))
  add(query_614356, "Endpoint", newJString(Endpoint))
  add(query_614356, "Attributes.0.key", newJString(Attributes0Key))
  add(query_614356, "Attributes.2.value", newJString(Attributes2Value))
  add(query_614356, "Attributes.1.value", newJString(Attributes1Value))
  add(query_614356, "Action", newJString(Action))
  add(query_614356, "Protocol", newJString(Protocol))
  add(query_614356, "ReturnSubscriptionArn", newJBool(ReturnSubscriptionArn))
  add(query_614356, "Version", newJString(Version))
  add(query_614356, "Attributes.2.key", newJString(Attributes2Key))
  add(query_614356, "TopicArn", newJString(TopicArn))
  result = call_614355.call(nil, query_614356, nil, nil, nil)

var getSubscribe* = Call_GetSubscribe_614332(name: "getSubscribe",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=Subscribe", validator: validate_GetSubscribe_614333, base: "/",
    url: url_GetSubscribe_614334, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTagResource_614400 = ref object of OpenApiRestCall_612658
proc url_PostTagResource_614402(protocol: Scheme; host: string; base: string;
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

proc validate_PostTagResource_614401(path: JsonNode; query: JsonNode;
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
  var valid_614403 = query.getOrDefault("Action")
  valid_614403 = validateParameter(valid_614403, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_614403 != nil:
    section.add "Action", valid_614403
  var valid_614404 = query.getOrDefault("Version")
  valid_614404 = validateParameter(valid_614404, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_614404 != nil:
    section.add "Version", valid_614404
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614405 = header.getOrDefault("X-Amz-Signature")
  valid_614405 = validateParameter(valid_614405, JString, required = false,
                                 default = nil)
  if valid_614405 != nil:
    section.add "X-Amz-Signature", valid_614405
  var valid_614406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614406 = validateParameter(valid_614406, JString, required = false,
                                 default = nil)
  if valid_614406 != nil:
    section.add "X-Amz-Content-Sha256", valid_614406
  var valid_614407 = header.getOrDefault("X-Amz-Date")
  valid_614407 = validateParameter(valid_614407, JString, required = false,
                                 default = nil)
  if valid_614407 != nil:
    section.add "X-Amz-Date", valid_614407
  var valid_614408 = header.getOrDefault("X-Amz-Credential")
  valid_614408 = validateParameter(valid_614408, JString, required = false,
                                 default = nil)
  if valid_614408 != nil:
    section.add "X-Amz-Credential", valid_614408
  var valid_614409 = header.getOrDefault("X-Amz-Security-Token")
  valid_614409 = validateParameter(valid_614409, JString, required = false,
                                 default = nil)
  if valid_614409 != nil:
    section.add "X-Amz-Security-Token", valid_614409
  var valid_614410 = header.getOrDefault("X-Amz-Algorithm")
  valid_614410 = validateParameter(valid_614410, JString, required = false,
                                 default = nil)
  if valid_614410 != nil:
    section.add "X-Amz-Algorithm", valid_614410
  var valid_614411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614411 = validateParameter(valid_614411, JString, required = false,
                                 default = nil)
  if valid_614411 != nil:
    section.add "X-Amz-SignedHeaders", valid_614411
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic to which to add tags.
  ##   Tags: JArray (required)
  ##       : The tags to be added to the specified topic. A tag consists of a required key and an optional value.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_614412 = formData.getOrDefault("ResourceArn")
  valid_614412 = validateParameter(valid_614412, JString, required = true,
                                 default = nil)
  if valid_614412 != nil:
    section.add "ResourceArn", valid_614412
  var valid_614413 = formData.getOrDefault("Tags")
  valid_614413 = validateParameter(valid_614413, JArray, required = true, default = nil)
  if valid_614413 != nil:
    section.add "Tags", valid_614413
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614414: Call_PostTagResource_614400; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account, per AWS region. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul>
  ## 
  let valid = call_614414.validator(path, query, header, formData, body)
  let scheme = call_614414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614414.url(scheme.get, call_614414.host, call_614414.base,
                         call_614414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614414, url, valid)

proc call*(call_614415: Call_PostTagResource_614400; ResourceArn: string;
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
  var query_614416 = newJObject()
  var formData_614417 = newJObject()
  add(formData_614417, "ResourceArn", newJString(ResourceArn))
  add(query_614416, "Action", newJString(Action))
  if Tags != nil:
    formData_614417.add "Tags", Tags
  add(query_614416, "Version", newJString(Version))
  result = call_614415.call(nil, query_614416, nil, formData_614417, nil)

var postTagResource* = Call_PostTagResource_614400(name: "postTagResource",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_PostTagResource_614401,
    base: "/", url: url_PostTagResource_614402, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagResource_614383 = ref object of OpenApiRestCall_612658
proc url_GetTagResource_614385(protocol: Scheme; host: string; base: string;
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

proc validate_GetTagResource_614384(path: JsonNode; query: JsonNode;
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
  var valid_614386 = query.getOrDefault("Tags")
  valid_614386 = validateParameter(valid_614386, JArray, required = true, default = nil)
  if valid_614386 != nil:
    section.add "Tags", valid_614386
  var valid_614387 = query.getOrDefault("ResourceArn")
  valid_614387 = validateParameter(valid_614387, JString, required = true,
                                 default = nil)
  if valid_614387 != nil:
    section.add "ResourceArn", valid_614387
  var valid_614388 = query.getOrDefault("Action")
  valid_614388 = validateParameter(valid_614388, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_614388 != nil:
    section.add "Action", valid_614388
  var valid_614389 = query.getOrDefault("Version")
  valid_614389 = validateParameter(valid_614389, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_614389 != nil:
    section.add "Version", valid_614389
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614390 = header.getOrDefault("X-Amz-Signature")
  valid_614390 = validateParameter(valid_614390, JString, required = false,
                                 default = nil)
  if valid_614390 != nil:
    section.add "X-Amz-Signature", valid_614390
  var valid_614391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614391 = validateParameter(valid_614391, JString, required = false,
                                 default = nil)
  if valid_614391 != nil:
    section.add "X-Amz-Content-Sha256", valid_614391
  var valid_614392 = header.getOrDefault("X-Amz-Date")
  valid_614392 = validateParameter(valid_614392, JString, required = false,
                                 default = nil)
  if valid_614392 != nil:
    section.add "X-Amz-Date", valid_614392
  var valid_614393 = header.getOrDefault("X-Amz-Credential")
  valid_614393 = validateParameter(valid_614393, JString, required = false,
                                 default = nil)
  if valid_614393 != nil:
    section.add "X-Amz-Credential", valid_614393
  var valid_614394 = header.getOrDefault("X-Amz-Security-Token")
  valid_614394 = validateParameter(valid_614394, JString, required = false,
                                 default = nil)
  if valid_614394 != nil:
    section.add "X-Amz-Security-Token", valid_614394
  var valid_614395 = header.getOrDefault("X-Amz-Algorithm")
  valid_614395 = validateParameter(valid_614395, JString, required = false,
                                 default = nil)
  if valid_614395 != nil:
    section.add "X-Amz-Algorithm", valid_614395
  var valid_614396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614396 = validateParameter(valid_614396, JString, required = false,
                                 default = nil)
  if valid_614396 != nil:
    section.add "X-Amz-SignedHeaders", valid_614396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614397: Call_GetTagResource_614383; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account, per AWS region. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul>
  ## 
  let valid = call_614397.validator(path, query, header, formData, body)
  let scheme = call_614397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614397.url(scheme.get, call_614397.host, call_614397.base,
                         call_614397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614397, url, valid)

proc call*(call_614398: Call_GetTagResource_614383; Tags: JsonNode;
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
  var query_614399 = newJObject()
  if Tags != nil:
    query_614399.add "Tags", Tags
  add(query_614399, "ResourceArn", newJString(ResourceArn))
  add(query_614399, "Action", newJString(Action))
  add(query_614399, "Version", newJString(Version))
  result = call_614398.call(nil, query_614399, nil, nil, nil)

var getTagResource* = Call_GetTagResource_614383(name: "getTagResource",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_GetTagResource_614384,
    base: "/", url: url_GetTagResource_614385, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUnsubscribe_614434 = ref object of OpenApiRestCall_612658
proc url_PostUnsubscribe_614436(protocol: Scheme; host: string; base: string;
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

proc validate_PostUnsubscribe_614435(path: JsonNode; query: JsonNode;
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
  var valid_614437 = query.getOrDefault("Action")
  valid_614437 = validateParameter(valid_614437, JString, required = true,
                                 default = newJString("Unsubscribe"))
  if valid_614437 != nil:
    section.add "Action", valid_614437
  var valid_614438 = query.getOrDefault("Version")
  valid_614438 = validateParameter(valid_614438, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_614438 != nil:
    section.add "Version", valid_614438
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614439 = header.getOrDefault("X-Amz-Signature")
  valid_614439 = validateParameter(valid_614439, JString, required = false,
                                 default = nil)
  if valid_614439 != nil:
    section.add "X-Amz-Signature", valid_614439
  var valid_614440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614440 = validateParameter(valid_614440, JString, required = false,
                                 default = nil)
  if valid_614440 != nil:
    section.add "X-Amz-Content-Sha256", valid_614440
  var valid_614441 = header.getOrDefault("X-Amz-Date")
  valid_614441 = validateParameter(valid_614441, JString, required = false,
                                 default = nil)
  if valid_614441 != nil:
    section.add "X-Amz-Date", valid_614441
  var valid_614442 = header.getOrDefault("X-Amz-Credential")
  valid_614442 = validateParameter(valid_614442, JString, required = false,
                                 default = nil)
  if valid_614442 != nil:
    section.add "X-Amz-Credential", valid_614442
  var valid_614443 = header.getOrDefault("X-Amz-Security-Token")
  valid_614443 = validateParameter(valid_614443, JString, required = false,
                                 default = nil)
  if valid_614443 != nil:
    section.add "X-Amz-Security-Token", valid_614443
  var valid_614444 = header.getOrDefault("X-Amz-Algorithm")
  valid_614444 = validateParameter(valid_614444, JString, required = false,
                                 default = nil)
  if valid_614444 != nil:
    section.add "X-Amz-Algorithm", valid_614444
  var valid_614445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614445 = validateParameter(valid_614445, JString, required = false,
                                 default = nil)
  if valid_614445 != nil:
    section.add "X-Amz-SignedHeaders", valid_614445
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription to be deleted.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionArn` field"
  var valid_614446 = formData.getOrDefault("SubscriptionArn")
  valid_614446 = validateParameter(valid_614446, JString, required = true,
                                 default = nil)
  if valid_614446 != nil:
    section.add "SubscriptionArn", valid_614446
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614447: Call_PostUnsubscribe_614434; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_614447.validator(path, query, header, formData, body)
  let scheme = call_614447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614447.url(scheme.get, call_614447.host, call_614447.base,
                         call_614447.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614447, url, valid)

proc call*(call_614448: Call_PostUnsubscribe_614434; SubscriptionArn: string;
          Action: string = "Unsubscribe"; Version: string = "2010-03-31"): Recallable =
  ## postUnsubscribe
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to be deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614449 = newJObject()
  var formData_614450 = newJObject()
  add(formData_614450, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_614449, "Action", newJString(Action))
  add(query_614449, "Version", newJString(Version))
  result = call_614448.call(nil, query_614449, nil, formData_614450, nil)

var postUnsubscribe* = Call_PostUnsubscribe_614434(name: "postUnsubscribe",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=Unsubscribe", validator: validate_PostUnsubscribe_614435,
    base: "/", url: url_PostUnsubscribe_614436, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUnsubscribe_614418 = ref object of OpenApiRestCall_612658
proc url_GetUnsubscribe_614420(protocol: Scheme; host: string; base: string;
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

proc validate_GetUnsubscribe_614419(path: JsonNode; query: JsonNode;
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
  var valid_614421 = query.getOrDefault("SubscriptionArn")
  valid_614421 = validateParameter(valid_614421, JString, required = true,
                                 default = nil)
  if valid_614421 != nil:
    section.add "SubscriptionArn", valid_614421
  var valid_614422 = query.getOrDefault("Action")
  valid_614422 = validateParameter(valid_614422, JString, required = true,
                                 default = newJString("Unsubscribe"))
  if valid_614422 != nil:
    section.add "Action", valid_614422
  var valid_614423 = query.getOrDefault("Version")
  valid_614423 = validateParameter(valid_614423, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_614423 != nil:
    section.add "Version", valid_614423
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614424 = header.getOrDefault("X-Amz-Signature")
  valid_614424 = validateParameter(valid_614424, JString, required = false,
                                 default = nil)
  if valid_614424 != nil:
    section.add "X-Amz-Signature", valid_614424
  var valid_614425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614425 = validateParameter(valid_614425, JString, required = false,
                                 default = nil)
  if valid_614425 != nil:
    section.add "X-Amz-Content-Sha256", valid_614425
  var valid_614426 = header.getOrDefault("X-Amz-Date")
  valid_614426 = validateParameter(valid_614426, JString, required = false,
                                 default = nil)
  if valid_614426 != nil:
    section.add "X-Amz-Date", valid_614426
  var valid_614427 = header.getOrDefault("X-Amz-Credential")
  valid_614427 = validateParameter(valid_614427, JString, required = false,
                                 default = nil)
  if valid_614427 != nil:
    section.add "X-Amz-Credential", valid_614427
  var valid_614428 = header.getOrDefault("X-Amz-Security-Token")
  valid_614428 = validateParameter(valid_614428, JString, required = false,
                                 default = nil)
  if valid_614428 != nil:
    section.add "X-Amz-Security-Token", valid_614428
  var valid_614429 = header.getOrDefault("X-Amz-Algorithm")
  valid_614429 = validateParameter(valid_614429, JString, required = false,
                                 default = nil)
  if valid_614429 != nil:
    section.add "X-Amz-Algorithm", valid_614429
  var valid_614430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614430 = validateParameter(valid_614430, JString, required = false,
                                 default = nil)
  if valid_614430 != nil:
    section.add "X-Amz-SignedHeaders", valid_614430
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614431: Call_GetUnsubscribe_614418; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_614431.validator(path, query, header, formData, body)
  let scheme = call_614431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614431.url(scheme.get, call_614431.host, call_614431.base,
                         call_614431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614431, url, valid)

proc call*(call_614432: Call_GetUnsubscribe_614418; SubscriptionArn: string;
          Action: string = "Unsubscribe"; Version: string = "2010-03-31"): Recallable =
  ## getUnsubscribe
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to be deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614433 = newJObject()
  add(query_614433, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_614433, "Action", newJString(Action))
  add(query_614433, "Version", newJString(Version))
  result = call_614432.call(nil, query_614433, nil, nil, nil)

var getUnsubscribe* = Call_GetUnsubscribe_614418(name: "getUnsubscribe",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=Unsubscribe", validator: validate_GetUnsubscribe_614419,
    base: "/", url: url_GetUnsubscribe_614420, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUntagResource_614468 = ref object of OpenApiRestCall_612658
proc url_PostUntagResource_614470(protocol: Scheme; host: string; base: string;
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

proc validate_PostUntagResource_614469(path: JsonNode; query: JsonNode;
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
  var valid_614471 = query.getOrDefault("Action")
  valid_614471 = validateParameter(valid_614471, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_614471 != nil:
    section.add "Action", valid_614471
  var valid_614472 = query.getOrDefault("Version")
  valid_614472 = validateParameter(valid_614472, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_614472 != nil:
    section.add "Version", valid_614472
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614473 = header.getOrDefault("X-Amz-Signature")
  valid_614473 = validateParameter(valid_614473, JString, required = false,
                                 default = nil)
  if valid_614473 != nil:
    section.add "X-Amz-Signature", valid_614473
  var valid_614474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614474 = validateParameter(valid_614474, JString, required = false,
                                 default = nil)
  if valid_614474 != nil:
    section.add "X-Amz-Content-Sha256", valid_614474
  var valid_614475 = header.getOrDefault("X-Amz-Date")
  valid_614475 = validateParameter(valid_614475, JString, required = false,
                                 default = nil)
  if valid_614475 != nil:
    section.add "X-Amz-Date", valid_614475
  var valid_614476 = header.getOrDefault("X-Amz-Credential")
  valid_614476 = validateParameter(valid_614476, JString, required = false,
                                 default = nil)
  if valid_614476 != nil:
    section.add "X-Amz-Credential", valid_614476
  var valid_614477 = header.getOrDefault("X-Amz-Security-Token")
  valid_614477 = validateParameter(valid_614477, JString, required = false,
                                 default = nil)
  if valid_614477 != nil:
    section.add "X-Amz-Security-Token", valid_614477
  var valid_614478 = header.getOrDefault("X-Amz-Algorithm")
  valid_614478 = validateParameter(valid_614478, JString, required = false,
                                 default = nil)
  if valid_614478 != nil:
    section.add "X-Amz-Algorithm", valid_614478
  var valid_614479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614479 = validateParameter(valid_614479, JString, required = false,
                                 default = nil)
  if valid_614479 != nil:
    section.add "X-Amz-SignedHeaders", valid_614479
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the specified topic.
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic from which to remove tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_614480 = formData.getOrDefault("TagKeys")
  valid_614480 = validateParameter(valid_614480, JArray, required = true, default = nil)
  if valid_614480 != nil:
    section.add "TagKeys", valid_614480
  var valid_614481 = formData.getOrDefault("ResourceArn")
  valid_614481 = validateParameter(valid_614481, JString, required = true,
                                 default = nil)
  if valid_614481 != nil:
    section.add "ResourceArn", valid_614481
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614482: Call_PostUntagResource_614468; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  let valid = call_614482.validator(path, query, header, formData, body)
  let scheme = call_614482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614482.url(scheme.get, call_614482.host, call_614482.base,
                         call_614482.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614482, url, valid)

proc call*(call_614483: Call_PostUntagResource_614468; TagKeys: JsonNode;
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
  var query_614484 = newJObject()
  var formData_614485 = newJObject()
  if TagKeys != nil:
    formData_614485.add "TagKeys", TagKeys
  add(formData_614485, "ResourceArn", newJString(ResourceArn))
  add(query_614484, "Action", newJString(Action))
  add(query_614484, "Version", newJString(Version))
  result = call_614483.call(nil, query_614484, nil, formData_614485, nil)

var postUntagResource* = Call_PostUntagResource_614468(name: "postUntagResource",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_PostUntagResource_614469,
    base: "/", url: url_PostUntagResource_614470,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUntagResource_614451 = ref object of OpenApiRestCall_612658
proc url_GetUntagResource_614453(protocol: Scheme; host: string; base: string;
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

proc validate_GetUntagResource_614452(path: JsonNode; query: JsonNode;
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
  var valid_614454 = query.getOrDefault("TagKeys")
  valid_614454 = validateParameter(valid_614454, JArray, required = true, default = nil)
  if valid_614454 != nil:
    section.add "TagKeys", valid_614454
  var valid_614455 = query.getOrDefault("ResourceArn")
  valid_614455 = validateParameter(valid_614455, JString, required = true,
                                 default = nil)
  if valid_614455 != nil:
    section.add "ResourceArn", valid_614455
  var valid_614456 = query.getOrDefault("Action")
  valid_614456 = validateParameter(valid_614456, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_614456 != nil:
    section.add "Action", valid_614456
  var valid_614457 = query.getOrDefault("Version")
  valid_614457 = validateParameter(valid_614457, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_614457 != nil:
    section.add "Version", valid_614457
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614458 = header.getOrDefault("X-Amz-Signature")
  valid_614458 = validateParameter(valid_614458, JString, required = false,
                                 default = nil)
  if valid_614458 != nil:
    section.add "X-Amz-Signature", valid_614458
  var valid_614459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614459 = validateParameter(valid_614459, JString, required = false,
                                 default = nil)
  if valid_614459 != nil:
    section.add "X-Amz-Content-Sha256", valid_614459
  var valid_614460 = header.getOrDefault("X-Amz-Date")
  valid_614460 = validateParameter(valid_614460, JString, required = false,
                                 default = nil)
  if valid_614460 != nil:
    section.add "X-Amz-Date", valid_614460
  var valid_614461 = header.getOrDefault("X-Amz-Credential")
  valid_614461 = validateParameter(valid_614461, JString, required = false,
                                 default = nil)
  if valid_614461 != nil:
    section.add "X-Amz-Credential", valid_614461
  var valid_614462 = header.getOrDefault("X-Amz-Security-Token")
  valid_614462 = validateParameter(valid_614462, JString, required = false,
                                 default = nil)
  if valid_614462 != nil:
    section.add "X-Amz-Security-Token", valid_614462
  var valid_614463 = header.getOrDefault("X-Amz-Algorithm")
  valid_614463 = validateParameter(valid_614463, JString, required = false,
                                 default = nil)
  if valid_614463 != nil:
    section.add "X-Amz-Algorithm", valid_614463
  var valid_614464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614464 = validateParameter(valid_614464, JString, required = false,
                                 default = nil)
  if valid_614464 != nil:
    section.add "X-Amz-SignedHeaders", valid_614464
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614465: Call_GetUntagResource_614451; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  let valid = call_614465.validator(path, query, header, formData, body)
  let scheme = call_614465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614465.url(scheme.get, call_614465.host, call_614465.base,
                         call_614465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614465, url, valid)

proc call*(call_614466: Call_GetUntagResource_614451; TagKeys: JsonNode;
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
  var query_614467 = newJObject()
  if TagKeys != nil:
    query_614467.add "TagKeys", TagKeys
  add(query_614467, "ResourceArn", newJString(ResourceArn))
  add(query_614467, "Action", newJString(Action))
  add(query_614467, "Version", newJString(Version))
  result = call_614466.call(nil, query_614467, nil, nil, nil)

var getUntagResource* = Call_GetUntagResource_614451(name: "getUntagResource",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_GetUntagResource_614452,
    base: "/", url: url_GetUntagResource_614453,
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
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
