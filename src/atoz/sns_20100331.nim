
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
  Call_PostAddPermission_599979 = ref object of OpenApiRestCall_599368
proc url_PostAddPermission_599981(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAddPermission_599980(path: JsonNode; query: JsonNode;
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
  var valid_599982 = query.getOrDefault("Action")
  valid_599982 = validateParameter(valid_599982, JString, required = true,
                                 default = newJString("AddPermission"))
  if valid_599982 != nil:
    section.add "Action", valid_599982
  var valid_599983 = query.getOrDefault("Version")
  valid_599983 = validateParameter(valid_599983, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_599983 != nil:
    section.add "Version", valid_599983
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599984 = header.getOrDefault("X-Amz-Date")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Date", valid_599984
  var valid_599985 = header.getOrDefault("X-Amz-Security-Token")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "X-Amz-Security-Token", valid_599985
  var valid_599986 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599986 = validateParameter(valid_599986, JString, required = false,
                                 default = nil)
  if valid_599986 != nil:
    section.add "X-Amz-Content-Sha256", valid_599986
  var valid_599987 = header.getOrDefault("X-Amz-Algorithm")
  valid_599987 = validateParameter(valid_599987, JString, required = false,
                                 default = nil)
  if valid_599987 != nil:
    section.add "X-Amz-Algorithm", valid_599987
  var valid_599988 = header.getOrDefault("X-Amz-Signature")
  valid_599988 = validateParameter(valid_599988, JString, required = false,
                                 default = nil)
  if valid_599988 != nil:
    section.add "X-Amz-Signature", valid_599988
  var valid_599989 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599989 = validateParameter(valid_599989, JString, required = false,
                                 default = nil)
  if valid_599989 != nil:
    section.add "X-Amz-SignedHeaders", valid_599989
  var valid_599990 = header.getOrDefault("X-Amz-Credential")
  valid_599990 = validateParameter(valid_599990, JString, required = false,
                                 default = nil)
  if valid_599990 != nil:
    section.add "X-Amz-Credential", valid_599990
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
  var valid_599991 = formData.getOrDefault("TopicArn")
  valid_599991 = validateParameter(valid_599991, JString, required = true,
                                 default = nil)
  if valid_599991 != nil:
    section.add "TopicArn", valid_599991
  var valid_599992 = formData.getOrDefault("AWSAccountId")
  valid_599992 = validateParameter(valid_599992, JArray, required = true, default = nil)
  if valid_599992 != nil:
    section.add "AWSAccountId", valid_599992
  var valid_599993 = formData.getOrDefault("Label")
  valid_599993 = validateParameter(valid_599993, JString, required = true,
                                 default = nil)
  if valid_599993 != nil:
    section.add "Label", valid_599993
  var valid_599994 = formData.getOrDefault("ActionName")
  valid_599994 = validateParameter(valid_599994, JArray, required = true, default = nil)
  if valid_599994 != nil:
    section.add "ActionName", valid_599994
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599995: Call_PostAddPermission_599979; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  let valid = call_599995.validator(path, query, header, formData, body)
  let scheme = call_599995.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599995.url(scheme.get, call_599995.host, call_599995.base,
                         call_599995.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599995, url, valid)

proc call*(call_599996: Call_PostAddPermission_599979; TopicArn: string;
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
  var query_599997 = newJObject()
  var formData_599998 = newJObject()
  add(formData_599998, "TopicArn", newJString(TopicArn))
  if AWSAccountId != nil:
    formData_599998.add "AWSAccountId", AWSAccountId
  add(formData_599998, "Label", newJString(Label))
  add(query_599997, "Action", newJString(Action))
  if ActionName != nil:
    formData_599998.add "ActionName", ActionName
  add(query_599997, "Version", newJString(Version))
  result = call_599996.call(nil, query_599997, nil, formData_599998, nil)

var postAddPermission* = Call_PostAddPermission_599979(name: "postAddPermission",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=AddPermission", validator: validate_PostAddPermission_599980,
    base: "/", url: url_PostAddPermission_599981,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddPermission_599705 = ref object of OpenApiRestCall_599368
proc url_GetAddPermission_599707(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAddPermission_599706(path: JsonNode; query: JsonNode;
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
  var valid_599819 = query.getOrDefault("ActionName")
  valid_599819 = validateParameter(valid_599819, JArray, required = true, default = nil)
  if valid_599819 != nil:
    section.add "ActionName", valid_599819
  var valid_599833 = query.getOrDefault("Action")
  valid_599833 = validateParameter(valid_599833, JString, required = true,
                                 default = newJString("AddPermission"))
  if valid_599833 != nil:
    section.add "Action", valid_599833
  var valid_599834 = query.getOrDefault("TopicArn")
  valid_599834 = validateParameter(valid_599834, JString, required = true,
                                 default = nil)
  if valid_599834 != nil:
    section.add "TopicArn", valid_599834
  var valid_599835 = query.getOrDefault("Version")
  valid_599835 = validateParameter(valid_599835, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_599835 != nil:
    section.add "Version", valid_599835
  var valid_599836 = query.getOrDefault("Label")
  valid_599836 = validateParameter(valid_599836, JString, required = true,
                                 default = nil)
  if valid_599836 != nil:
    section.add "Label", valid_599836
  var valid_599837 = query.getOrDefault("AWSAccountId")
  valid_599837 = validateParameter(valid_599837, JArray, required = true, default = nil)
  if valid_599837 != nil:
    section.add "AWSAccountId", valid_599837
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599838 = header.getOrDefault("X-Amz-Date")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-Date", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-Security-Token")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-Security-Token", valid_599839
  var valid_599840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599840 = validateParameter(valid_599840, JString, required = false,
                                 default = nil)
  if valid_599840 != nil:
    section.add "X-Amz-Content-Sha256", valid_599840
  var valid_599841 = header.getOrDefault("X-Amz-Algorithm")
  valid_599841 = validateParameter(valid_599841, JString, required = false,
                                 default = nil)
  if valid_599841 != nil:
    section.add "X-Amz-Algorithm", valid_599841
  var valid_599842 = header.getOrDefault("X-Amz-Signature")
  valid_599842 = validateParameter(valid_599842, JString, required = false,
                                 default = nil)
  if valid_599842 != nil:
    section.add "X-Amz-Signature", valid_599842
  var valid_599843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599843 = validateParameter(valid_599843, JString, required = false,
                                 default = nil)
  if valid_599843 != nil:
    section.add "X-Amz-SignedHeaders", valid_599843
  var valid_599844 = header.getOrDefault("X-Amz-Credential")
  valid_599844 = validateParameter(valid_599844, JString, required = false,
                                 default = nil)
  if valid_599844 != nil:
    section.add "X-Amz-Credential", valid_599844
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599867: Call_GetAddPermission_599705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  let valid = call_599867.validator(path, query, header, formData, body)
  let scheme = call_599867.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599867.url(scheme.get, call_599867.host, call_599867.base,
                         call_599867.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599867, url, valid)

proc call*(call_599938: Call_GetAddPermission_599705; ActionName: JsonNode;
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
  var query_599939 = newJObject()
  if ActionName != nil:
    query_599939.add "ActionName", ActionName
  add(query_599939, "Action", newJString(Action))
  add(query_599939, "TopicArn", newJString(TopicArn))
  add(query_599939, "Version", newJString(Version))
  add(query_599939, "Label", newJString(Label))
  if AWSAccountId != nil:
    query_599939.add "AWSAccountId", AWSAccountId
  result = call_599938.call(nil, query_599939, nil, nil, nil)

var getAddPermission* = Call_GetAddPermission_599705(name: "getAddPermission",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=AddPermission", validator: validate_GetAddPermission_599706,
    base: "/", url: url_GetAddPermission_599707,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCheckIfPhoneNumberIsOptedOut_600015 = ref object of OpenApiRestCall_599368
proc url_PostCheckIfPhoneNumberIsOptedOut_600017(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCheckIfPhoneNumberIsOptedOut_600016(path: JsonNode;
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
  var valid_600018 = query.getOrDefault("Action")
  valid_600018 = validateParameter(valid_600018, JString, required = true, default = newJString(
      "CheckIfPhoneNumberIsOptedOut"))
  if valid_600018 != nil:
    section.add "Action", valid_600018
  var valid_600019 = query.getOrDefault("Version")
  valid_600019 = validateParameter(valid_600019, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600019 != nil:
    section.add "Version", valid_600019
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600020 = header.getOrDefault("X-Amz-Date")
  valid_600020 = validateParameter(valid_600020, JString, required = false,
                                 default = nil)
  if valid_600020 != nil:
    section.add "X-Amz-Date", valid_600020
  var valid_600021 = header.getOrDefault("X-Amz-Security-Token")
  valid_600021 = validateParameter(valid_600021, JString, required = false,
                                 default = nil)
  if valid_600021 != nil:
    section.add "X-Amz-Security-Token", valid_600021
  var valid_600022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-Content-Sha256", valid_600022
  var valid_600023 = header.getOrDefault("X-Amz-Algorithm")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-Algorithm", valid_600023
  var valid_600024 = header.getOrDefault("X-Amz-Signature")
  valid_600024 = validateParameter(valid_600024, JString, required = false,
                                 default = nil)
  if valid_600024 != nil:
    section.add "X-Amz-Signature", valid_600024
  var valid_600025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-SignedHeaders", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Credential")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Credential", valid_600026
  result.add "header", section
  ## parameters in `formData` object:
  ##   phoneNumber: JString (required)
  ##              : The phone number for which you want to check the opt out status.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `phoneNumber` field"
  var valid_600027 = formData.getOrDefault("phoneNumber")
  valid_600027 = validateParameter(valid_600027, JString, required = true,
                                 default = nil)
  if valid_600027 != nil:
    section.add "phoneNumber", valid_600027
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600028: Call_PostCheckIfPhoneNumberIsOptedOut_600015;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ## 
  let valid = call_600028.validator(path, query, header, formData, body)
  let scheme = call_600028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600028.url(scheme.get, call_600028.host, call_600028.base,
                         call_600028.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600028, url, valid)

proc call*(call_600029: Call_PostCheckIfPhoneNumberIsOptedOut_600015;
          phoneNumber: string; Action: string = "CheckIfPhoneNumberIsOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## postCheckIfPhoneNumberIsOptedOut
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ##   Action: string (required)
  ##   phoneNumber: string (required)
  ##              : The phone number for which you want to check the opt out status.
  ##   Version: string (required)
  var query_600030 = newJObject()
  var formData_600031 = newJObject()
  add(query_600030, "Action", newJString(Action))
  add(formData_600031, "phoneNumber", newJString(phoneNumber))
  add(query_600030, "Version", newJString(Version))
  result = call_600029.call(nil, query_600030, nil, formData_600031, nil)

var postCheckIfPhoneNumberIsOptedOut* = Call_PostCheckIfPhoneNumberIsOptedOut_600015(
    name: "postCheckIfPhoneNumberIsOptedOut", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CheckIfPhoneNumberIsOptedOut",
    validator: validate_PostCheckIfPhoneNumberIsOptedOut_600016, base: "/",
    url: url_PostCheckIfPhoneNumberIsOptedOut_600017,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCheckIfPhoneNumberIsOptedOut_599999 = ref object of OpenApiRestCall_599368
proc url_GetCheckIfPhoneNumberIsOptedOut_600001(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCheckIfPhoneNumberIsOptedOut_600000(path: JsonNode;
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
  var valid_600002 = query.getOrDefault("phoneNumber")
  valid_600002 = validateParameter(valid_600002, JString, required = true,
                                 default = nil)
  if valid_600002 != nil:
    section.add "phoneNumber", valid_600002
  var valid_600003 = query.getOrDefault("Action")
  valid_600003 = validateParameter(valid_600003, JString, required = true, default = newJString(
      "CheckIfPhoneNumberIsOptedOut"))
  if valid_600003 != nil:
    section.add "Action", valid_600003
  var valid_600004 = query.getOrDefault("Version")
  valid_600004 = validateParameter(valid_600004, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600004 != nil:
    section.add "Version", valid_600004
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600005 = header.getOrDefault("X-Amz-Date")
  valid_600005 = validateParameter(valid_600005, JString, required = false,
                                 default = nil)
  if valid_600005 != nil:
    section.add "X-Amz-Date", valid_600005
  var valid_600006 = header.getOrDefault("X-Amz-Security-Token")
  valid_600006 = validateParameter(valid_600006, JString, required = false,
                                 default = nil)
  if valid_600006 != nil:
    section.add "X-Amz-Security-Token", valid_600006
  var valid_600007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Content-Sha256", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-Algorithm")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Algorithm", valid_600008
  var valid_600009 = header.getOrDefault("X-Amz-Signature")
  valid_600009 = validateParameter(valid_600009, JString, required = false,
                                 default = nil)
  if valid_600009 != nil:
    section.add "X-Amz-Signature", valid_600009
  var valid_600010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-SignedHeaders", valid_600010
  var valid_600011 = header.getOrDefault("X-Amz-Credential")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Credential", valid_600011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600012: Call_GetCheckIfPhoneNumberIsOptedOut_599999;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ## 
  let valid = call_600012.validator(path, query, header, formData, body)
  let scheme = call_600012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600012.url(scheme.get, call_600012.host, call_600012.base,
                         call_600012.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600012, url, valid)

proc call*(call_600013: Call_GetCheckIfPhoneNumberIsOptedOut_599999;
          phoneNumber: string; Action: string = "CheckIfPhoneNumberIsOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## getCheckIfPhoneNumberIsOptedOut
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number for which you want to check the opt out status.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600014 = newJObject()
  add(query_600014, "phoneNumber", newJString(phoneNumber))
  add(query_600014, "Action", newJString(Action))
  add(query_600014, "Version", newJString(Version))
  result = call_600013.call(nil, query_600014, nil, nil, nil)

var getCheckIfPhoneNumberIsOptedOut* = Call_GetCheckIfPhoneNumberIsOptedOut_599999(
    name: "getCheckIfPhoneNumberIsOptedOut", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CheckIfPhoneNumberIsOptedOut",
    validator: validate_GetCheckIfPhoneNumberIsOptedOut_600000, base: "/",
    url: url_GetCheckIfPhoneNumberIsOptedOut_600001,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostConfirmSubscription_600050 = ref object of OpenApiRestCall_599368
proc url_PostConfirmSubscription_600052(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostConfirmSubscription_600051(path: JsonNode; query: JsonNode;
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
  var valid_600053 = query.getOrDefault("Action")
  valid_600053 = validateParameter(valid_600053, JString, required = true,
                                 default = newJString("ConfirmSubscription"))
  if valid_600053 != nil:
    section.add "Action", valid_600053
  var valid_600054 = query.getOrDefault("Version")
  valid_600054 = validateParameter(valid_600054, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600054 != nil:
    section.add "Version", valid_600054
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600055 = header.getOrDefault("X-Amz-Date")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-Date", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Security-Token")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Security-Token", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Content-Sha256", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-Algorithm")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-Algorithm", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-Signature")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-Signature", valid_600059
  var valid_600060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600060 = validateParameter(valid_600060, JString, required = false,
                                 default = nil)
  if valid_600060 != nil:
    section.add "X-Amz-SignedHeaders", valid_600060
  var valid_600061 = header.getOrDefault("X-Amz-Credential")
  valid_600061 = validateParameter(valid_600061, JString, required = false,
                                 default = nil)
  if valid_600061 != nil:
    section.add "X-Amz-Credential", valid_600061
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
  var valid_600062 = formData.getOrDefault("TopicArn")
  valid_600062 = validateParameter(valid_600062, JString, required = true,
                                 default = nil)
  if valid_600062 != nil:
    section.add "TopicArn", valid_600062
  var valid_600063 = formData.getOrDefault("AuthenticateOnUnsubscribe")
  valid_600063 = validateParameter(valid_600063, JString, required = false,
                                 default = nil)
  if valid_600063 != nil:
    section.add "AuthenticateOnUnsubscribe", valid_600063
  var valid_600064 = formData.getOrDefault("Token")
  valid_600064 = validateParameter(valid_600064, JString, required = true,
                                 default = nil)
  if valid_600064 != nil:
    section.add "Token", valid_600064
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600065: Call_PostConfirmSubscription_600050; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  let valid = call_600065.validator(path, query, header, formData, body)
  let scheme = call_600065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600065.url(scheme.get, call_600065.host, call_600065.base,
                         call_600065.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600065, url, valid)

proc call*(call_600066: Call_PostConfirmSubscription_600050; TopicArn: string;
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
  var query_600067 = newJObject()
  var formData_600068 = newJObject()
  add(formData_600068, "TopicArn", newJString(TopicArn))
  add(formData_600068, "AuthenticateOnUnsubscribe",
      newJString(AuthenticateOnUnsubscribe))
  add(query_600067, "Action", newJString(Action))
  add(query_600067, "Version", newJString(Version))
  add(formData_600068, "Token", newJString(Token))
  result = call_600066.call(nil, query_600067, nil, formData_600068, nil)

var postConfirmSubscription* = Call_PostConfirmSubscription_600050(
    name: "postConfirmSubscription", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ConfirmSubscription",
    validator: validate_PostConfirmSubscription_600051, base: "/",
    url: url_PostConfirmSubscription_600052, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfirmSubscription_600032 = ref object of OpenApiRestCall_599368
proc url_GetConfirmSubscription_600034(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetConfirmSubscription_600033(path: JsonNode; query: JsonNode;
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
  var valid_600035 = query.getOrDefault("Token")
  valid_600035 = validateParameter(valid_600035, JString, required = true,
                                 default = nil)
  if valid_600035 != nil:
    section.add "Token", valid_600035
  var valid_600036 = query.getOrDefault("Action")
  valid_600036 = validateParameter(valid_600036, JString, required = true,
                                 default = newJString("ConfirmSubscription"))
  if valid_600036 != nil:
    section.add "Action", valid_600036
  var valid_600037 = query.getOrDefault("TopicArn")
  valid_600037 = validateParameter(valid_600037, JString, required = true,
                                 default = nil)
  if valid_600037 != nil:
    section.add "TopicArn", valid_600037
  var valid_600038 = query.getOrDefault("AuthenticateOnUnsubscribe")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "AuthenticateOnUnsubscribe", valid_600038
  var valid_600039 = query.getOrDefault("Version")
  valid_600039 = validateParameter(valid_600039, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600039 != nil:
    section.add "Version", valid_600039
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600040 = header.getOrDefault("X-Amz-Date")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Date", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Security-Token")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Security-Token", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Content-Sha256", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-Algorithm")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-Algorithm", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-Signature")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-Signature", valid_600044
  var valid_600045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600045 = validateParameter(valid_600045, JString, required = false,
                                 default = nil)
  if valid_600045 != nil:
    section.add "X-Amz-SignedHeaders", valid_600045
  var valid_600046 = header.getOrDefault("X-Amz-Credential")
  valid_600046 = validateParameter(valid_600046, JString, required = false,
                                 default = nil)
  if valid_600046 != nil:
    section.add "X-Amz-Credential", valid_600046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600047: Call_GetConfirmSubscription_600032; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  let valid = call_600047.validator(path, query, header, formData, body)
  let scheme = call_600047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600047.url(scheme.get, call_600047.host, call_600047.base,
                         call_600047.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600047, url, valid)

proc call*(call_600048: Call_GetConfirmSubscription_600032; Token: string;
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
  var query_600049 = newJObject()
  add(query_600049, "Token", newJString(Token))
  add(query_600049, "Action", newJString(Action))
  add(query_600049, "TopicArn", newJString(TopicArn))
  add(query_600049, "AuthenticateOnUnsubscribe",
      newJString(AuthenticateOnUnsubscribe))
  add(query_600049, "Version", newJString(Version))
  result = call_600048.call(nil, query_600049, nil, nil, nil)

var getConfirmSubscription* = Call_GetConfirmSubscription_600032(
    name: "getConfirmSubscription", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ConfirmSubscription",
    validator: validate_GetConfirmSubscription_600033, base: "/",
    url: url_GetConfirmSubscription_600034, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformApplication_600092 = ref object of OpenApiRestCall_599368
proc url_PostCreatePlatformApplication_600094(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreatePlatformApplication_600093(path: JsonNode; query: JsonNode;
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
  var valid_600095 = query.getOrDefault("Action")
  valid_600095 = validateParameter(valid_600095, JString, required = true, default = newJString(
      "CreatePlatformApplication"))
  if valid_600095 != nil:
    section.add "Action", valid_600095
  var valid_600096 = query.getOrDefault("Version")
  valid_600096 = validateParameter(valid_600096, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600096 != nil:
    section.add "Version", valid_600096
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600097 = header.getOrDefault("X-Amz-Date")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "X-Amz-Date", valid_600097
  var valid_600098 = header.getOrDefault("X-Amz-Security-Token")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "X-Amz-Security-Token", valid_600098
  var valid_600099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600099 = validateParameter(valid_600099, JString, required = false,
                                 default = nil)
  if valid_600099 != nil:
    section.add "X-Amz-Content-Sha256", valid_600099
  var valid_600100 = header.getOrDefault("X-Amz-Algorithm")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "X-Amz-Algorithm", valid_600100
  var valid_600101 = header.getOrDefault("X-Amz-Signature")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-Signature", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-SignedHeaders", valid_600102
  var valid_600103 = header.getOrDefault("X-Amz-Credential")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-Credential", valid_600103
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
  var valid_600104 = formData.getOrDefault("Name")
  valid_600104 = validateParameter(valid_600104, JString, required = true,
                                 default = nil)
  if valid_600104 != nil:
    section.add "Name", valid_600104
  var valid_600105 = formData.getOrDefault("Attributes.0.value")
  valid_600105 = validateParameter(valid_600105, JString, required = false,
                                 default = nil)
  if valid_600105 != nil:
    section.add "Attributes.0.value", valid_600105
  var valid_600106 = formData.getOrDefault("Attributes.0.key")
  valid_600106 = validateParameter(valid_600106, JString, required = false,
                                 default = nil)
  if valid_600106 != nil:
    section.add "Attributes.0.key", valid_600106
  var valid_600107 = formData.getOrDefault("Attributes.1.key")
  valid_600107 = validateParameter(valid_600107, JString, required = false,
                                 default = nil)
  if valid_600107 != nil:
    section.add "Attributes.1.key", valid_600107
  var valid_600108 = formData.getOrDefault("Attributes.2.value")
  valid_600108 = validateParameter(valid_600108, JString, required = false,
                                 default = nil)
  if valid_600108 != nil:
    section.add "Attributes.2.value", valid_600108
  var valid_600109 = formData.getOrDefault("Platform")
  valid_600109 = validateParameter(valid_600109, JString, required = true,
                                 default = nil)
  if valid_600109 != nil:
    section.add "Platform", valid_600109
  var valid_600110 = formData.getOrDefault("Attributes.2.key")
  valid_600110 = validateParameter(valid_600110, JString, required = false,
                                 default = nil)
  if valid_600110 != nil:
    section.add "Attributes.2.key", valid_600110
  var valid_600111 = formData.getOrDefault("Attributes.1.value")
  valid_600111 = validateParameter(valid_600111, JString, required = false,
                                 default = nil)
  if valid_600111 != nil:
    section.add "Attributes.1.value", valid_600111
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600112: Call_PostCreatePlatformApplication_600092; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For FCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For FCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action.</p>
  ## 
  let valid = call_600112.validator(path, query, header, formData, body)
  let scheme = call_600112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600112.url(scheme.get, call_600112.host, call_600112.base,
                         call_600112.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600112, url, valid)

proc call*(call_600113: Call_PostCreatePlatformApplication_600092; Name: string;
          Platform: string; Attributes0Value: string = "";
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
  var query_600114 = newJObject()
  var formData_600115 = newJObject()
  add(formData_600115, "Name", newJString(Name))
  add(formData_600115, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_600115, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_600115, "Attributes.1.key", newJString(Attributes1Key))
  add(query_600114, "Action", newJString(Action))
  add(formData_600115, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_600115, "Platform", newJString(Platform))
  add(formData_600115, "Attributes.2.key", newJString(Attributes2Key))
  add(query_600114, "Version", newJString(Version))
  add(formData_600115, "Attributes.1.value", newJString(Attributes1Value))
  result = call_600113.call(nil, query_600114, nil, formData_600115, nil)

var postCreatePlatformApplication* = Call_PostCreatePlatformApplication_600092(
    name: "postCreatePlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformApplication",
    validator: validate_PostCreatePlatformApplication_600093, base: "/",
    url: url_PostCreatePlatformApplication_600094,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformApplication_600069 = ref object of OpenApiRestCall_599368
proc url_GetCreatePlatformApplication_600071(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreatePlatformApplication_600070(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600072 = query.getOrDefault("Attributes.2.key")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "Attributes.2.key", valid_600072
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_600073 = query.getOrDefault("Name")
  valid_600073 = validateParameter(valid_600073, JString, required = true,
                                 default = nil)
  if valid_600073 != nil:
    section.add "Name", valid_600073
  var valid_600074 = query.getOrDefault("Attributes.1.value")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "Attributes.1.value", valid_600074
  var valid_600075 = query.getOrDefault("Attributes.0.value")
  valid_600075 = validateParameter(valid_600075, JString, required = false,
                                 default = nil)
  if valid_600075 != nil:
    section.add "Attributes.0.value", valid_600075
  var valid_600076 = query.getOrDefault("Action")
  valid_600076 = validateParameter(valid_600076, JString, required = true, default = newJString(
      "CreatePlatformApplication"))
  if valid_600076 != nil:
    section.add "Action", valid_600076
  var valid_600077 = query.getOrDefault("Attributes.1.key")
  valid_600077 = validateParameter(valid_600077, JString, required = false,
                                 default = nil)
  if valid_600077 != nil:
    section.add "Attributes.1.key", valid_600077
  var valid_600078 = query.getOrDefault("Platform")
  valid_600078 = validateParameter(valid_600078, JString, required = true,
                                 default = nil)
  if valid_600078 != nil:
    section.add "Platform", valid_600078
  var valid_600079 = query.getOrDefault("Attributes.2.value")
  valid_600079 = validateParameter(valid_600079, JString, required = false,
                                 default = nil)
  if valid_600079 != nil:
    section.add "Attributes.2.value", valid_600079
  var valid_600080 = query.getOrDefault("Attributes.0.key")
  valid_600080 = validateParameter(valid_600080, JString, required = false,
                                 default = nil)
  if valid_600080 != nil:
    section.add "Attributes.0.key", valid_600080
  var valid_600081 = query.getOrDefault("Version")
  valid_600081 = validateParameter(valid_600081, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600081 != nil:
    section.add "Version", valid_600081
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600082 = header.getOrDefault("X-Amz-Date")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-Date", valid_600082
  var valid_600083 = header.getOrDefault("X-Amz-Security-Token")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Security-Token", valid_600083
  var valid_600084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600084 = validateParameter(valid_600084, JString, required = false,
                                 default = nil)
  if valid_600084 != nil:
    section.add "X-Amz-Content-Sha256", valid_600084
  var valid_600085 = header.getOrDefault("X-Amz-Algorithm")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "X-Amz-Algorithm", valid_600085
  var valid_600086 = header.getOrDefault("X-Amz-Signature")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-Signature", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-SignedHeaders", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-Credential")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-Credential", valid_600088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600089: Call_GetCreatePlatformApplication_600069; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For FCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For FCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action.</p>
  ## 
  let valid = call_600089.validator(path, query, header, formData, body)
  let scheme = call_600089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600089.url(scheme.get, call_600089.host, call_600089.base,
                         call_600089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600089, url, valid)

proc call*(call_600090: Call_GetCreatePlatformApplication_600069; Name: string;
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
  var query_600091 = newJObject()
  add(query_600091, "Attributes.2.key", newJString(Attributes2Key))
  add(query_600091, "Name", newJString(Name))
  add(query_600091, "Attributes.1.value", newJString(Attributes1Value))
  add(query_600091, "Attributes.0.value", newJString(Attributes0Value))
  add(query_600091, "Action", newJString(Action))
  add(query_600091, "Attributes.1.key", newJString(Attributes1Key))
  add(query_600091, "Platform", newJString(Platform))
  add(query_600091, "Attributes.2.value", newJString(Attributes2Value))
  add(query_600091, "Attributes.0.key", newJString(Attributes0Key))
  add(query_600091, "Version", newJString(Version))
  result = call_600090.call(nil, query_600091, nil, nil, nil)

var getCreatePlatformApplication* = Call_GetCreatePlatformApplication_600069(
    name: "getCreatePlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformApplication",
    validator: validate_GetCreatePlatformApplication_600070, base: "/",
    url: url_GetCreatePlatformApplication_600071,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformEndpoint_600140 = ref object of OpenApiRestCall_599368
proc url_PostCreatePlatformEndpoint_600142(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreatePlatformEndpoint_600141(path: JsonNode; query: JsonNode;
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
  var valid_600143 = query.getOrDefault("Action")
  valid_600143 = validateParameter(valid_600143, JString, required = true,
                                 default = newJString("CreatePlatformEndpoint"))
  if valid_600143 != nil:
    section.add "Action", valid_600143
  var valid_600144 = query.getOrDefault("Version")
  valid_600144 = validateParameter(valid_600144, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600144 != nil:
    section.add "Version", valid_600144
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600145 = header.getOrDefault("X-Amz-Date")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-Date", valid_600145
  var valid_600146 = header.getOrDefault("X-Amz-Security-Token")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-Security-Token", valid_600146
  var valid_600147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-Content-Sha256", valid_600147
  var valid_600148 = header.getOrDefault("X-Amz-Algorithm")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "X-Amz-Algorithm", valid_600148
  var valid_600149 = header.getOrDefault("X-Amz-Signature")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "X-Amz-Signature", valid_600149
  var valid_600150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600150 = validateParameter(valid_600150, JString, required = false,
                                 default = nil)
  if valid_600150 != nil:
    section.add "X-Amz-SignedHeaders", valid_600150
  var valid_600151 = header.getOrDefault("X-Amz-Credential")
  valid_600151 = validateParameter(valid_600151, JString, required = false,
                                 default = nil)
  if valid_600151 != nil:
    section.add "X-Amz-Credential", valid_600151
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
  var valid_600152 = formData.getOrDefault("Attributes.0.value")
  valid_600152 = validateParameter(valid_600152, JString, required = false,
                                 default = nil)
  if valid_600152 != nil:
    section.add "Attributes.0.value", valid_600152
  var valid_600153 = formData.getOrDefault("Attributes.0.key")
  valid_600153 = validateParameter(valid_600153, JString, required = false,
                                 default = nil)
  if valid_600153 != nil:
    section.add "Attributes.0.key", valid_600153
  var valid_600154 = formData.getOrDefault("Attributes.1.key")
  valid_600154 = validateParameter(valid_600154, JString, required = false,
                                 default = nil)
  if valid_600154 != nil:
    section.add "Attributes.1.key", valid_600154
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_600155 = formData.getOrDefault("PlatformApplicationArn")
  valid_600155 = validateParameter(valid_600155, JString, required = true,
                                 default = nil)
  if valid_600155 != nil:
    section.add "PlatformApplicationArn", valid_600155
  var valid_600156 = formData.getOrDefault("CustomUserData")
  valid_600156 = validateParameter(valid_600156, JString, required = false,
                                 default = nil)
  if valid_600156 != nil:
    section.add "CustomUserData", valid_600156
  var valid_600157 = formData.getOrDefault("Attributes.2.value")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "Attributes.2.value", valid_600157
  var valid_600158 = formData.getOrDefault("Attributes.2.key")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "Attributes.2.key", valid_600158
  var valid_600159 = formData.getOrDefault("Attributes.1.value")
  valid_600159 = validateParameter(valid_600159, JString, required = false,
                                 default = nil)
  if valid_600159 != nil:
    section.add "Attributes.1.value", valid_600159
  var valid_600160 = formData.getOrDefault("Token")
  valid_600160 = validateParameter(valid_600160, JString, required = true,
                                 default = nil)
  if valid_600160 != nil:
    section.add "Token", valid_600160
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600161: Call_PostCreatePlatformEndpoint_600140; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as FCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  let valid = call_600161.validator(path, query, header, formData, body)
  let scheme = call_600161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600161.url(scheme.get, call_600161.host, call_600161.base,
                         call_600161.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600161, url, valid)

proc call*(call_600162: Call_PostCreatePlatformEndpoint_600140;
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
  var query_600163 = newJObject()
  var formData_600164 = newJObject()
  add(formData_600164, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_600164, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_600164, "Attributes.1.key", newJString(Attributes1Key))
  add(query_600163, "Action", newJString(Action))
  add(formData_600164, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(formData_600164, "CustomUserData", newJString(CustomUserData))
  add(formData_600164, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_600164, "Attributes.2.key", newJString(Attributes2Key))
  add(query_600163, "Version", newJString(Version))
  add(formData_600164, "Attributes.1.value", newJString(Attributes1Value))
  add(formData_600164, "Token", newJString(Token))
  result = call_600162.call(nil, query_600163, nil, formData_600164, nil)

var postCreatePlatformEndpoint* = Call_PostCreatePlatformEndpoint_600140(
    name: "postCreatePlatformEndpoint", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformEndpoint",
    validator: validate_PostCreatePlatformEndpoint_600141, base: "/",
    url: url_PostCreatePlatformEndpoint_600142,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformEndpoint_600116 = ref object of OpenApiRestCall_599368
proc url_GetCreatePlatformEndpoint_600118(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreatePlatformEndpoint_600117(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600119 = query.getOrDefault("CustomUserData")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "CustomUserData", valid_600119
  var valid_600120 = query.getOrDefault("Attributes.2.key")
  valid_600120 = validateParameter(valid_600120, JString, required = false,
                                 default = nil)
  if valid_600120 != nil:
    section.add "Attributes.2.key", valid_600120
  assert query != nil, "query argument is necessary due to required `Token` field"
  var valid_600121 = query.getOrDefault("Token")
  valid_600121 = validateParameter(valid_600121, JString, required = true,
                                 default = nil)
  if valid_600121 != nil:
    section.add "Token", valid_600121
  var valid_600122 = query.getOrDefault("Attributes.1.value")
  valid_600122 = validateParameter(valid_600122, JString, required = false,
                                 default = nil)
  if valid_600122 != nil:
    section.add "Attributes.1.value", valid_600122
  var valid_600123 = query.getOrDefault("Attributes.0.value")
  valid_600123 = validateParameter(valid_600123, JString, required = false,
                                 default = nil)
  if valid_600123 != nil:
    section.add "Attributes.0.value", valid_600123
  var valid_600124 = query.getOrDefault("Action")
  valid_600124 = validateParameter(valid_600124, JString, required = true,
                                 default = newJString("CreatePlatformEndpoint"))
  if valid_600124 != nil:
    section.add "Action", valid_600124
  var valid_600125 = query.getOrDefault("Attributes.1.key")
  valid_600125 = validateParameter(valid_600125, JString, required = false,
                                 default = nil)
  if valid_600125 != nil:
    section.add "Attributes.1.key", valid_600125
  var valid_600126 = query.getOrDefault("Attributes.2.value")
  valid_600126 = validateParameter(valid_600126, JString, required = false,
                                 default = nil)
  if valid_600126 != nil:
    section.add "Attributes.2.value", valid_600126
  var valid_600127 = query.getOrDefault("Attributes.0.key")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "Attributes.0.key", valid_600127
  var valid_600128 = query.getOrDefault("Version")
  valid_600128 = validateParameter(valid_600128, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600128 != nil:
    section.add "Version", valid_600128
  var valid_600129 = query.getOrDefault("PlatformApplicationArn")
  valid_600129 = validateParameter(valid_600129, JString, required = true,
                                 default = nil)
  if valid_600129 != nil:
    section.add "PlatformApplicationArn", valid_600129
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600130 = header.getOrDefault("X-Amz-Date")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "X-Amz-Date", valid_600130
  var valid_600131 = header.getOrDefault("X-Amz-Security-Token")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Security-Token", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-Content-Sha256", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-Algorithm")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-Algorithm", valid_600133
  var valid_600134 = header.getOrDefault("X-Amz-Signature")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-Signature", valid_600134
  var valid_600135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600135 = validateParameter(valid_600135, JString, required = false,
                                 default = nil)
  if valid_600135 != nil:
    section.add "X-Amz-SignedHeaders", valid_600135
  var valid_600136 = header.getOrDefault("X-Amz-Credential")
  valid_600136 = validateParameter(valid_600136, JString, required = false,
                                 default = nil)
  if valid_600136 != nil:
    section.add "X-Amz-Credential", valid_600136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600137: Call_GetCreatePlatformEndpoint_600116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as FCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  let valid = call_600137.validator(path, query, header, formData, body)
  let scheme = call_600137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600137.url(scheme.get, call_600137.host, call_600137.base,
                         call_600137.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600137, url, valid)

proc call*(call_600138: Call_GetCreatePlatformEndpoint_600116; Token: string;
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
  var query_600139 = newJObject()
  add(query_600139, "CustomUserData", newJString(CustomUserData))
  add(query_600139, "Attributes.2.key", newJString(Attributes2Key))
  add(query_600139, "Token", newJString(Token))
  add(query_600139, "Attributes.1.value", newJString(Attributes1Value))
  add(query_600139, "Attributes.0.value", newJString(Attributes0Value))
  add(query_600139, "Action", newJString(Action))
  add(query_600139, "Attributes.1.key", newJString(Attributes1Key))
  add(query_600139, "Attributes.2.value", newJString(Attributes2Value))
  add(query_600139, "Attributes.0.key", newJString(Attributes0Key))
  add(query_600139, "Version", newJString(Version))
  add(query_600139, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_600138.call(nil, query_600139, nil, nil, nil)

var getCreatePlatformEndpoint* = Call_GetCreatePlatformEndpoint_600116(
    name: "getCreatePlatformEndpoint", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformEndpoint",
    validator: validate_GetCreatePlatformEndpoint_600117, base: "/",
    url: url_GetCreatePlatformEndpoint_600118,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateTopic_600188 = ref object of OpenApiRestCall_599368
proc url_PostCreateTopic_600190(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateTopic_600189(path: JsonNode; query: JsonNode;
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
  var valid_600191 = query.getOrDefault("Action")
  valid_600191 = validateParameter(valid_600191, JString, required = true,
                                 default = newJString("CreateTopic"))
  if valid_600191 != nil:
    section.add "Action", valid_600191
  var valid_600192 = query.getOrDefault("Version")
  valid_600192 = validateParameter(valid_600192, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600192 != nil:
    section.add "Version", valid_600192
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600193 = header.getOrDefault("X-Amz-Date")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "X-Amz-Date", valid_600193
  var valid_600194 = header.getOrDefault("X-Amz-Security-Token")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "X-Amz-Security-Token", valid_600194
  var valid_600195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600195 = validateParameter(valid_600195, JString, required = false,
                                 default = nil)
  if valid_600195 != nil:
    section.add "X-Amz-Content-Sha256", valid_600195
  var valid_600196 = header.getOrDefault("X-Amz-Algorithm")
  valid_600196 = validateParameter(valid_600196, JString, required = false,
                                 default = nil)
  if valid_600196 != nil:
    section.add "X-Amz-Algorithm", valid_600196
  var valid_600197 = header.getOrDefault("X-Amz-Signature")
  valid_600197 = validateParameter(valid_600197, JString, required = false,
                                 default = nil)
  if valid_600197 != nil:
    section.add "X-Amz-Signature", valid_600197
  var valid_600198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600198 = validateParameter(valid_600198, JString, required = false,
                                 default = nil)
  if valid_600198 != nil:
    section.add "X-Amz-SignedHeaders", valid_600198
  var valid_600199 = header.getOrDefault("X-Amz-Credential")
  valid_600199 = validateParameter(valid_600199, JString, required = false,
                                 default = nil)
  if valid_600199 != nil:
    section.add "X-Amz-Credential", valid_600199
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
  var valid_600200 = formData.getOrDefault("Name")
  valid_600200 = validateParameter(valid_600200, JString, required = true,
                                 default = nil)
  if valid_600200 != nil:
    section.add "Name", valid_600200
  var valid_600201 = formData.getOrDefault("Attributes.0.value")
  valid_600201 = validateParameter(valid_600201, JString, required = false,
                                 default = nil)
  if valid_600201 != nil:
    section.add "Attributes.0.value", valid_600201
  var valid_600202 = formData.getOrDefault("Attributes.0.key")
  valid_600202 = validateParameter(valid_600202, JString, required = false,
                                 default = nil)
  if valid_600202 != nil:
    section.add "Attributes.0.key", valid_600202
  var valid_600203 = formData.getOrDefault("Tags")
  valid_600203 = validateParameter(valid_600203, JArray, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "Tags", valid_600203
  var valid_600204 = formData.getOrDefault("Attributes.1.key")
  valid_600204 = validateParameter(valid_600204, JString, required = false,
                                 default = nil)
  if valid_600204 != nil:
    section.add "Attributes.1.key", valid_600204
  var valid_600205 = formData.getOrDefault("Attributes.2.value")
  valid_600205 = validateParameter(valid_600205, JString, required = false,
                                 default = nil)
  if valid_600205 != nil:
    section.add "Attributes.2.value", valid_600205
  var valid_600206 = formData.getOrDefault("Attributes.2.key")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "Attributes.2.key", valid_600206
  var valid_600207 = formData.getOrDefault("Attributes.1.value")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "Attributes.1.value", valid_600207
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600208: Call_PostCreateTopic_600188; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  let valid = call_600208.validator(path, query, header, formData, body)
  let scheme = call_600208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600208.url(scheme.get, call_600208.host, call_600208.base,
                         call_600208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600208, url, valid)

proc call*(call_600209: Call_PostCreateTopic_600188; Name: string;
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
  var query_600210 = newJObject()
  var formData_600211 = newJObject()
  add(formData_600211, "Name", newJString(Name))
  add(formData_600211, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_600211, "Attributes.0.key", newJString(Attributes0Key))
  if Tags != nil:
    formData_600211.add "Tags", Tags
  add(formData_600211, "Attributes.1.key", newJString(Attributes1Key))
  add(query_600210, "Action", newJString(Action))
  add(formData_600211, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_600211, "Attributes.2.key", newJString(Attributes2Key))
  add(query_600210, "Version", newJString(Version))
  add(formData_600211, "Attributes.1.value", newJString(Attributes1Value))
  result = call_600209.call(nil, query_600210, nil, formData_600211, nil)

var postCreateTopic* = Call_PostCreateTopic_600188(name: "postCreateTopic",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=CreateTopic", validator: validate_PostCreateTopic_600189,
    base: "/", url: url_PostCreateTopic_600190, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateTopic_600165 = ref object of OpenApiRestCall_599368
proc url_GetCreateTopic_600167(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateTopic_600166(path: JsonNode; query: JsonNode;
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
  ##       : <p>The list of tags to add to a new topic.</p> <note> <p>To be able to tag a topic on creation, you must have the <code>sns:CreateTopic</code> and <code>sns:TagResource</code> permissions.</p> </note>
  ##   Attributes.0.value: JString
  ##   Action: JString (required)
  ##   Attributes.1.key: JString
  ##   Attributes.2.value: JString
  ##   Attributes.0.key: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_600168 = query.getOrDefault("Attributes.2.key")
  valid_600168 = validateParameter(valid_600168, JString, required = false,
                                 default = nil)
  if valid_600168 != nil:
    section.add "Attributes.2.key", valid_600168
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_600169 = query.getOrDefault("Name")
  valid_600169 = validateParameter(valid_600169, JString, required = true,
                                 default = nil)
  if valid_600169 != nil:
    section.add "Name", valid_600169
  var valid_600170 = query.getOrDefault("Attributes.1.value")
  valid_600170 = validateParameter(valid_600170, JString, required = false,
                                 default = nil)
  if valid_600170 != nil:
    section.add "Attributes.1.value", valid_600170
  var valid_600171 = query.getOrDefault("Tags")
  valid_600171 = validateParameter(valid_600171, JArray, required = false,
                                 default = nil)
  if valid_600171 != nil:
    section.add "Tags", valid_600171
  var valid_600172 = query.getOrDefault("Attributes.0.value")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "Attributes.0.value", valid_600172
  var valid_600173 = query.getOrDefault("Action")
  valid_600173 = validateParameter(valid_600173, JString, required = true,
                                 default = newJString("CreateTopic"))
  if valid_600173 != nil:
    section.add "Action", valid_600173
  var valid_600174 = query.getOrDefault("Attributes.1.key")
  valid_600174 = validateParameter(valid_600174, JString, required = false,
                                 default = nil)
  if valid_600174 != nil:
    section.add "Attributes.1.key", valid_600174
  var valid_600175 = query.getOrDefault("Attributes.2.value")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "Attributes.2.value", valid_600175
  var valid_600176 = query.getOrDefault("Attributes.0.key")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "Attributes.0.key", valid_600176
  var valid_600177 = query.getOrDefault("Version")
  valid_600177 = validateParameter(valid_600177, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600177 != nil:
    section.add "Version", valid_600177
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600178 = header.getOrDefault("X-Amz-Date")
  valid_600178 = validateParameter(valid_600178, JString, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "X-Amz-Date", valid_600178
  var valid_600179 = header.getOrDefault("X-Amz-Security-Token")
  valid_600179 = validateParameter(valid_600179, JString, required = false,
                                 default = nil)
  if valid_600179 != nil:
    section.add "X-Amz-Security-Token", valid_600179
  var valid_600180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600180 = validateParameter(valid_600180, JString, required = false,
                                 default = nil)
  if valid_600180 != nil:
    section.add "X-Amz-Content-Sha256", valid_600180
  var valid_600181 = header.getOrDefault("X-Amz-Algorithm")
  valid_600181 = validateParameter(valid_600181, JString, required = false,
                                 default = nil)
  if valid_600181 != nil:
    section.add "X-Amz-Algorithm", valid_600181
  var valid_600182 = header.getOrDefault("X-Amz-Signature")
  valid_600182 = validateParameter(valid_600182, JString, required = false,
                                 default = nil)
  if valid_600182 != nil:
    section.add "X-Amz-Signature", valid_600182
  var valid_600183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600183 = validateParameter(valid_600183, JString, required = false,
                                 default = nil)
  if valid_600183 != nil:
    section.add "X-Amz-SignedHeaders", valid_600183
  var valid_600184 = header.getOrDefault("X-Amz-Credential")
  valid_600184 = validateParameter(valid_600184, JString, required = false,
                                 default = nil)
  if valid_600184 != nil:
    section.add "X-Amz-Credential", valid_600184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600185: Call_GetCreateTopic_600165; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  let valid = call_600185.validator(path, query, header, formData, body)
  let scheme = call_600185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600185.url(scheme.get, call_600185.host, call_600185.base,
                         call_600185.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600185, url, valid)

proc call*(call_600186: Call_GetCreateTopic_600165; Name: string;
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
  var query_600187 = newJObject()
  add(query_600187, "Attributes.2.key", newJString(Attributes2Key))
  add(query_600187, "Name", newJString(Name))
  add(query_600187, "Attributes.1.value", newJString(Attributes1Value))
  if Tags != nil:
    query_600187.add "Tags", Tags
  add(query_600187, "Attributes.0.value", newJString(Attributes0Value))
  add(query_600187, "Action", newJString(Action))
  add(query_600187, "Attributes.1.key", newJString(Attributes1Key))
  add(query_600187, "Attributes.2.value", newJString(Attributes2Value))
  add(query_600187, "Attributes.0.key", newJString(Attributes0Key))
  add(query_600187, "Version", newJString(Version))
  result = call_600186.call(nil, query_600187, nil, nil, nil)

var getCreateTopic* = Call_GetCreateTopic_600165(name: "getCreateTopic",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=CreateTopic", validator: validate_GetCreateTopic_600166,
    base: "/", url: url_GetCreateTopic_600167, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEndpoint_600228 = ref object of OpenApiRestCall_599368
proc url_PostDeleteEndpoint_600230(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteEndpoint_600229(path: JsonNode; query: JsonNode;
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
  var valid_600231 = query.getOrDefault("Action")
  valid_600231 = validateParameter(valid_600231, JString, required = true,
                                 default = newJString("DeleteEndpoint"))
  if valid_600231 != nil:
    section.add "Action", valid_600231
  var valid_600232 = query.getOrDefault("Version")
  valid_600232 = validateParameter(valid_600232, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600232 != nil:
    section.add "Version", valid_600232
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600233 = header.getOrDefault("X-Amz-Date")
  valid_600233 = validateParameter(valid_600233, JString, required = false,
                                 default = nil)
  if valid_600233 != nil:
    section.add "X-Amz-Date", valid_600233
  var valid_600234 = header.getOrDefault("X-Amz-Security-Token")
  valid_600234 = validateParameter(valid_600234, JString, required = false,
                                 default = nil)
  if valid_600234 != nil:
    section.add "X-Amz-Security-Token", valid_600234
  var valid_600235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600235 = validateParameter(valid_600235, JString, required = false,
                                 default = nil)
  if valid_600235 != nil:
    section.add "X-Amz-Content-Sha256", valid_600235
  var valid_600236 = header.getOrDefault("X-Amz-Algorithm")
  valid_600236 = validateParameter(valid_600236, JString, required = false,
                                 default = nil)
  if valid_600236 != nil:
    section.add "X-Amz-Algorithm", valid_600236
  var valid_600237 = header.getOrDefault("X-Amz-Signature")
  valid_600237 = validateParameter(valid_600237, JString, required = false,
                                 default = nil)
  if valid_600237 != nil:
    section.add "X-Amz-Signature", valid_600237
  var valid_600238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600238 = validateParameter(valid_600238, JString, required = false,
                                 default = nil)
  if valid_600238 != nil:
    section.add "X-Amz-SignedHeaders", valid_600238
  var valid_600239 = header.getOrDefault("X-Amz-Credential")
  valid_600239 = validateParameter(valid_600239, JString, required = false,
                                 default = nil)
  if valid_600239 != nil:
    section.add "X-Amz-Credential", valid_600239
  result.add "header", section
  ## parameters in `formData` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn of endpoint to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_600240 = formData.getOrDefault("EndpointArn")
  valid_600240 = validateParameter(valid_600240, JString, required = true,
                                 default = nil)
  if valid_600240 != nil:
    section.add "EndpointArn", valid_600240
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600241: Call_PostDeleteEndpoint_600228; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ## 
  let valid = call_600241.validator(path, query, header, formData, body)
  let scheme = call_600241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600241.url(scheme.get, call_600241.host, call_600241.base,
                         call_600241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600241, url, valid)

proc call*(call_600242: Call_PostDeleteEndpoint_600228; EndpointArn: string;
          Action: string = "DeleteEndpoint"; Version: string = "2010-03-31"): Recallable =
  ## postDeleteEndpoint
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ##   Action: string (required)
  ##   EndpointArn: string (required)
  ##              : EndpointArn of endpoint to delete.
  ##   Version: string (required)
  var query_600243 = newJObject()
  var formData_600244 = newJObject()
  add(query_600243, "Action", newJString(Action))
  add(formData_600244, "EndpointArn", newJString(EndpointArn))
  add(query_600243, "Version", newJString(Version))
  result = call_600242.call(nil, query_600243, nil, formData_600244, nil)

var postDeleteEndpoint* = Call_PostDeleteEndpoint_600228(
    name: "postDeleteEndpoint", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=DeleteEndpoint",
    validator: validate_PostDeleteEndpoint_600229, base: "/",
    url: url_PostDeleteEndpoint_600230, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEndpoint_600212 = ref object of OpenApiRestCall_599368
proc url_GetDeleteEndpoint_600214(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteEndpoint_600213(path: JsonNode; query: JsonNode;
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
  var valid_600215 = query.getOrDefault("EndpointArn")
  valid_600215 = validateParameter(valid_600215, JString, required = true,
                                 default = nil)
  if valid_600215 != nil:
    section.add "EndpointArn", valid_600215
  var valid_600216 = query.getOrDefault("Action")
  valid_600216 = validateParameter(valid_600216, JString, required = true,
                                 default = newJString("DeleteEndpoint"))
  if valid_600216 != nil:
    section.add "Action", valid_600216
  var valid_600217 = query.getOrDefault("Version")
  valid_600217 = validateParameter(valid_600217, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600217 != nil:
    section.add "Version", valid_600217
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600218 = header.getOrDefault("X-Amz-Date")
  valid_600218 = validateParameter(valid_600218, JString, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "X-Amz-Date", valid_600218
  var valid_600219 = header.getOrDefault("X-Amz-Security-Token")
  valid_600219 = validateParameter(valid_600219, JString, required = false,
                                 default = nil)
  if valid_600219 != nil:
    section.add "X-Amz-Security-Token", valid_600219
  var valid_600220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600220 = validateParameter(valid_600220, JString, required = false,
                                 default = nil)
  if valid_600220 != nil:
    section.add "X-Amz-Content-Sha256", valid_600220
  var valid_600221 = header.getOrDefault("X-Amz-Algorithm")
  valid_600221 = validateParameter(valid_600221, JString, required = false,
                                 default = nil)
  if valid_600221 != nil:
    section.add "X-Amz-Algorithm", valid_600221
  var valid_600222 = header.getOrDefault("X-Amz-Signature")
  valid_600222 = validateParameter(valid_600222, JString, required = false,
                                 default = nil)
  if valid_600222 != nil:
    section.add "X-Amz-Signature", valid_600222
  var valid_600223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600223 = validateParameter(valid_600223, JString, required = false,
                                 default = nil)
  if valid_600223 != nil:
    section.add "X-Amz-SignedHeaders", valid_600223
  var valid_600224 = header.getOrDefault("X-Amz-Credential")
  valid_600224 = validateParameter(valid_600224, JString, required = false,
                                 default = nil)
  if valid_600224 != nil:
    section.add "X-Amz-Credential", valid_600224
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600225: Call_GetDeleteEndpoint_600212; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ## 
  let valid = call_600225.validator(path, query, header, formData, body)
  let scheme = call_600225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600225.url(scheme.get, call_600225.host, call_600225.base,
                         call_600225.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600225, url, valid)

proc call*(call_600226: Call_GetDeleteEndpoint_600212; EndpointArn: string;
          Action: string = "DeleteEndpoint"; Version: string = "2010-03-31"): Recallable =
  ## getDeleteEndpoint
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ##   EndpointArn: string (required)
  ##              : EndpointArn of endpoint to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600227 = newJObject()
  add(query_600227, "EndpointArn", newJString(EndpointArn))
  add(query_600227, "Action", newJString(Action))
  add(query_600227, "Version", newJString(Version))
  result = call_600226.call(nil, query_600227, nil, nil, nil)

var getDeleteEndpoint* = Call_GetDeleteEndpoint_600212(name: "getDeleteEndpoint",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=DeleteEndpoint", validator: validate_GetDeleteEndpoint_600213,
    base: "/", url: url_GetDeleteEndpoint_600214,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeletePlatformApplication_600261 = ref object of OpenApiRestCall_599368
proc url_PostDeletePlatformApplication_600263(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeletePlatformApplication_600262(path: JsonNode; query: JsonNode;
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
  var valid_600264 = query.getOrDefault("Action")
  valid_600264 = validateParameter(valid_600264, JString, required = true, default = newJString(
      "DeletePlatformApplication"))
  if valid_600264 != nil:
    section.add "Action", valid_600264
  var valid_600265 = query.getOrDefault("Version")
  valid_600265 = validateParameter(valid_600265, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600265 != nil:
    section.add "Version", valid_600265
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600266 = header.getOrDefault("X-Amz-Date")
  valid_600266 = validateParameter(valid_600266, JString, required = false,
                                 default = nil)
  if valid_600266 != nil:
    section.add "X-Amz-Date", valid_600266
  var valid_600267 = header.getOrDefault("X-Amz-Security-Token")
  valid_600267 = validateParameter(valid_600267, JString, required = false,
                                 default = nil)
  if valid_600267 != nil:
    section.add "X-Amz-Security-Token", valid_600267
  var valid_600268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600268 = validateParameter(valid_600268, JString, required = false,
                                 default = nil)
  if valid_600268 != nil:
    section.add "X-Amz-Content-Sha256", valid_600268
  var valid_600269 = header.getOrDefault("X-Amz-Algorithm")
  valid_600269 = validateParameter(valid_600269, JString, required = false,
                                 default = nil)
  if valid_600269 != nil:
    section.add "X-Amz-Algorithm", valid_600269
  var valid_600270 = header.getOrDefault("X-Amz-Signature")
  valid_600270 = validateParameter(valid_600270, JString, required = false,
                                 default = nil)
  if valid_600270 != nil:
    section.add "X-Amz-Signature", valid_600270
  var valid_600271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600271 = validateParameter(valid_600271, JString, required = false,
                                 default = nil)
  if valid_600271 != nil:
    section.add "X-Amz-SignedHeaders", valid_600271
  var valid_600272 = header.getOrDefault("X-Amz-Credential")
  valid_600272 = validateParameter(valid_600272, JString, required = false,
                                 default = nil)
  if valid_600272 != nil:
    section.add "X-Amz-Credential", valid_600272
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_600273 = formData.getOrDefault("PlatformApplicationArn")
  valid_600273 = validateParameter(valid_600273, JString, required = true,
                                 default = nil)
  if valid_600273 != nil:
    section.add "PlatformApplicationArn", valid_600273
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600274: Call_PostDeletePlatformApplication_600261; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_600274.validator(path, query, header, formData, body)
  let scheme = call_600274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600274.url(scheme.get, call_600274.host, call_600274.base,
                         call_600274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600274, url, valid)

proc call*(call_600275: Call_PostDeletePlatformApplication_600261;
          PlatformApplicationArn: string;
          Action: string = "DeletePlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## postDeletePlatformApplication
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  ##   Version: string (required)
  var query_600276 = newJObject()
  var formData_600277 = newJObject()
  add(query_600276, "Action", newJString(Action))
  add(formData_600277, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(query_600276, "Version", newJString(Version))
  result = call_600275.call(nil, query_600276, nil, formData_600277, nil)

var postDeletePlatformApplication* = Call_PostDeletePlatformApplication_600261(
    name: "postDeletePlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=DeletePlatformApplication",
    validator: validate_PostDeletePlatformApplication_600262, base: "/",
    url: url_PostDeletePlatformApplication_600263,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeletePlatformApplication_600245 = ref object of OpenApiRestCall_599368
proc url_GetDeletePlatformApplication_600247(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeletePlatformApplication_600246(path: JsonNode; query: JsonNode;
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
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600248 = query.getOrDefault("Action")
  valid_600248 = validateParameter(valid_600248, JString, required = true, default = newJString(
      "DeletePlatformApplication"))
  if valid_600248 != nil:
    section.add "Action", valid_600248
  var valid_600249 = query.getOrDefault("Version")
  valid_600249 = validateParameter(valid_600249, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600249 != nil:
    section.add "Version", valid_600249
  var valid_600250 = query.getOrDefault("PlatformApplicationArn")
  valid_600250 = validateParameter(valid_600250, JString, required = true,
                                 default = nil)
  if valid_600250 != nil:
    section.add "PlatformApplicationArn", valid_600250
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600251 = header.getOrDefault("X-Amz-Date")
  valid_600251 = validateParameter(valid_600251, JString, required = false,
                                 default = nil)
  if valid_600251 != nil:
    section.add "X-Amz-Date", valid_600251
  var valid_600252 = header.getOrDefault("X-Amz-Security-Token")
  valid_600252 = validateParameter(valid_600252, JString, required = false,
                                 default = nil)
  if valid_600252 != nil:
    section.add "X-Amz-Security-Token", valid_600252
  var valid_600253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600253 = validateParameter(valid_600253, JString, required = false,
                                 default = nil)
  if valid_600253 != nil:
    section.add "X-Amz-Content-Sha256", valid_600253
  var valid_600254 = header.getOrDefault("X-Amz-Algorithm")
  valid_600254 = validateParameter(valid_600254, JString, required = false,
                                 default = nil)
  if valid_600254 != nil:
    section.add "X-Amz-Algorithm", valid_600254
  var valid_600255 = header.getOrDefault("X-Amz-Signature")
  valid_600255 = validateParameter(valid_600255, JString, required = false,
                                 default = nil)
  if valid_600255 != nil:
    section.add "X-Amz-Signature", valid_600255
  var valid_600256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600256 = validateParameter(valid_600256, JString, required = false,
                                 default = nil)
  if valid_600256 != nil:
    section.add "X-Amz-SignedHeaders", valid_600256
  var valid_600257 = header.getOrDefault("X-Amz-Credential")
  valid_600257 = validateParameter(valid_600257, JString, required = false,
                                 default = nil)
  if valid_600257 != nil:
    section.add "X-Amz-Credential", valid_600257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600258: Call_GetDeletePlatformApplication_600245; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_600258.validator(path, query, header, formData, body)
  let scheme = call_600258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600258.url(scheme.get, call_600258.host, call_600258.base,
                         call_600258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600258, url, valid)

proc call*(call_600259: Call_GetDeletePlatformApplication_600245;
          PlatformApplicationArn: string;
          Action: string = "DeletePlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## getDeletePlatformApplication
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  var query_600260 = newJObject()
  add(query_600260, "Action", newJString(Action))
  add(query_600260, "Version", newJString(Version))
  add(query_600260, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_600259.call(nil, query_600260, nil, nil, nil)

var getDeletePlatformApplication* = Call_GetDeletePlatformApplication_600245(
    name: "getDeletePlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=DeletePlatformApplication",
    validator: validate_GetDeletePlatformApplication_600246, base: "/",
    url: url_GetDeletePlatformApplication_600247,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteTopic_600294 = ref object of OpenApiRestCall_599368
proc url_PostDeleteTopic_600296(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteTopic_600295(path: JsonNode; query: JsonNode;
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
  var valid_600297 = query.getOrDefault("Action")
  valid_600297 = validateParameter(valid_600297, JString, required = true,
                                 default = newJString("DeleteTopic"))
  if valid_600297 != nil:
    section.add "Action", valid_600297
  var valid_600298 = query.getOrDefault("Version")
  valid_600298 = validateParameter(valid_600298, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600298 != nil:
    section.add "Version", valid_600298
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600299 = header.getOrDefault("X-Amz-Date")
  valid_600299 = validateParameter(valid_600299, JString, required = false,
                                 default = nil)
  if valid_600299 != nil:
    section.add "X-Amz-Date", valid_600299
  var valid_600300 = header.getOrDefault("X-Amz-Security-Token")
  valid_600300 = validateParameter(valid_600300, JString, required = false,
                                 default = nil)
  if valid_600300 != nil:
    section.add "X-Amz-Security-Token", valid_600300
  var valid_600301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600301 = validateParameter(valid_600301, JString, required = false,
                                 default = nil)
  if valid_600301 != nil:
    section.add "X-Amz-Content-Sha256", valid_600301
  var valid_600302 = header.getOrDefault("X-Amz-Algorithm")
  valid_600302 = validateParameter(valid_600302, JString, required = false,
                                 default = nil)
  if valid_600302 != nil:
    section.add "X-Amz-Algorithm", valid_600302
  var valid_600303 = header.getOrDefault("X-Amz-Signature")
  valid_600303 = validateParameter(valid_600303, JString, required = false,
                                 default = nil)
  if valid_600303 != nil:
    section.add "X-Amz-Signature", valid_600303
  var valid_600304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600304 = validateParameter(valid_600304, JString, required = false,
                                 default = nil)
  if valid_600304 != nil:
    section.add "X-Amz-SignedHeaders", valid_600304
  var valid_600305 = header.getOrDefault("X-Amz-Credential")
  valid_600305 = validateParameter(valid_600305, JString, required = false,
                                 default = nil)
  if valid_600305 != nil:
    section.add "X-Amz-Credential", valid_600305
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic you want to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_600306 = formData.getOrDefault("TopicArn")
  valid_600306 = validateParameter(valid_600306, JString, required = true,
                                 default = nil)
  if valid_600306 != nil:
    section.add "TopicArn", valid_600306
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600307: Call_PostDeleteTopic_600294; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ## 
  let valid = call_600307.validator(path, query, header, formData, body)
  let scheme = call_600307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600307.url(scheme.get, call_600307.host, call_600307.base,
                         call_600307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600307, url, valid)

proc call*(call_600308: Call_PostDeleteTopic_600294; TopicArn: string;
          Action: string = "DeleteTopic"; Version: string = "2010-03-31"): Recallable =
  ## postDeleteTopic
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600309 = newJObject()
  var formData_600310 = newJObject()
  add(formData_600310, "TopicArn", newJString(TopicArn))
  add(query_600309, "Action", newJString(Action))
  add(query_600309, "Version", newJString(Version))
  result = call_600308.call(nil, query_600309, nil, formData_600310, nil)

var postDeleteTopic* = Call_PostDeleteTopic_600294(name: "postDeleteTopic",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=DeleteTopic", validator: validate_PostDeleteTopic_600295,
    base: "/", url: url_PostDeleteTopic_600296, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteTopic_600278 = ref object of OpenApiRestCall_599368
proc url_GetDeleteTopic_600280(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteTopic_600279(path: JsonNode; query: JsonNode;
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
  var valid_600281 = query.getOrDefault("Action")
  valid_600281 = validateParameter(valid_600281, JString, required = true,
                                 default = newJString("DeleteTopic"))
  if valid_600281 != nil:
    section.add "Action", valid_600281
  var valid_600282 = query.getOrDefault("TopicArn")
  valid_600282 = validateParameter(valid_600282, JString, required = true,
                                 default = nil)
  if valid_600282 != nil:
    section.add "TopicArn", valid_600282
  var valid_600283 = query.getOrDefault("Version")
  valid_600283 = validateParameter(valid_600283, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600283 != nil:
    section.add "Version", valid_600283
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600284 = header.getOrDefault("X-Amz-Date")
  valid_600284 = validateParameter(valid_600284, JString, required = false,
                                 default = nil)
  if valid_600284 != nil:
    section.add "X-Amz-Date", valid_600284
  var valid_600285 = header.getOrDefault("X-Amz-Security-Token")
  valid_600285 = validateParameter(valid_600285, JString, required = false,
                                 default = nil)
  if valid_600285 != nil:
    section.add "X-Amz-Security-Token", valid_600285
  var valid_600286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600286 = validateParameter(valid_600286, JString, required = false,
                                 default = nil)
  if valid_600286 != nil:
    section.add "X-Amz-Content-Sha256", valid_600286
  var valid_600287 = header.getOrDefault("X-Amz-Algorithm")
  valid_600287 = validateParameter(valid_600287, JString, required = false,
                                 default = nil)
  if valid_600287 != nil:
    section.add "X-Amz-Algorithm", valid_600287
  var valid_600288 = header.getOrDefault("X-Amz-Signature")
  valid_600288 = validateParameter(valid_600288, JString, required = false,
                                 default = nil)
  if valid_600288 != nil:
    section.add "X-Amz-Signature", valid_600288
  var valid_600289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600289 = validateParameter(valid_600289, JString, required = false,
                                 default = nil)
  if valid_600289 != nil:
    section.add "X-Amz-SignedHeaders", valid_600289
  var valid_600290 = header.getOrDefault("X-Amz-Credential")
  valid_600290 = validateParameter(valid_600290, JString, required = false,
                                 default = nil)
  if valid_600290 != nil:
    section.add "X-Amz-Credential", valid_600290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600291: Call_GetDeleteTopic_600278; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ## 
  let valid = call_600291.validator(path, query, header, formData, body)
  let scheme = call_600291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600291.url(scheme.get, call_600291.host, call_600291.base,
                         call_600291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600291, url, valid)

proc call*(call_600292: Call_GetDeleteTopic_600278; TopicArn: string;
          Action: string = "DeleteTopic"; Version: string = "2010-03-31"): Recallable =
  ## getDeleteTopic
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ##   Action: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to delete.
  ##   Version: string (required)
  var query_600293 = newJObject()
  add(query_600293, "Action", newJString(Action))
  add(query_600293, "TopicArn", newJString(TopicArn))
  add(query_600293, "Version", newJString(Version))
  result = call_600292.call(nil, query_600293, nil, nil, nil)

var getDeleteTopic* = Call_GetDeleteTopic_600278(name: "getDeleteTopic",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=DeleteTopic", validator: validate_GetDeleteTopic_600279,
    base: "/", url: url_GetDeleteTopic_600280, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetEndpointAttributes_600327 = ref object of OpenApiRestCall_599368
proc url_PostGetEndpointAttributes_600329(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetEndpointAttributes_600328(path: JsonNode; query: JsonNode;
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
  var valid_600330 = query.getOrDefault("Action")
  valid_600330 = validateParameter(valid_600330, JString, required = true,
                                 default = newJString("GetEndpointAttributes"))
  if valid_600330 != nil:
    section.add "Action", valid_600330
  var valid_600331 = query.getOrDefault("Version")
  valid_600331 = validateParameter(valid_600331, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600331 != nil:
    section.add "Version", valid_600331
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600332 = header.getOrDefault("X-Amz-Date")
  valid_600332 = validateParameter(valid_600332, JString, required = false,
                                 default = nil)
  if valid_600332 != nil:
    section.add "X-Amz-Date", valid_600332
  var valid_600333 = header.getOrDefault("X-Amz-Security-Token")
  valid_600333 = validateParameter(valid_600333, JString, required = false,
                                 default = nil)
  if valid_600333 != nil:
    section.add "X-Amz-Security-Token", valid_600333
  var valid_600334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600334 = validateParameter(valid_600334, JString, required = false,
                                 default = nil)
  if valid_600334 != nil:
    section.add "X-Amz-Content-Sha256", valid_600334
  var valid_600335 = header.getOrDefault("X-Amz-Algorithm")
  valid_600335 = validateParameter(valid_600335, JString, required = false,
                                 default = nil)
  if valid_600335 != nil:
    section.add "X-Amz-Algorithm", valid_600335
  var valid_600336 = header.getOrDefault("X-Amz-Signature")
  valid_600336 = validateParameter(valid_600336, JString, required = false,
                                 default = nil)
  if valid_600336 != nil:
    section.add "X-Amz-Signature", valid_600336
  var valid_600337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600337 = validateParameter(valid_600337, JString, required = false,
                                 default = nil)
  if valid_600337 != nil:
    section.add "X-Amz-SignedHeaders", valid_600337
  var valid_600338 = header.getOrDefault("X-Amz-Credential")
  valid_600338 = validateParameter(valid_600338, JString, required = false,
                                 default = nil)
  if valid_600338 != nil:
    section.add "X-Amz-Credential", valid_600338
  result.add "header", section
  ## parameters in `formData` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_600339 = formData.getOrDefault("EndpointArn")
  valid_600339 = validateParameter(valid_600339, JString, required = true,
                                 default = nil)
  if valid_600339 != nil:
    section.add "EndpointArn", valid_600339
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600340: Call_PostGetEndpointAttributes_600327; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_600340.validator(path, query, header, formData, body)
  let scheme = call_600340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600340.url(scheme.get, call_600340.host, call_600340.base,
                         call_600340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600340, url, valid)

proc call*(call_600341: Call_PostGetEndpointAttributes_600327; EndpointArn: string;
          Action: string = "GetEndpointAttributes"; Version: string = "2010-03-31"): Recallable =
  ## postGetEndpointAttributes
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   EndpointArn: string (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  ##   Version: string (required)
  var query_600342 = newJObject()
  var formData_600343 = newJObject()
  add(query_600342, "Action", newJString(Action))
  add(formData_600343, "EndpointArn", newJString(EndpointArn))
  add(query_600342, "Version", newJString(Version))
  result = call_600341.call(nil, query_600342, nil, formData_600343, nil)

var postGetEndpointAttributes* = Call_PostGetEndpointAttributes_600327(
    name: "postGetEndpointAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetEndpointAttributes",
    validator: validate_PostGetEndpointAttributes_600328, base: "/",
    url: url_PostGetEndpointAttributes_600329,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetEndpointAttributes_600311 = ref object of OpenApiRestCall_599368
proc url_GetGetEndpointAttributes_600313(protocol: Scheme; host: string;
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

proc validate_GetGetEndpointAttributes_600312(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600314 = query.getOrDefault("EndpointArn")
  valid_600314 = validateParameter(valid_600314, JString, required = true,
                                 default = nil)
  if valid_600314 != nil:
    section.add "EndpointArn", valid_600314
  var valid_600315 = query.getOrDefault("Action")
  valid_600315 = validateParameter(valid_600315, JString, required = true,
                                 default = newJString("GetEndpointAttributes"))
  if valid_600315 != nil:
    section.add "Action", valid_600315
  var valid_600316 = query.getOrDefault("Version")
  valid_600316 = validateParameter(valid_600316, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600316 != nil:
    section.add "Version", valid_600316
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600317 = header.getOrDefault("X-Amz-Date")
  valid_600317 = validateParameter(valid_600317, JString, required = false,
                                 default = nil)
  if valid_600317 != nil:
    section.add "X-Amz-Date", valid_600317
  var valid_600318 = header.getOrDefault("X-Amz-Security-Token")
  valid_600318 = validateParameter(valid_600318, JString, required = false,
                                 default = nil)
  if valid_600318 != nil:
    section.add "X-Amz-Security-Token", valid_600318
  var valid_600319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600319 = validateParameter(valid_600319, JString, required = false,
                                 default = nil)
  if valid_600319 != nil:
    section.add "X-Amz-Content-Sha256", valid_600319
  var valid_600320 = header.getOrDefault("X-Amz-Algorithm")
  valid_600320 = validateParameter(valid_600320, JString, required = false,
                                 default = nil)
  if valid_600320 != nil:
    section.add "X-Amz-Algorithm", valid_600320
  var valid_600321 = header.getOrDefault("X-Amz-Signature")
  valid_600321 = validateParameter(valid_600321, JString, required = false,
                                 default = nil)
  if valid_600321 != nil:
    section.add "X-Amz-Signature", valid_600321
  var valid_600322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600322 = validateParameter(valid_600322, JString, required = false,
                                 default = nil)
  if valid_600322 != nil:
    section.add "X-Amz-SignedHeaders", valid_600322
  var valid_600323 = header.getOrDefault("X-Amz-Credential")
  valid_600323 = validateParameter(valid_600323, JString, required = false,
                                 default = nil)
  if valid_600323 != nil:
    section.add "X-Amz-Credential", valid_600323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600324: Call_GetGetEndpointAttributes_600311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_600324.validator(path, query, header, formData, body)
  let scheme = call_600324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600324.url(scheme.get, call_600324.host, call_600324.base,
                         call_600324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600324, url, valid)

proc call*(call_600325: Call_GetGetEndpointAttributes_600311; EndpointArn: string;
          Action: string = "GetEndpointAttributes"; Version: string = "2010-03-31"): Recallable =
  ## getGetEndpointAttributes
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   EndpointArn: string (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600326 = newJObject()
  add(query_600326, "EndpointArn", newJString(EndpointArn))
  add(query_600326, "Action", newJString(Action))
  add(query_600326, "Version", newJString(Version))
  result = call_600325.call(nil, query_600326, nil, nil, nil)

var getGetEndpointAttributes* = Call_GetGetEndpointAttributes_600311(
    name: "getGetEndpointAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetEndpointAttributes",
    validator: validate_GetGetEndpointAttributes_600312, base: "/",
    url: url_GetGetEndpointAttributes_600313, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetPlatformApplicationAttributes_600360 = ref object of OpenApiRestCall_599368
proc url_PostGetPlatformApplicationAttributes_600362(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetPlatformApplicationAttributes_600361(path: JsonNode;
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
  var valid_600363 = query.getOrDefault("Action")
  valid_600363 = validateParameter(valid_600363, JString, required = true, default = newJString(
      "GetPlatformApplicationAttributes"))
  if valid_600363 != nil:
    section.add "Action", valid_600363
  var valid_600364 = query.getOrDefault("Version")
  valid_600364 = validateParameter(valid_600364, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600364 != nil:
    section.add "Version", valid_600364
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600365 = header.getOrDefault("X-Amz-Date")
  valid_600365 = validateParameter(valid_600365, JString, required = false,
                                 default = nil)
  if valid_600365 != nil:
    section.add "X-Amz-Date", valid_600365
  var valid_600366 = header.getOrDefault("X-Amz-Security-Token")
  valid_600366 = validateParameter(valid_600366, JString, required = false,
                                 default = nil)
  if valid_600366 != nil:
    section.add "X-Amz-Security-Token", valid_600366
  var valid_600367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600367 = validateParameter(valid_600367, JString, required = false,
                                 default = nil)
  if valid_600367 != nil:
    section.add "X-Amz-Content-Sha256", valid_600367
  var valid_600368 = header.getOrDefault("X-Amz-Algorithm")
  valid_600368 = validateParameter(valid_600368, JString, required = false,
                                 default = nil)
  if valid_600368 != nil:
    section.add "X-Amz-Algorithm", valid_600368
  var valid_600369 = header.getOrDefault("X-Amz-Signature")
  valid_600369 = validateParameter(valid_600369, JString, required = false,
                                 default = nil)
  if valid_600369 != nil:
    section.add "X-Amz-Signature", valid_600369
  var valid_600370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600370 = validateParameter(valid_600370, JString, required = false,
                                 default = nil)
  if valid_600370 != nil:
    section.add "X-Amz-SignedHeaders", valid_600370
  var valid_600371 = header.getOrDefault("X-Amz-Credential")
  valid_600371 = validateParameter(valid_600371, JString, required = false,
                                 default = nil)
  if valid_600371 != nil:
    section.add "X-Amz-Credential", valid_600371
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_600372 = formData.getOrDefault("PlatformApplicationArn")
  valid_600372 = validateParameter(valid_600372, JString, required = true,
                                 default = nil)
  if valid_600372 != nil:
    section.add "PlatformApplicationArn", valid_600372
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600373: Call_PostGetPlatformApplicationAttributes_600360;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_600373.validator(path, query, header, formData, body)
  let scheme = call_600373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600373.url(scheme.get, call_600373.host, call_600373.base,
                         call_600373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600373, url, valid)

proc call*(call_600374: Call_PostGetPlatformApplicationAttributes_600360;
          PlatformApplicationArn: string;
          Action: string = "GetPlatformApplicationAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetPlatformApplicationAttributes
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  ##   Version: string (required)
  var query_600375 = newJObject()
  var formData_600376 = newJObject()
  add(query_600375, "Action", newJString(Action))
  add(formData_600376, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(query_600375, "Version", newJString(Version))
  result = call_600374.call(nil, query_600375, nil, formData_600376, nil)

var postGetPlatformApplicationAttributes* = Call_PostGetPlatformApplicationAttributes_600360(
    name: "postGetPlatformApplicationAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetPlatformApplicationAttributes",
    validator: validate_PostGetPlatformApplicationAttributes_600361, base: "/",
    url: url_PostGetPlatformApplicationAttributes_600362,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetPlatformApplicationAttributes_600344 = ref object of OpenApiRestCall_599368
proc url_GetGetPlatformApplicationAttributes_600346(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetPlatformApplicationAttributes_600345(path: JsonNode;
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
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600347 = query.getOrDefault("Action")
  valid_600347 = validateParameter(valid_600347, JString, required = true, default = newJString(
      "GetPlatformApplicationAttributes"))
  if valid_600347 != nil:
    section.add "Action", valid_600347
  var valid_600348 = query.getOrDefault("Version")
  valid_600348 = validateParameter(valid_600348, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600348 != nil:
    section.add "Version", valid_600348
  var valid_600349 = query.getOrDefault("PlatformApplicationArn")
  valid_600349 = validateParameter(valid_600349, JString, required = true,
                                 default = nil)
  if valid_600349 != nil:
    section.add "PlatformApplicationArn", valid_600349
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600350 = header.getOrDefault("X-Amz-Date")
  valid_600350 = validateParameter(valid_600350, JString, required = false,
                                 default = nil)
  if valid_600350 != nil:
    section.add "X-Amz-Date", valid_600350
  var valid_600351 = header.getOrDefault("X-Amz-Security-Token")
  valid_600351 = validateParameter(valid_600351, JString, required = false,
                                 default = nil)
  if valid_600351 != nil:
    section.add "X-Amz-Security-Token", valid_600351
  var valid_600352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600352 = validateParameter(valid_600352, JString, required = false,
                                 default = nil)
  if valid_600352 != nil:
    section.add "X-Amz-Content-Sha256", valid_600352
  var valid_600353 = header.getOrDefault("X-Amz-Algorithm")
  valid_600353 = validateParameter(valid_600353, JString, required = false,
                                 default = nil)
  if valid_600353 != nil:
    section.add "X-Amz-Algorithm", valid_600353
  var valid_600354 = header.getOrDefault("X-Amz-Signature")
  valid_600354 = validateParameter(valid_600354, JString, required = false,
                                 default = nil)
  if valid_600354 != nil:
    section.add "X-Amz-Signature", valid_600354
  var valid_600355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600355 = validateParameter(valid_600355, JString, required = false,
                                 default = nil)
  if valid_600355 != nil:
    section.add "X-Amz-SignedHeaders", valid_600355
  var valid_600356 = header.getOrDefault("X-Amz-Credential")
  valid_600356 = validateParameter(valid_600356, JString, required = false,
                                 default = nil)
  if valid_600356 != nil:
    section.add "X-Amz-Credential", valid_600356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600357: Call_GetGetPlatformApplicationAttributes_600344;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_600357.validator(path, query, header, formData, body)
  let scheme = call_600357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600357.url(scheme.get, call_600357.host, call_600357.base,
                         call_600357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600357, url, valid)

proc call*(call_600358: Call_GetGetPlatformApplicationAttributes_600344;
          PlatformApplicationArn: string;
          Action: string = "GetPlatformApplicationAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getGetPlatformApplicationAttributes
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  var query_600359 = newJObject()
  add(query_600359, "Action", newJString(Action))
  add(query_600359, "Version", newJString(Version))
  add(query_600359, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_600358.call(nil, query_600359, nil, nil, nil)

var getGetPlatformApplicationAttributes* = Call_GetGetPlatformApplicationAttributes_600344(
    name: "getGetPlatformApplicationAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetPlatformApplicationAttributes",
    validator: validate_GetGetPlatformApplicationAttributes_600345, base: "/",
    url: url_GetGetPlatformApplicationAttributes_600346,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetSMSAttributes_600393 = ref object of OpenApiRestCall_599368
proc url_PostGetSMSAttributes_600395(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetSMSAttributes_600394(path: JsonNode; query: JsonNode;
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
  var valid_600396 = query.getOrDefault("Action")
  valid_600396 = validateParameter(valid_600396, JString, required = true,
                                 default = newJString("GetSMSAttributes"))
  if valid_600396 != nil:
    section.add "Action", valid_600396
  var valid_600397 = query.getOrDefault("Version")
  valid_600397 = validateParameter(valid_600397, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600397 != nil:
    section.add "Version", valid_600397
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600398 = header.getOrDefault("X-Amz-Date")
  valid_600398 = validateParameter(valid_600398, JString, required = false,
                                 default = nil)
  if valid_600398 != nil:
    section.add "X-Amz-Date", valid_600398
  var valid_600399 = header.getOrDefault("X-Amz-Security-Token")
  valid_600399 = validateParameter(valid_600399, JString, required = false,
                                 default = nil)
  if valid_600399 != nil:
    section.add "X-Amz-Security-Token", valid_600399
  var valid_600400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600400 = validateParameter(valid_600400, JString, required = false,
                                 default = nil)
  if valid_600400 != nil:
    section.add "X-Amz-Content-Sha256", valid_600400
  var valid_600401 = header.getOrDefault("X-Amz-Algorithm")
  valid_600401 = validateParameter(valid_600401, JString, required = false,
                                 default = nil)
  if valid_600401 != nil:
    section.add "X-Amz-Algorithm", valid_600401
  var valid_600402 = header.getOrDefault("X-Amz-Signature")
  valid_600402 = validateParameter(valid_600402, JString, required = false,
                                 default = nil)
  if valid_600402 != nil:
    section.add "X-Amz-Signature", valid_600402
  var valid_600403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600403 = validateParameter(valid_600403, JString, required = false,
                                 default = nil)
  if valid_600403 != nil:
    section.add "X-Amz-SignedHeaders", valid_600403
  var valid_600404 = header.getOrDefault("X-Amz-Credential")
  valid_600404 = validateParameter(valid_600404, JString, required = false,
                                 default = nil)
  if valid_600404 != nil:
    section.add "X-Amz-Credential", valid_600404
  result.add "header", section
  ## parameters in `formData` object:
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  section = newJObject()
  var valid_600405 = formData.getOrDefault("attributes")
  valid_600405 = validateParameter(valid_600405, JArray, required = false,
                                 default = nil)
  if valid_600405 != nil:
    section.add "attributes", valid_600405
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600406: Call_PostGetSMSAttributes_600393; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  let valid = call_600406.validator(path, query, header, formData, body)
  let scheme = call_600406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600406.url(scheme.get, call_600406.host, call_600406.base,
                         call_600406.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600406, url, valid)

proc call*(call_600407: Call_PostGetSMSAttributes_600393;
          attributes: JsonNode = nil; Action: string = "GetSMSAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetSMSAttributes
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600408 = newJObject()
  var formData_600409 = newJObject()
  if attributes != nil:
    formData_600409.add "attributes", attributes
  add(query_600408, "Action", newJString(Action))
  add(query_600408, "Version", newJString(Version))
  result = call_600407.call(nil, query_600408, nil, formData_600409, nil)

var postGetSMSAttributes* = Call_PostGetSMSAttributes_600393(
    name: "postGetSMSAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetSMSAttributes",
    validator: validate_PostGetSMSAttributes_600394, base: "/",
    url: url_PostGetSMSAttributes_600395, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetSMSAttributes_600377 = ref object of OpenApiRestCall_599368
proc url_GetGetSMSAttributes_600379(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetSMSAttributes_600378(path: JsonNode; query: JsonNode;
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
  var valid_600380 = query.getOrDefault("attributes")
  valid_600380 = validateParameter(valid_600380, JArray, required = false,
                                 default = nil)
  if valid_600380 != nil:
    section.add "attributes", valid_600380
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600381 = query.getOrDefault("Action")
  valid_600381 = validateParameter(valid_600381, JString, required = true,
                                 default = newJString("GetSMSAttributes"))
  if valid_600381 != nil:
    section.add "Action", valid_600381
  var valid_600382 = query.getOrDefault("Version")
  valid_600382 = validateParameter(valid_600382, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600382 != nil:
    section.add "Version", valid_600382
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600383 = header.getOrDefault("X-Amz-Date")
  valid_600383 = validateParameter(valid_600383, JString, required = false,
                                 default = nil)
  if valid_600383 != nil:
    section.add "X-Amz-Date", valid_600383
  var valid_600384 = header.getOrDefault("X-Amz-Security-Token")
  valid_600384 = validateParameter(valid_600384, JString, required = false,
                                 default = nil)
  if valid_600384 != nil:
    section.add "X-Amz-Security-Token", valid_600384
  var valid_600385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600385 = validateParameter(valid_600385, JString, required = false,
                                 default = nil)
  if valid_600385 != nil:
    section.add "X-Amz-Content-Sha256", valid_600385
  var valid_600386 = header.getOrDefault("X-Amz-Algorithm")
  valid_600386 = validateParameter(valid_600386, JString, required = false,
                                 default = nil)
  if valid_600386 != nil:
    section.add "X-Amz-Algorithm", valid_600386
  var valid_600387 = header.getOrDefault("X-Amz-Signature")
  valid_600387 = validateParameter(valid_600387, JString, required = false,
                                 default = nil)
  if valid_600387 != nil:
    section.add "X-Amz-Signature", valid_600387
  var valid_600388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600388 = validateParameter(valid_600388, JString, required = false,
                                 default = nil)
  if valid_600388 != nil:
    section.add "X-Amz-SignedHeaders", valid_600388
  var valid_600389 = header.getOrDefault("X-Amz-Credential")
  valid_600389 = validateParameter(valid_600389, JString, required = false,
                                 default = nil)
  if valid_600389 != nil:
    section.add "X-Amz-Credential", valid_600389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600390: Call_GetGetSMSAttributes_600377; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  let valid = call_600390.validator(path, query, header, formData, body)
  let scheme = call_600390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600390.url(scheme.get, call_600390.host, call_600390.base,
                         call_600390.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600390, url, valid)

proc call*(call_600391: Call_GetGetSMSAttributes_600377;
          attributes: JsonNode = nil; Action: string = "GetSMSAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getGetSMSAttributes
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600392 = newJObject()
  if attributes != nil:
    query_600392.add "attributes", attributes
  add(query_600392, "Action", newJString(Action))
  add(query_600392, "Version", newJString(Version))
  result = call_600391.call(nil, query_600392, nil, nil, nil)

var getGetSMSAttributes* = Call_GetGetSMSAttributes_600377(
    name: "getGetSMSAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetSMSAttributes",
    validator: validate_GetGetSMSAttributes_600378, base: "/",
    url: url_GetGetSMSAttributes_600379, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetSubscriptionAttributes_600426 = ref object of OpenApiRestCall_599368
proc url_PostGetSubscriptionAttributes_600428(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetSubscriptionAttributes_600427(path: JsonNode; query: JsonNode;
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
  var valid_600429 = query.getOrDefault("Action")
  valid_600429 = validateParameter(valid_600429, JString, required = true, default = newJString(
      "GetSubscriptionAttributes"))
  if valid_600429 != nil:
    section.add "Action", valid_600429
  var valid_600430 = query.getOrDefault("Version")
  valid_600430 = validateParameter(valid_600430, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600430 != nil:
    section.add "Version", valid_600430
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600431 = header.getOrDefault("X-Amz-Date")
  valid_600431 = validateParameter(valid_600431, JString, required = false,
                                 default = nil)
  if valid_600431 != nil:
    section.add "X-Amz-Date", valid_600431
  var valid_600432 = header.getOrDefault("X-Amz-Security-Token")
  valid_600432 = validateParameter(valid_600432, JString, required = false,
                                 default = nil)
  if valid_600432 != nil:
    section.add "X-Amz-Security-Token", valid_600432
  var valid_600433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600433 = validateParameter(valid_600433, JString, required = false,
                                 default = nil)
  if valid_600433 != nil:
    section.add "X-Amz-Content-Sha256", valid_600433
  var valid_600434 = header.getOrDefault("X-Amz-Algorithm")
  valid_600434 = validateParameter(valid_600434, JString, required = false,
                                 default = nil)
  if valid_600434 != nil:
    section.add "X-Amz-Algorithm", valid_600434
  var valid_600435 = header.getOrDefault("X-Amz-Signature")
  valid_600435 = validateParameter(valid_600435, JString, required = false,
                                 default = nil)
  if valid_600435 != nil:
    section.add "X-Amz-Signature", valid_600435
  var valid_600436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600436 = validateParameter(valid_600436, JString, required = false,
                                 default = nil)
  if valid_600436 != nil:
    section.add "X-Amz-SignedHeaders", valid_600436
  var valid_600437 = header.getOrDefault("X-Amz-Credential")
  valid_600437 = validateParameter(valid_600437, JString, required = false,
                                 default = nil)
  if valid_600437 != nil:
    section.add "X-Amz-Credential", valid_600437
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionArn` field"
  var valid_600438 = formData.getOrDefault("SubscriptionArn")
  valid_600438 = validateParameter(valid_600438, JString, required = true,
                                 default = nil)
  if valid_600438 != nil:
    section.add "SubscriptionArn", valid_600438
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600439: Call_PostGetSubscriptionAttributes_600426; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a subscription.
  ## 
  let valid = call_600439.validator(path, query, header, formData, body)
  let scheme = call_600439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600439.url(scheme.get, call_600439.host, call_600439.base,
                         call_600439.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600439, url, valid)

proc call*(call_600440: Call_PostGetSubscriptionAttributes_600426;
          SubscriptionArn: string; Action: string = "GetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetSubscriptionAttributes
  ## Returns all of the properties of a subscription.
  ##   Action: string (required)
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  ##   Version: string (required)
  var query_600441 = newJObject()
  var formData_600442 = newJObject()
  add(query_600441, "Action", newJString(Action))
  add(formData_600442, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_600441, "Version", newJString(Version))
  result = call_600440.call(nil, query_600441, nil, formData_600442, nil)

var postGetSubscriptionAttributes* = Call_PostGetSubscriptionAttributes_600426(
    name: "postGetSubscriptionAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetSubscriptionAttributes",
    validator: validate_PostGetSubscriptionAttributes_600427, base: "/",
    url: url_PostGetSubscriptionAttributes_600428,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetSubscriptionAttributes_600410 = ref object of OpenApiRestCall_599368
proc url_GetGetSubscriptionAttributes_600412(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetSubscriptionAttributes_600411(path: JsonNode; query: JsonNode;
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
  var valid_600413 = query.getOrDefault("SubscriptionArn")
  valid_600413 = validateParameter(valid_600413, JString, required = true,
                                 default = nil)
  if valid_600413 != nil:
    section.add "SubscriptionArn", valid_600413
  var valid_600414 = query.getOrDefault("Action")
  valid_600414 = validateParameter(valid_600414, JString, required = true, default = newJString(
      "GetSubscriptionAttributes"))
  if valid_600414 != nil:
    section.add "Action", valid_600414
  var valid_600415 = query.getOrDefault("Version")
  valid_600415 = validateParameter(valid_600415, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600415 != nil:
    section.add "Version", valid_600415
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600416 = header.getOrDefault("X-Amz-Date")
  valid_600416 = validateParameter(valid_600416, JString, required = false,
                                 default = nil)
  if valid_600416 != nil:
    section.add "X-Amz-Date", valid_600416
  var valid_600417 = header.getOrDefault("X-Amz-Security-Token")
  valid_600417 = validateParameter(valid_600417, JString, required = false,
                                 default = nil)
  if valid_600417 != nil:
    section.add "X-Amz-Security-Token", valid_600417
  var valid_600418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600418 = validateParameter(valid_600418, JString, required = false,
                                 default = nil)
  if valid_600418 != nil:
    section.add "X-Amz-Content-Sha256", valid_600418
  var valid_600419 = header.getOrDefault("X-Amz-Algorithm")
  valid_600419 = validateParameter(valid_600419, JString, required = false,
                                 default = nil)
  if valid_600419 != nil:
    section.add "X-Amz-Algorithm", valid_600419
  var valid_600420 = header.getOrDefault("X-Amz-Signature")
  valid_600420 = validateParameter(valid_600420, JString, required = false,
                                 default = nil)
  if valid_600420 != nil:
    section.add "X-Amz-Signature", valid_600420
  var valid_600421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600421 = validateParameter(valid_600421, JString, required = false,
                                 default = nil)
  if valid_600421 != nil:
    section.add "X-Amz-SignedHeaders", valid_600421
  var valid_600422 = header.getOrDefault("X-Amz-Credential")
  valid_600422 = validateParameter(valid_600422, JString, required = false,
                                 default = nil)
  if valid_600422 != nil:
    section.add "X-Amz-Credential", valid_600422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600423: Call_GetGetSubscriptionAttributes_600410; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a subscription.
  ## 
  let valid = call_600423.validator(path, query, header, formData, body)
  let scheme = call_600423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600423.url(scheme.get, call_600423.host, call_600423.base,
                         call_600423.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600423, url, valid)

proc call*(call_600424: Call_GetGetSubscriptionAttributes_600410;
          SubscriptionArn: string; Action: string = "GetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getGetSubscriptionAttributes
  ## Returns all of the properties of a subscription.
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600425 = newJObject()
  add(query_600425, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_600425, "Action", newJString(Action))
  add(query_600425, "Version", newJString(Version))
  result = call_600424.call(nil, query_600425, nil, nil, nil)

var getGetSubscriptionAttributes* = Call_GetGetSubscriptionAttributes_600410(
    name: "getGetSubscriptionAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetSubscriptionAttributes",
    validator: validate_GetGetSubscriptionAttributes_600411, base: "/",
    url: url_GetGetSubscriptionAttributes_600412,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetTopicAttributes_600459 = ref object of OpenApiRestCall_599368
proc url_PostGetTopicAttributes_600461(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetTopicAttributes_600460(path: JsonNode; query: JsonNode;
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
  var valid_600462 = query.getOrDefault("Action")
  valid_600462 = validateParameter(valid_600462, JString, required = true,
                                 default = newJString("GetTopicAttributes"))
  if valid_600462 != nil:
    section.add "Action", valid_600462
  var valid_600463 = query.getOrDefault("Version")
  valid_600463 = validateParameter(valid_600463, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600463 != nil:
    section.add "Version", valid_600463
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600464 = header.getOrDefault("X-Amz-Date")
  valid_600464 = validateParameter(valid_600464, JString, required = false,
                                 default = nil)
  if valid_600464 != nil:
    section.add "X-Amz-Date", valid_600464
  var valid_600465 = header.getOrDefault("X-Amz-Security-Token")
  valid_600465 = validateParameter(valid_600465, JString, required = false,
                                 default = nil)
  if valid_600465 != nil:
    section.add "X-Amz-Security-Token", valid_600465
  var valid_600466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600466 = validateParameter(valid_600466, JString, required = false,
                                 default = nil)
  if valid_600466 != nil:
    section.add "X-Amz-Content-Sha256", valid_600466
  var valid_600467 = header.getOrDefault("X-Amz-Algorithm")
  valid_600467 = validateParameter(valid_600467, JString, required = false,
                                 default = nil)
  if valid_600467 != nil:
    section.add "X-Amz-Algorithm", valid_600467
  var valid_600468 = header.getOrDefault("X-Amz-Signature")
  valid_600468 = validateParameter(valid_600468, JString, required = false,
                                 default = nil)
  if valid_600468 != nil:
    section.add "X-Amz-Signature", valid_600468
  var valid_600469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600469 = validateParameter(valid_600469, JString, required = false,
                                 default = nil)
  if valid_600469 != nil:
    section.add "X-Amz-SignedHeaders", valid_600469
  var valid_600470 = header.getOrDefault("X-Amz-Credential")
  valid_600470 = validateParameter(valid_600470, JString, required = false,
                                 default = nil)
  if valid_600470 != nil:
    section.add "X-Amz-Credential", valid_600470
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose properties you want to get.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_600471 = formData.getOrDefault("TopicArn")
  valid_600471 = validateParameter(valid_600471, JString, required = true,
                                 default = nil)
  if valid_600471 != nil:
    section.add "TopicArn", valid_600471
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600472: Call_PostGetTopicAttributes_600459; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ## 
  let valid = call_600472.validator(path, query, header, formData, body)
  let scheme = call_600472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600472.url(scheme.get, call_600472.host, call_600472.base,
                         call_600472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600472, url, valid)

proc call*(call_600473: Call_PostGetTopicAttributes_600459; TopicArn: string;
          Action: string = "GetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## postGetTopicAttributes
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose properties you want to get.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600474 = newJObject()
  var formData_600475 = newJObject()
  add(formData_600475, "TopicArn", newJString(TopicArn))
  add(query_600474, "Action", newJString(Action))
  add(query_600474, "Version", newJString(Version))
  result = call_600473.call(nil, query_600474, nil, formData_600475, nil)

var postGetTopicAttributes* = Call_PostGetTopicAttributes_600459(
    name: "postGetTopicAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetTopicAttributes",
    validator: validate_PostGetTopicAttributes_600460, base: "/",
    url: url_PostGetTopicAttributes_600461, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetTopicAttributes_600443 = ref object of OpenApiRestCall_599368
proc url_GetGetTopicAttributes_600445(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetTopicAttributes_600444(path: JsonNode; query: JsonNode;
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
  var valid_600446 = query.getOrDefault("Action")
  valid_600446 = validateParameter(valid_600446, JString, required = true,
                                 default = newJString("GetTopicAttributes"))
  if valid_600446 != nil:
    section.add "Action", valid_600446
  var valid_600447 = query.getOrDefault("TopicArn")
  valid_600447 = validateParameter(valid_600447, JString, required = true,
                                 default = nil)
  if valid_600447 != nil:
    section.add "TopicArn", valid_600447
  var valid_600448 = query.getOrDefault("Version")
  valid_600448 = validateParameter(valid_600448, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600448 != nil:
    section.add "Version", valid_600448
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600449 = header.getOrDefault("X-Amz-Date")
  valid_600449 = validateParameter(valid_600449, JString, required = false,
                                 default = nil)
  if valid_600449 != nil:
    section.add "X-Amz-Date", valid_600449
  var valid_600450 = header.getOrDefault("X-Amz-Security-Token")
  valid_600450 = validateParameter(valid_600450, JString, required = false,
                                 default = nil)
  if valid_600450 != nil:
    section.add "X-Amz-Security-Token", valid_600450
  var valid_600451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600451 = validateParameter(valid_600451, JString, required = false,
                                 default = nil)
  if valid_600451 != nil:
    section.add "X-Amz-Content-Sha256", valid_600451
  var valid_600452 = header.getOrDefault("X-Amz-Algorithm")
  valid_600452 = validateParameter(valid_600452, JString, required = false,
                                 default = nil)
  if valid_600452 != nil:
    section.add "X-Amz-Algorithm", valid_600452
  var valid_600453 = header.getOrDefault("X-Amz-Signature")
  valid_600453 = validateParameter(valid_600453, JString, required = false,
                                 default = nil)
  if valid_600453 != nil:
    section.add "X-Amz-Signature", valid_600453
  var valid_600454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600454 = validateParameter(valid_600454, JString, required = false,
                                 default = nil)
  if valid_600454 != nil:
    section.add "X-Amz-SignedHeaders", valid_600454
  var valid_600455 = header.getOrDefault("X-Amz-Credential")
  valid_600455 = validateParameter(valid_600455, JString, required = false,
                                 default = nil)
  if valid_600455 != nil:
    section.add "X-Amz-Credential", valid_600455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600456: Call_GetGetTopicAttributes_600443; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ## 
  let valid = call_600456.validator(path, query, header, formData, body)
  let scheme = call_600456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600456.url(scheme.get, call_600456.host, call_600456.base,
                         call_600456.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600456, url, valid)

proc call*(call_600457: Call_GetGetTopicAttributes_600443; TopicArn: string;
          Action: string = "GetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## getGetTopicAttributes
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ##   Action: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose properties you want to get.
  ##   Version: string (required)
  var query_600458 = newJObject()
  add(query_600458, "Action", newJString(Action))
  add(query_600458, "TopicArn", newJString(TopicArn))
  add(query_600458, "Version", newJString(Version))
  result = call_600457.call(nil, query_600458, nil, nil, nil)

var getGetTopicAttributes* = Call_GetGetTopicAttributes_600443(
    name: "getGetTopicAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetTopicAttributes",
    validator: validate_GetGetTopicAttributes_600444, base: "/",
    url: url_GetGetTopicAttributes_600445, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListEndpointsByPlatformApplication_600493 = ref object of OpenApiRestCall_599368
proc url_PostListEndpointsByPlatformApplication_600495(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListEndpointsByPlatformApplication_600494(path: JsonNode;
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
  var valid_600496 = query.getOrDefault("Action")
  valid_600496 = validateParameter(valid_600496, JString, required = true, default = newJString(
      "ListEndpointsByPlatformApplication"))
  if valid_600496 != nil:
    section.add "Action", valid_600496
  var valid_600497 = query.getOrDefault("Version")
  valid_600497 = validateParameter(valid_600497, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600497 != nil:
    section.add "Version", valid_600497
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600498 = header.getOrDefault("X-Amz-Date")
  valid_600498 = validateParameter(valid_600498, JString, required = false,
                                 default = nil)
  if valid_600498 != nil:
    section.add "X-Amz-Date", valid_600498
  var valid_600499 = header.getOrDefault("X-Amz-Security-Token")
  valid_600499 = validateParameter(valid_600499, JString, required = false,
                                 default = nil)
  if valid_600499 != nil:
    section.add "X-Amz-Security-Token", valid_600499
  var valid_600500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600500 = validateParameter(valid_600500, JString, required = false,
                                 default = nil)
  if valid_600500 != nil:
    section.add "X-Amz-Content-Sha256", valid_600500
  var valid_600501 = header.getOrDefault("X-Amz-Algorithm")
  valid_600501 = validateParameter(valid_600501, JString, required = false,
                                 default = nil)
  if valid_600501 != nil:
    section.add "X-Amz-Algorithm", valid_600501
  var valid_600502 = header.getOrDefault("X-Amz-Signature")
  valid_600502 = validateParameter(valid_600502, JString, required = false,
                                 default = nil)
  if valid_600502 != nil:
    section.add "X-Amz-Signature", valid_600502
  var valid_600503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600503 = validateParameter(valid_600503, JString, required = false,
                                 default = nil)
  if valid_600503 != nil:
    section.add "X-Amz-SignedHeaders", valid_600503
  var valid_600504 = header.getOrDefault("X-Amz-Credential")
  valid_600504 = validateParameter(valid_600504, JString, required = false,
                                 default = nil)
  if valid_600504 != nil:
    section.add "X-Amz-Credential", valid_600504
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListEndpointsByPlatformApplication action to retrieve additional records that are available after the first page results.
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  section = newJObject()
  var valid_600505 = formData.getOrDefault("NextToken")
  valid_600505 = validateParameter(valid_600505, JString, required = false,
                                 default = nil)
  if valid_600505 != nil:
    section.add "NextToken", valid_600505
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_600506 = formData.getOrDefault("PlatformApplicationArn")
  valid_600506 = validateParameter(valid_600506, JString, required = true,
                                 default = nil)
  if valid_600506 != nil:
    section.add "PlatformApplicationArn", valid_600506
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600507: Call_PostListEndpointsByPlatformApplication_600493;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as FCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_600507.validator(path, query, header, formData, body)
  let scheme = call_600507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600507.url(scheme.get, call_600507.host, call_600507.base,
                         call_600507.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600507, url, valid)

proc call*(call_600508: Call_PostListEndpointsByPlatformApplication_600493;
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
  var query_600509 = newJObject()
  var formData_600510 = newJObject()
  add(formData_600510, "NextToken", newJString(NextToken))
  add(query_600509, "Action", newJString(Action))
  add(formData_600510, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(query_600509, "Version", newJString(Version))
  result = call_600508.call(nil, query_600509, nil, formData_600510, nil)

var postListEndpointsByPlatformApplication* = Call_PostListEndpointsByPlatformApplication_600493(
    name: "postListEndpointsByPlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com",
    route: "/#Action=ListEndpointsByPlatformApplication",
    validator: validate_PostListEndpointsByPlatformApplication_600494, base: "/",
    url: url_PostListEndpointsByPlatformApplication_600495,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListEndpointsByPlatformApplication_600476 = ref object of OpenApiRestCall_599368
proc url_GetListEndpointsByPlatformApplication_600478(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListEndpointsByPlatformApplication_600477(path: JsonNode;
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
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  section = newJObject()
  var valid_600479 = query.getOrDefault("NextToken")
  valid_600479 = validateParameter(valid_600479, JString, required = false,
                                 default = nil)
  if valid_600479 != nil:
    section.add "NextToken", valid_600479
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600480 = query.getOrDefault("Action")
  valid_600480 = validateParameter(valid_600480, JString, required = true, default = newJString(
      "ListEndpointsByPlatformApplication"))
  if valid_600480 != nil:
    section.add "Action", valid_600480
  var valid_600481 = query.getOrDefault("Version")
  valid_600481 = validateParameter(valid_600481, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600481 != nil:
    section.add "Version", valid_600481
  var valid_600482 = query.getOrDefault("PlatformApplicationArn")
  valid_600482 = validateParameter(valid_600482, JString, required = true,
                                 default = nil)
  if valid_600482 != nil:
    section.add "PlatformApplicationArn", valid_600482
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600483 = header.getOrDefault("X-Amz-Date")
  valid_600483 = validateParameter(valid_600483, JString, required = false,
                                 default = nil)
  if valid_600483 != nil:
    section.add "X-Amz-Date", valid_600483
  var valid_600484 = header.getOrDefault("X-Amz-Security-Token")
  valid_600484 = validateParameter(valid_600484, JString, required = false,
                                 default = nil)
  if valid_600484 != nil:
    section.add "X-Amz-Security-Token", valid_600484
  var valid_600485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600485 = validateParameter(valid_600485, JString, required = false,
                                 default = nil)
  if valid_600485 != nil:
    section.add "X-Amz-Content-Sha256", valid_600485
  var valid_600486 = header.getOrDefault("X-Amz-Algorithm")
  valid_600486 = validateParameter(valid_600486, JString, required = false,
                                 default = nil)
  if valid_600486 != nil:
    section.add "X-Amz-Algorithm", valid_600486
  var valid_600487 = header.getOrDefault("X-Amz-Signature")
  valid_600487 = validateParameter(valid_600487, JString, required = false,
                                 default = nil)
  if valid_600487 != nil:
    section.add "X-Amz-Signature", valid_600487
  var valid_600488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600488 = validateParameter(valid_600488, JString, required = false,
                                 default = nil)
  if valid_600488 != nil:
    section.add "X-Amz-SignedHeaders", valid_600488
  var valid_600489 = header.getOrDefault("X-Amz-Credential")
  valid_600489 = validateParameter(valid_600489, JString, required = false,
                                 default = nil)
  if valid_600489 != nil:
    section.add "X-Amz-Credential", valid_600489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600490: Call_GetListEndpointsByPlatformApplication_600476;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as FCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_600490.validator(path, query, header, formData, body)
  let scheme = call_600490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600490.url(scheme.get, call_600490.host, call_600490.base,
                         call_600490.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600490, url, valid)

proc call*(call_600491: Call_GetListEndpointsByPlatformApplication_600476;
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
  var query_600492 = newJObject()
  add(query_600492, "NextToken", newJString(NextToken))
  add(query_600492, "Action", newJString(Action))
  add(query_600492, "Version", newJString(Version))
  add(query_600492, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_600491.call(nil, query_600492, nil, nil, nil)

var getListEndpointsByPlatformApplication* = Call_GetListEndpointsByPlatformApplication_600476(
    name: "getListEndpointsByPlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com",
    route: "/#Action=ListEndpointsByPlatformApplication",
    validator: validate_GetListEndpointsByPlatformApplication_600477, base: "/",
    url: url_GetListEndpointsByPlatformApplication_600478,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPhoneNumbersOptedOut_600527 = ref object of OpenApiRestCall_599368
proc url_PostListPhoneNumbersOptedOut_600529(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListPhoneNumbersOptedOut_600528(path: JsonNode; query: JsonNode;
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
  var valid_600530 = query.getOrDefault("Action")
  valid_600530 = validateParameter(valid_600530, JString, required = true, default = newJString(
      "ListPhoneNumbersOptedOut"))
  if valid_600530 != nil:
    section.add "Action", valid_600530
  var valid_600531 = query.getOrDefault("Version")
  valid_600531 = validateParameter(valid_600531, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600531 != nil:
    section.add "Version", valid_600531
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600532 = header.getOrDefault("X-Amz-Date")
  valid_600532 = validateParameter(valid_600532, JString, required = false,
                                 default = nil)
  if valid_600532 != nil:
    section.add "X-Amz-Date", valid_600532
  var valid_600533 = header.getOrDefault("X-Amz-Security-Token")
  valid_600533 = validateParameter(valid_600533, JString, required = false,
                                 default = nil)
  if valid_600533 != nil:
    section.add "X-Amz-Security-Token", valid_600533
  var valid_600534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600534 = validateParameter(valid_600534, JString, required = false,
                                 default = nil)
  if valid_600534 != nil:
    section.add "X-Amz-Content-Sha256", valid_600534
  var valid_600535 = header.getOrDefault("X-Amz-Algorithm")
  valid_600535 = validateParameter(valid_600535, JString, required = false,
                                 default = nil)
  if valid_600535 != nil:
    section.add "X-Amz-Algorithm", valid_600535
  var valid_600536 = header.getOrDefault("X-Amz-Signature")
  valid_600536 = validateParameter(valid_600536, JString, required = false,
                                 default = nil)
  if valid_600536 != nil:
    section.add "X-Amz-Signature", valid_600536
  var valid_600537 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600537 = validateParameter(valid_600537, JString, required = false,
                                 default = nil)
  if valid_600537 != nil:
    section.add "X-Amz-SignedHeaders", valid_600537
  var valid_600538 = header.getOrDefault("X-Amz-Credential")
  valid_600538 = validateParameter(valid_600538, JString, required = false,
                                 default = nil)
  if valid_600538 != nil:
    section.add "X-Amz-Credential", valid_600538
  result.add "header", section
  ## parameters in `formData` object:
  ##   nextToken: JString
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  section = newJObject()
  var valid_600539 = formData.getOrDefault("nextToken")
  valid_600539 = validateParameter(valid_600539, JString, required = false,
                                 default = nil)
  if valid_600539 != nil:
    section.add "nextToken", valid_600539
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600540: Call_PostListPhoneNumbersOptedOut_600527; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ## 
  let valid = call_600540.validator(path, query, header, formData, body)
  let scheme = call_600540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600540.url(scheme.get, call_600540.host, call_600540.base,
                         call_600540.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600540, url, valid)

proc call*(call_600541: Call_PostListPhoneNumbersOptedOut_600527;
          Action: string = "ListPhoneNumbersOptedOut"; nextToken: string = "";
          Version: string = "2010-03-31"): Recallable =
  ## postListPhoneNumbersOptedOut
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ##   Action: string (required)
  ##   nextToken: string
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  ##   Version: string (required)
  var query_600542 = newJObject()
  var formData_600543 = newJObject()
  add(query_600542, "Action", newJString(Action))
  add(formData_600543, "nextToken", newJString(nextToken))
  add(query_600542, "Version", newJString(Version))
  result = call_600541.call(nil, query_600542, nil, formData_600543, nil)

var postListPhoneNumbersOptedOut* = Call_PostListPhoneNumbersOptedOut_600527(
    name: "postListPhoneNumbersOptedOut", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListPhoneNumbersOptedOut",
    validator: validate_PostListPhoneNumbersOptedOut_600528, base: "/",
    url: url_PostListPhoneNumbersOptedOut_600529,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPhoneNumbersOptedOut_600511 = ref object of OpenApiRestCall_599368
proc url_GetListPhoneNumbersOptedOut_600513(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListPhoneNumbersOptedOut_600512(path: JsonNode; query: JsonNode;
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
  var valid_600514 = query.getOrDefault("nextToken")
  valid_600514 = validateParameter(valid_600514, JString, required = false,
                                 default = nil)
  if valid_600514 != nil:
    section.add "nextToken", valid_600514
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600515 = query.getOrDefault("Action")
  valid_600515 = validateParameter(valid_600515, JString, required = true, default = newJString(
      "ListPhoneNumbersOptedOut"))
  if valid_600515 != nil:
    section.add "Action", valid_600515
  var valid_600516 = query.getOrDefault("Version")
  valid_600516 = validateParameter(valid_600516, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600516 != nil:
    section.add "Version", valid_600516
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600517 = header.getOrDefault("X-Amz-Date")
  valid_600517 = validateParameter(valid_600517, JString, required = false,
                                 default = nil)
  if valid_600517 != nil:
    section.add "X-Amz-Date", valid_600517
  var valid_600518 = header.getOrDefault("X-Amz-Security-Token")
  valid_600518 = validateParameter(valid_600518, JString, required = false,
                                 default = nil)
  if valid_600518 != nil:
    section.add "X-Amz-Security-Token", valid_600518
  var valid_600519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600519 = validateParameter(valid_600519, JString, required = false,
                                 default = nil)
  if valid_600519 != nil:
    section.add "X-Amz-Content-Sha256", valid_600519
  var valid_600520 = header.getOrDefault("X-Amz-Algorithm")
  valid_600520 = validateParameter(valid_600520, JString, required = false,
                                 default = nil)
  if valid_600520 != nil:
    section.add "X-Amz-Algorithm", valid_600520
  var valid_600521 = header.getOrDefault("X-Amz-Signature")
  valid_600521 = validateParameter(valid_600521, JString, required = false,
                                 default = nil)
  if valid_600521 != nil:
    section.add "X-Amz-Signature", valid_600521
  var valid_600522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600522 = validateParameter(valid_600522, JString, required = false,
                                 default = nil)
  if valid_600522 != nil:
    section.add "X-Amz-SignedHeaders", valid_600522
  var valid_600523 = header.getOrDefault("X-Amz-Credential")
  valid_600523 = validateParameter(valid_600523, JString, required = false,
                                 default = nil)
  if valid_600523 != nil:
    section.add "X-Amz-Credential", valid_600523
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600524: Call_GetListPhoneNumbersOptedOut_600511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ## 
  let valid = call_600524.validator(path, query, header, formData, body)
  let scheme = call_600524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600524.url(scheme.get, call_600524.host, call_600524.base,
                         call_600524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600524, url, valid)

proc call*(call_600525: Call_GetListPhoneNumbersOptedOut_600511;
          nextToken: string = ""; Action: string = "ListPhoneNumbersOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## getListPhoneNumbersOptedOut
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ##   nextToken: string
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600526 = newJObject()
  add(query_600526, "nextToken", newJString(nextToken))
  add(query_600526, "Action", newJString(Action))
  add(query_600526, "Version", newJString(Version))
  result = call_600525.call(nil, query_600526, nil, nil, nil)

var getListPhoneNumbersOptedOut* = Call_GetListPhoneNumbersOptedOut_600511(
    name: "getListPhoneNumbersOptedOut", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListPhoneNumbersOptedOut",
    validator: validate_GetListPhoneNumbersOptedOut_600512, base: "/",
    url: url_GetListPhoneNumbersOptedOut_600513,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPlatformApplications_600560 = ref object of OpenApiRestCall_599368
proc url_PostListPlatformApplications_600562(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListPlatformApplications_600561(path: JsonNode; query: JsonNode;
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
  var valid_600563 = query.getOrDefault("Action")
  valid_600563 = validateParameter(valid_600563, JString, required = true, default = newJString(
      "ListPlatformApplications"))
  if valid_600563 != nil:
    section.add "Action", valid_600563
  var valid_600564 = query.getOrDefault("Version")
  valid_600564 = validateParameter(valid_600564, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600564 != nil:
    section.add "Version", valid_600564
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600565 = header.getOrDefault("X-Amz-Date")
  valid_600565 = validateParameter(valid_600565, JString, required = false,
                                 default = nil)
  if valid_600565 != nil:
    section.add "X-Amz-Date", valid_600565
  var valid_600566 = header.getOrDefault("X-Amz-Security-Token")
  valid_600566 = validateParameter(valid_600566, JString, required = false,
                                 default = nil)
  if valid_600566 != nil:
    section.add "X-Amz-Security-Token", valid_600566
  var valid_600567 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600567 = validateParameter(valid_600567, JString, required = false,
                                 default = nil)
  if valid_600567 != nil:
    section.add "X-Amz-Content-Sha256", valid_600567
  var valid_600568 = header.getOrDefault("X-Amz-Algorithm")
  valid_600568 = validateParameter(valid_600568, JString, required = false,
                                 default = nil)
  if valid_600568 != nil:
    section.add "X-Amz-Algorithm", valid_600568
  var valid_600569 = header.getOrDefault("X-Amz-Signature")
  valid_600569 = validateParameter(valid_600569, JString, required = false,
                                 default = nil)
  if valid_600569 != nil:
    section.add "X-Amz-Signature", valid_600569
  var valid_600570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600570 = validateParameter(valid_600570, JString, required = false,
                                 default = nil)
  if valid_600570 != nil:
    section.add "X-Amz-SignedHeaders", valid_600570
  var valid_600571 = header.getOrDefault("X-Amz-Credential")
  valid_600571 = validateParameter(valid_600571, JString, required = false,
                                 default = nil)
  if valid_600571 != nil:
    section.add "X-Amz-Credential", valid_600571
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  section = newJObject()
  var valid_600572 = formData.getOrDefault("NextToken")
  valid_600572 = validateParameter(valid_600572, JString, required = false,
                                 default = nil)
  if valid_600572 != nil:
    section.add "NextToken", valid_600572
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600573: Call_PostListPlatformApplications_600560; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and FCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  let valid = call_600573.validator(path, query, header, formData, body)
  let scheme = call_600573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600573.url(scheme.get, call_600573.host, call_600573.base,
                         call_600573.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600573, url, valid)

proc call*(call_600574: Call_PostListPlatformApplications_600560;
          NextToken: string = ""; Action: string = "ListPlatformApplications";
          Version: string = "2010-03-31"): Recallable =
  ## postListPlatformApplications
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and FCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600575 = newJObject()
  var formData_600576 = newJObject()
  add(formData_600576, "NextToken", newJString(NextToken))
  add(query_600575, "Action", newJString(Action))
  add(query_600575, "Version", newJString(Version))
  result = call_600574.call(nil, query_600575, nil, formData_600576, nil)

var postListPlatformApplications* = Call_PostListPlatformApplications_600560(
    name: "postListPlatformApplications", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListPlatformApplications",
    validator: validate_PostListPlatformApplications_600561, base: "/",
    url: url_PostListPlatformApplications_600562,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPlatformApplications_600544 = ref object of OpenApiRestCall_599368
proc url_GetListPlatformApplications_600546(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListPlatformApplications_600545(path: JsonNode; query: JsonNode;
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
  var valid_600547 = query.getOrDefault("NextToken")
  valid_600547 = validateParameter(valid_600547, JString, required = false,
                                 default = nil)
  if valid_600547 != nil:
    section.add "NextToken", valid_600547
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600548 = query.getOrDefault("Action")
  valid_600548 = validateParameter(valid_600548, JString, required = true, default = newJString(
      "ListPlatformApplications"))
  if valid_600548 != nil:
    section.add "Action", valid_600548
  var valid_600549 = query.getOrDefault("Version")
  valid_600549 = validateParameter(valid_600549, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600549 != nil:
    section.add "Version", valid_600549
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600550 = header.getOrDefault("X-Amz-Date")
  valid_600550 = validateParameter(valid_600550, JString, required = false,
                                 default = nil)
  if valid_600550 != nil:
    section.add "X-Amz-Date", valid_600550
  var valid_600551 = header.getOrDefault("X-Amz-Security-Token")
  valid_600551 = validateParameter(valid_600551, JString, required = false,
                                 default = nil)
  if valid_600551 != nil:
    section.add "X-Amz-Security-Token", valid_600551
  var valid_600552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600552 = validateParameter(valid_600552, JString, required = false,
                                 default = nil)
  if valid_600552 != nil:
    section.add "X-Amz-Content-Sha256", valid_600552
  var valid_600553 = header.getOrDefault("X-Amz-Algorithm")
  valid_600553 = validateParameter(valid_600553, JString, required = false,
                                 default = nil)
  if valid_600553 != nil:
    section.add "X-Amz-Algorithm", valid_600553
  var valid_600554 = header.getOrDefault("X-Amz-Signature")
  valid_600554 = validateParameter(valid_600554, JString, required = false,
                                 default = nil)
  if valid_600554 != nil:
    section.add "X-Amz-Signature", valid_600554
  var valid_600555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600555 = validateParameter(valid_600555, JString, required = false,
                                 default = nil)
  if valid_600555 != nil:
    section.add "X-Amz-SignedHeaders", valid_600555
  var valid_600556 = header.getOrDefault("X-Amz-Credential")
  valid_600556 = validateParameter(valid_600556, JString, required = false,
                                 default = nil)
  if valid_600556 != nil:
    section.add "X-Amz-Credential", valid_600556
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600557: Call_GetListPlatformApplications_600544; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and FCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  let valid = call_600557.validator(path, query, header, formData, body)
  let scheme = call_600557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600557.url(scheme.get, call_600557.host, call_600557.base,
                         call_600557.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600557, url, valid)

proc call*(call_600558: Call_GetListPlatformApplications_600544;
          NextToken: string = ""; Action: string = "ListPlatformApplications";
          Version: string = "2010-03-31"): Recallable =
  ## getListPlatformApplications
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and FCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600559 = newJObject()
  add(query_600559, "NextToken", newJString(NextToken))
  add(query_600559, "Action", newJString(Action))
  add(query_600559, "Version", newJString(Version))
  result = call_600558.call(nil, query_600559, nil, nil, nil)

var getListPlatformApplications* = Call_GetListPlatformApplications_600544(
    name: "getListPlatformApplications", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListPlatformApplications",
    validator: validate_GetListPlatformApplications_600545, base: "/",
    url: url_GetListPlatformApplications_600546,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListSubscriptions_600593 = ref object of OpenApiRestCall_599368
proc url_PostListSubscriptions_600595(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListSubscriptions_600594(path: JsonNode; query: JsonNode;
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
  var valid_600596 = query.getOrDefault("Action")
  valid_600596 = validateParameter(valid_600596, JString, required = true,
                                 default = newJString("ListSubscriptions"))
  if valid_600596 != nil:
    section.add "Action", valid_600596
  var valid_600597 = query.getOrDefault("Version")
  valid_600597 = validateParameter(valid_600597, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600597 != nil:
    section.add "Version", valid_600597
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600598 = header.getOrDefault("X-Amz-Date")
  valid_600598 = validateParameter(valid_600598, JString, required = false,
                                 default = nil)
  if valid_600598 != nil:
    section.add "X-Amz-Date", valid_600598
  var valid_600599 = header.getOrDefault("X-Amz-Security-Token")
  valid_600599 = validateParameter(valid_600599, JString, required = false,
                                 default = nil)
  if valid_600599 != nil:
    section.add "X-Amz-Security-Token", valid_600599
  var valid_600600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600600 = validateParameter(valid_600600, JString, required = false,
                                 default = nil)
  if valid_600600 != nil:
    section.add "X-Amz-Content-Sha256", valid_600600
  var valid_600601 = header.getOrDefault("X-Amz-Algorithm")
  valid_600601 = validateParameter(valid_600601, JString, required = false,
                                 default = nil)
  if valid_600601 != nil:
    section.add "X-Amz-Algorithm", valid_600601
  var valid_600602 = header.getOrDefault("X-Amz-Signature")
  valid_600602 = validateParameter(valid_600602, JString, required = false,
                                 default = nil)
  if valid_600602 != nil:
    section.add "X-Amz-Signature", valid_600602
  var valid_600603 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600603 = validateParameter(valid_600603, JString, required = false,
                                 default = nil)
  if valid_600603 != nil:
    section.add "X-Amz-SignedHeaders", valid_600603
  var valid_600604 = header.getOrDefault("X-Amz-Credential")
  valid_600604 = validateParameter(valid_600604, JString, required = false,
                                 default = nil)
  if valid_600604 != nil:
    section.add "X-Amz-Credential", valid_600604
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  section = newJObject()
  var valid_600605 = formData.getOrDefault("NextToken")
  valid_600605 = validateParameter(valid_600605, JString, required = false,
                                 default = nil)
  if valid_600605 != nil:
    section.add "NextToken", valid_600605
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600606: Call_PostListSubscriptions_600593; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_600606.validator(path, query, header, formData, body)
  let scheme = call_600606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600606.url(scheme.get, call_600606.host, call_600606.base,
                         call_600606.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600606, url, valid)

proc call*(call_600607: Call_PostListSubscriptions_600593; NextToken: string = "";
          Action: string = "ListSubscriptions"; Version: string = "2010-03-31"): Recallable =
  ## postListSubscriptions
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600608 = newJObject()
  var formData_600609 = newJObject()
  add(formData_600609, "NextToken", newJString(NextToken))
  add(query_600608, "Action", newJString(Action))
  add(query_600608, "Version", newJString(Version))
  result = call_600607.call(nil, query_600608, nil, formData_600609, nil)

var postListSubscriptions* = Call_PostListSubscriptions_600593(
    name: "postListSubscriptions", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptions",
    validator: validate_PostListSubscriptions_600594, base: "/",
    url: url_PostListSubscriptions_600595, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListSubscriptions_600577 = ref object of OpenApiRestCall_599368
proc url_GetListSubscriptions_600579(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListSubscriptions_600578(path: JsonNode; query: JsonNode;
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
  var valid_600580 = query.getOrDefault("NextToken")
  valid_600580 = validateParameter(valid_600580, JString, required = false,
                                 default = nil)
  if valid_600580 != nil:
    section.add "NextToken", valid_600580
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600581 = query.getOrDefault("Action")
  valid_600581 = validateParameter(valid_600581, JString, required = true,
                                 default = newJString("ListSubscriptions"))
  if valid_600581 != nil:
    section.add "Action", valid_600581
  var valid_600582 = query.getOrDefault("Version")
  valid_600582 = validateParameter(valid_600582, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600582 != nil:
    section.add "Version", valid_600582
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600583 = header.getOrDefault("X-Amz-Date")
  valid_600583 = validateParameter(valid_600583, JString, required = false,
                                 default = nil)
  if valid_600583 != nil:
    section.add "X-Amz-Date", valid_600583
  var valid_600584 = header.getOrDefault("X-Amz-Security-Token")
  valid_600584 = validateParameter(valid_600584, JString, required = false,
                                 default = nil)
  if valid_600584 != nil:
    section.add "X-Amz-Security-Token", valid_600584
  var valid_600585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600585 = validateParameter(valid_600585, JString, required = false,
                                 default = nil)
  if valid_600585 != nil:
    section.add "X-Amz-Content-Sha256", valid_600585
  var valid_600586 = header.getOrDefault("X-Amz-Algorithm")
  valid_600586 = validateParameter(valid_600586, JString, required = false,
                                 default = nil)
  if valid_600586 != nil:
    section.add "X-Amz-Algorithm", valid_600586
  var valid_600587 = header.getOrDefault("X-Amz-Signature")
  valid_600587 = validateParameter(valid_600587, JString, required = false,
                                 default = nil)
  if valid_600587 != nil:
    section.add "X-Amz-Signature", valid_600587
  var valid_600588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600588 = validateParameter(valid_600588, JString, required = false,
                                 default = nil)
  if valid_600588 != nil:
    section.add "X-Amz-SignedHeaders", valid_600588
  var valid_600589 = header.getOrDefault("X-Amz-Credential")
  valid_600589 = validateParameter(valid_600589, JString, required = false,
                                 default = nil)
  if valid_600589 != nil:
    section.add "X-Amz-Credential", valid_600589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600590: Call_GetListSubscriptions_600577; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_600590.validator(path, query, header, formData, body)
  let scheme = call_600590.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600590.url(scheme.get, call_600590.host, call_600590.base,
                         call_600590.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600590, url, valid)

proc call*(call_600591: Call_GetListSubscriptions_600577; NextToken: string = "";
          Action: string = "ListSubscriptions"; Version: string = "2010-03-31"): Recallable =
  ## getListSubscriptions
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600592 = newJObject()
  add(query_600592, "NextToken", newJString(NextToken))
  add(query_600592, "Action", newJString(Action))
  add(query_600592, "Version", newJString(Version))
  result = call_600591.call(nil, query_600592, nil, nil, nil)

var getListSubscriptions* = Call_GetListSubscriptions_600577(
    name: "getListSubscriptions", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptions",
    validator: validate_GetListSubscriptions_600578, base: "/",
    url: url_GetListSubscriptions_600579, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListSubscriptionsByTopic_600627 = ref object of OpenApiRestCall_599368
proc url_PostListSubscriptionsByTopic_600629(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListSubscriptionsByTopic_600628(path: JsonNode; query: JsonNode;
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
  var valid_600630 = query.getOrDefault("Action")
  valid_600630 = validateParameter(valid_600630, JString, required = true, default = newJString(
      "ListSubscriptionsByTopic"))
  if valid_600630 != nil:
    section.add "Action", valid_600630
  var valid_600631 = query.getOrDefault("Version")
  valid_600631 = validateParameter(valid_600631, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600631 != nil:
    section.add "Version", valid_600631
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600632 = header.getOrDefault("X-Amz-Date")
  valid_600632 = validateParameter(valid_600632, JString, required = false,
                                 default = nil)
  if valid_600632 != nil:
    section.add "X-Amz-Date", valid_600632
  var valid_600633 = header.getOrDefault("X-Amz-Security-Token")
  valid_600633 = validateParameter(valid_600633, JString, required = false,
                                 default = nil)
  if valid_600633 != nil:
    section.add "X-Amz-Security-Token", valid_600633
  var valid_600634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600634 = validateParameter(valid_600634, JString, required = false,
                                 default = nil)
  if valid_600634 != nil:
    section.add "X-Amz-Content-Sha256", valid_600634
  var valid_600635 = header.getOrDefault("X-Amz-Algorithm")
  valid_600635 = validateParameter(valid_600635, JString, required = false,
                                 default = nil)
  if valid_600635 != nil:
    section.add "X-Amz-Algorithm", valid_600635
  var valid_600636 = header.getOrDefault("X-Amz-Signature")
  valid_600636 = validateParameter(valid_600636, JString, required = false,
                                 default = nil)
  if valid_600636 != nil:
    section.add "X-Amz-Signature", valid_600636
  var valid_600637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600637 = validateParameter(valid_600637, JString, required = false,
                                 default = nil)
  if valid_600637 != nil:
    section.add "X-Amz-SignedHeaders", valid_600637
  var valid_600638 = header.getOrDefault("X-Amz-Credential")
  valid_600638 = validateParameter(valid_600638, JString, required = false,
                                 default = nil)
  if valid_600638 != nil:
    section.add "X-Amz-Credential", valid_600638
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListSubscriptionsByTopic</code> request.
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic for which you wish to find subscriptions.
  section = newJObject()
  var valid_600639 = formData.getOrDefault("NextToken")
  valid_600639 = validateParameter(valid_600639, JString, required = false,
                                 default = nil)
  if valid_600639 != nil:
    section.add "NextToken", valid_600639
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_600640 = formData.getOrDefault("TopicArn")
  valid_600640 = validateParameter(valid_600640, JString, required = true,
                                 default = nil)
  if valid_600640 != nil:
    section.add "TopicArn", valid_600640
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600641: Call_PostListSubscriptionsByTopic_600627; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_600641.validator(path, query, header, formData, body)
  let scheme = call_600641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600641.url(scheme.get, call_600641.host, call_600641.base,
                         call_600641.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600641, url, valid)

proc call*(call_600642: Call_PostListSubscriptionsByTopic_600627; TopicArn: string;
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
  var query_600643 = newJObject()
  var formData_600644 = newJObject()
  add(formData_600644, "NextToken", newJString(NextToken))
  add(formData_600644, "TopicArn", newJString(TopicArn))
  add(query_600643, "Action", newJString(Action))
  add(query_600643, "Version", newJString(Version))
  result = call_600642.call(nil, query_600643, nil, formData_600644, nil)

var postListSubscriptionsByTopic* = Call_PostListSubscriptionsByTopic_600627(
    name: "postListSubscriptionsByTopic", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptionsByTopic",
    validator: validate_PostListSubscriptionsByTopic_600628, base: "/",
    url: url_PostListSubscriptionsByTopic_600629,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListSubscriptionsByTopic_600610 = ref object of OpenApiRestCall_599368
proc url_GetListSubscriptionsByTopic_600612(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListSubscriptionsByTopic_600611(path: JsonNode; query: JsonNode;
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
  var valid_600613 = query.getOrDefault("NextToken")
  valid_600613 = validateParameter(valid_600613, JString, required = false,
                                 default = nil)
  if valid_600613 != nil:
    section.add "NextToken", valid_600613
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600614 = query.getOrDefault("Action")
  valid_600614 = validateParameter(valid_600614, JString, required = true, default = newJString(
      "ListSubscriptionsByTopic"))
  if valid_600614 != nil:
    section.add "Action", valid_600614
  var valid_600615 = query.getOrDefault("TopicArn")
  valid_600615 = validateParameter(valid_600615, JString, required = true,
                                 default = nil)
  if valid_600615 != nil:
    section.add "TopicArn", valid_600615
  var valid_600616 = query.getOrDefault("Version")
  valid_600616 = validateParameter(valid_600616, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600616 != nil:
    section.add "Version", valid_600616
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600617 = header.getOrDefault("X-Amz-Date")
  valid_600617 = validateParameter(valid_600617, JString, required = false,
                                 default = nil)
  if valid_600617 != nil:
    section.add "X-Amz-Date", valid_600617
  var valid_600618 = header.getOrDefault("X-Amz-Security-Token")
  valid_600618 = validateParameter(valid_600618, JString, required = false,
                                 default = nil)
  if valid_600618 != nil:
    section.add "X-Amz-Security-Token", valid_600618
  var valid_600619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600619 = validateParameter(valid_600619, JString, required = false,
                                 default = nil)
  if valid_600619 != nil:
    section.add "X-Amz-Content-Sha256", valid_600619
  var valid_600620 = header.getOrDefault("X-Amz-Algorithm")
  valid_600620 = validateParameter(valid_600620, JString, required = false,
                                 default = nil)
  if valid_600620 != nil:
    section.add "X-Amz-Algorithm", valid_600620
  var valid_600621 = header.getOrDefault("X-Amz-Signature")
  valid_600621 = validateParameter(valid_600621, JString, required = false,
                                 default = nil)
  if valid_600621 != nil:
    section.add "X-Amz-Signature", valid_600621
  var valid_600622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600622 = validateParameter(valid_600622, JString, required = false,
                                 default = nil)
  if valid_600622 != nil:
    section.add "X-Amz-SignedHeaders", valid_600622
  var valid_600623 = header.getOrDefault("X-Amz-Credential")
  valid_600623 = validateParameter(valid_600623, JString, required = false,
                                 default = nil)
  if valid_600623 != nil:
    section.add "X-Amz-Credential", valid_600623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600624: Call_GetListSubscriptionsByTopic_600610; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_600624.validator(path, query, header, formData, body)
  let scheme = call_600624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600624.url(scheme.get, call_600624.host, call_600624.base,
                         call_600624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600624, url, valid)

proc call*(call_600625: Call_GetListSubscriptionsByTopic_600610; TopicArn: string;
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
  var query_600626 = newJObject()
  add(query_600626, "NextToken", newJString(NextToken))
  add(query_600626, "Action", newJString(Action))
  add(query_600626, "TopicArn", newJString(TopicArn))
  add(query_600626, "Version", newJString(Version))
  result = call_600625.call(nil, query_600626, nil, nil, nil)

var getListSubscriptionsByTopic* = Call_GetListSubscriptionsByTopic_600610(
    name: "getListSubscriptionsByTopic", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptionsByTopic",
    validator: validate_GetListSubscriptionsByTopic_600611, base: "/",
    url: url_GetListSubscriptionsByTopic_600612,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_600661 = ref object of OpenApiRestCall_599368
proc url_PostListTagsForResource_600663(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListTagsForResource_600662(path: JsonNode; query: JsonNode;
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
  var valid_600664 = query.getOrDefault("Action")
  valid_600664 = validateParameter(valid_600664, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_600664 != nil:
    section.add "Action", valid_600664
  var valid_600665 = query.getOrDefault("Version")
  valid_600665 = validateParameter(valid_600665, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600665 != nil:
    section.add "Version", valid_600665
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600666 = header.getOrDefault("X-Amz-Date")
  valid_600666 = validateParameter(valid_600666, JString, required = false,
                                 default = nil)
  if valid_600666 != nil:
    section.add "X-Amz-Date", valid_600666
  var valid_600667 = header.getOrDefault("X-Amz-Security-Token")
  valid_600667 = validateParameter(valid_600667, JString, required = false,
                                 default = nil)
  if valid_600667 != nil:
    section.add "X-Amz-Security-Token", valid_600667
  var valid_600668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600668 = validateParameter(valid_600668, JString, required = false,
                                 default = nil)
  if valid_600668 != nil:
    section.add "X-Amz-Content-Sha256", valid_600668
  var valid_600669 = header.getOrDefault("X-Amz-Algorithm")
  valid_600669 = validateParameter(valid_600669, JString, required = false,
                                 default = nil)
  if valid_600669 != nil:
    section.add "X-Amz-Algorithm", valid_600669
  var valid_600670 = header.getOrDefault("X-Amz-Signature")
  valid_600670 = validateParameter(valid_600670, JString, required = false,
                                 default = nil)
  if valid_600670 != nil:
    section.add "X-Amz-Signature", valid_600670
  var valid_600671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600671 = validateParameter(valid_600671, JString, required = false,
                                 default = nil)
  if valid_600671 != nil:
    section.add "X-Amz-SignedHeaders", valid_600671
  var valid_600672 = header.getOrDefault("X-Amz-Credential")
  valid_600672 = validateParameter(valid_600672, JString, required = false,
                                 default = nil)
  if valid_600672 != nil:
    section.add "X-Amz-Credential", valid_600672
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic for which to list tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_600673 = formData.getOrDefault("ResourceArn")
  valid_600673 = validateParameter(valid_600673, JString, required = true,
                                 default = nil)
  if valid_600673 != nil:
    section.add "ResourceArn", valid_600673
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600674: Call_PostListTagsForResource_600661; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ## 
  let valid = call_600674.validator(path, query, header, formData, body)
  let scheme = call_600674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600674.url(scheme.get, call_600674.host, call_600674.base,
                         call_600674.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600674, url, valid)

proc call*(call_600675: Call_PostListTagsForResource_600661; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-03-31"): Recallable =
  ## postListTagsForResource
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ##   Action: string (required)
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic for which to list tags.
  ##   Version: string (required)
  var query_600676 = newJObject()
  var formData_600677 = newJObject()
  add(query_600676, "Action", newJString(Action))
  add(formData_600677, "ResourceArn", newJString(ResourceArn))
  add(query_600676, "Version", newJString(Version))
  result = call_600675.call(nil, query_600676, nil, formData_600677, nil)

var postListTagsForResource* = Call_PostListTagsForResource_600661(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_600662, base: "/",
    url: url_PostListTagsForResource_600663, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_600645 = ref object of OpenApiRestCall_599368
proc url_GetListTagsForResource_600647(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListTagsForResource_600646(path: JsonNode; query: JsonNode;
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
  var valid_600648 = query.getOrDefault("ResourceArn")
  valid_600648 = validateParameter(valid_600648, JString, required = true,
                                 default = nil)
  if valid_600648 != nil:
    section.add "ResourceArn", valid_600648
  var valid_600649 = query.getOrDefault("Action")
  valid_600649 = validateParameter(valid_600649, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_600649 != nil:
    section.add "Action", valid_600649
  var valid_600650 = query.getOrDefault("Version")
  valid_600650 = validateParameter(valid_600650, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600650 != nil:
    section.add "Version", valid_600650
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600651 = header.getOrDefault("X-Amz-Date")
  valid_600651 = validateParameter(valid_600651, JString, required = false,
                                 default = nil)
  if valid_600651 != nil:
    section.add "X-Amz-Date", valid_600651
  var valid_600652 = header.getOrDefault("X-Amz-Security-Token")
  valid_600652 = validateParameter(valid_600652, JString, required = false,
                                 default = nil)
  if valid_600652 != nil:
    section.add "X-Amz-Security-Token", valid_600652
  var valid_600653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600653 = validateParameter(valid_600653, JString, required = false,
                                 default = nil)
  if valid_600653 != nil:
    section.add "X-Amz-Content-Sha256", valid_600653
  var valid_600654 = header.getOrDefault("X-Amz-Algorithm")
  valid_600654 = validateParameter(valid_600654, JString, required = false,
                                 default = nil)
  if valid_600654 != nil:
    section.add "X-Amz-Algorithm", valid_600654
  var valid_600655 = header.getOrDefault("X-Amz-Signature")
  valid_600655 = validateParameter(valid_600655, JString, required = false,
                                 default = nil)
  if valid_600655 != nil:
    section.add "X-Amz-Signature", valid_600655
  var valid_600656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600656 = validateParameter(valid_600656, JString, required = false,
                                 default = nil)
  if valid_600656 != nil:
    section.add "X-Amz-SignedHeaders", valid_600656
  var valid_600657 = header.getOrDefault("X-Amz-Credential")
  valid_600657 = validateParameter(valid_600657, JString, required = false,
                                 default = nil)
  if valid_600657 != nil:
    section.add "X-Amz-Credential", valid_600657
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600658: Call_GetListTagsForResource_600645; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ## 
  let valid = call_600658.validator(path, query, header, formData, body)
  let scheme = call_600658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600658.url(scheme.get, call_600658.host, call_600658.base,
                         call_600658.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600658, url, valid)

proc call*(call_600659: Call_GetListTagsForResource_600645; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-03-31"): Recallable =
  ## getListTagsForResource
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic for which to list tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600660 = newJObject()
  add(query_600660, "ResourceArn", newJString(ResourceArn))
  add(query_600660, "Action", newJString(Action))
  add(query_600660, "Version", newJString(Version))
  result = call_600659.call(nil, query_600660, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_600645(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_600646, base: "/",
    url: url_GetListTagsForResource_600647, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTopics_600694 = ref object of OpenApiRestCall_599368
proc url_PostListTopics_600696(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListTopics_600695(path: JsonNode; query: JsonNode;
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
  var valid_600697 = query.getOrDefault("Action")
  valid_600697 = validateParameter(valid_600697, JString, required = true,
                                 default = newJString("ListTopics"))
  if valid_600697 != nil:
    section.add "Action", valid_600697
  var valid_600698 = query.getOrDefault("Version")
  valid_600698 = validateParameter(valid_600698, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600698 != nil:
    section.add "Version", valid_600698
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600699 = header.getOrDefault("X-Amz-Date")
  valid_600699 = validateParameter(valid_600699, JString, required = false,
                                 default = nil)
  if valid_600699 != nil:
    section.add "X-Amz-Date", valid_600699
  var valid_600700 = header.getOrDefault("X-Amz-Security-Token")
  valid_600700 = validateParameter(valid_600700, JString, required = false,
                                 default = nil)
  if valid_600700 != nil:
    section.add "X-Amz-Security-Token", valid_600700
  var valid_600701 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600701 = validateParameter(valid_600701, JString, required = false,
                                 default = nil)
  if valid_600701 != nil:
    section.add "X-Amz-Content-Sha256", valid_600701
  var valid_600702 = header.getOrDefault("X-Amz-Algorithm")
  valid_600702 = validateParameter(valid_600702, JString, required = false,
                                 default = nil)
  if valid_600702 != nil:
    section.add "X-Amz-Algorithm", valid_600702
  var valid_600703 = header.getOrDefault("X-Amz-Signature")
  valid_600703 = validateParameter(valid_600703, JString, required = false,
                                 default = nil)
  if valid_600703 != nil:
    section.add "X-Amz-Signature", valid_600703
  var valid_600704 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600704 = validateParameter(valid_600704, JString, required = false,
                                 default = nil)
  if valid_600704 != nil:
    section.add "X-Amz-SignedHeaders", valid_600704
  var valid_600705 = header.getOrDefault("X-Amz-Credential")
  valid_600705 = validateParameter(valid_600705, JString, required = false,
                                 default = nil)
  if valid_600705 != nil:
    section.add "X-Amz-Credential", valid_600705
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListTopics</code> request.
  section = newJObject()
  var valid_600706 = formData.getOrDefault("NextToken")
  valid_600706 = validateParameter(valid_600706, JString, required = false,
                                 default = nil)
  if valid_600706 != nil:
    section.add "NextToken", valid_600706
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600707: Call_PostListTopics_600694; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_600707.validator(path, query, header, formData, body)
  let scheme = call_600707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600707.url(scheme.get, call_600707.host, call_600707.base,
                         call_600707.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600707, url, valid)

proc call*(call_600708: Call_PostListTopics_600694; NextToken: string = "";
          Action: string = "ListTopics"; Version: string = "2010-03-31"): Recallable =
  ## postListTopics
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListTopics</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600709 = newJObject()
  var formData_600710 = newJObject()
  add(formData_600710, "NextToken", newJString(NextToken))
  add(query_600709, "Action", newJString(Action))
  add(query_600709, "Version", newJString(Version))
  result = call_600708.call(nil, query_600709, nil, formData_600710, nil)

var postListTopics* = Call_PostListTopics_600694(name: "postListTopics",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=ListTopics", validator: validate_PostListTopics_600695,
    base: "/", url: url_PostListTopics_600696, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTopics_600678 = ref object of OpenApiRestCall_599368
proc url_GetListTopics_600680(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListTopics_600679(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600681 = query.getOrDefault("NextToken")
  valid_600681 = validateParameter(valid_600681, JString, required = false,
                                 default = nil)
  if valid_600681 != nil:
    section.add "NextToken", valid_600681
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600682 = query.getOrDefault("Action")
  valid_600682 = validateParameter(valid_600682, JString, required = true,
                                 default = newJString("ListTopics"))
  if valid_600682 != nil:
    section.add "Action", valid_600682
  var valid_600683 = query.getOrDefault("Version")
  valid_600683 = validateParameter(valid_600683, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600683 != nil:
    section.add "Version", valid_600683
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600684 = header.getOrDefault("X-Amz-Date")
  valid_600684 = validateParameter(valid_600684, JString, required = false,
                                 default = nil)
  if valid_600684 != nil:
    section.add "X-Amz-Date", valid_600684
  var valid_600685 = header.getOrDefault("X-Amz-Security-Token")
  valid_600685 = validateParameter(valid_600685, JString, required = false,
                                 default = nil)
  if valid_600685 != nil:
    section.add "X-Amz-Security-Token", valid_600685
  var valid_600686 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600686 = validateParameter(valid_600686, JString, required = false,
                                 default = nil)
  if valid_600686 != nil:
    section.add "X-Amz-Content-Sha256", valid_600686
  var valid_600687 = header.getOrDefault("X-Amz-Algorithm")
  valid_600687 = validateParameter(valid_600687, JString, required = false,
                                 default = nil)
  if valid_600687 != nil:
    section.add "X-Amz-Algorithm", valid_600687
  var valid_600688 = header.getOrDefault("X-Amz-Signature")
  valid_600688 = validateParameter(valid_600688, JString, required = false,
                                 default = nil)
  if valid_600688 != nil:
    section.add "X-Amz-Signature", valid_600688
  var valid_600689 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600689 = validateParameter(valid_600689, JString, required = false,
                                 default = nil)
  if valid_600689 != nil:
    section.add "X-Amz-SignedHeaders", valid_600689
  var valid_600690 = header.getOrDefault("X-Amz-Credential")
  valid_600690 = validateParameter(valid_600690, JString, required = false,
                                 default = nil)
  if valid_600690 != nil:
    section.add "X-Amz-Credential", valid_600690
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600691: Call_GetListTopics_600678; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_600691.validator(path, query, header, formData, body)
  let scheme = call_600691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600691.url(scheme.get, call_600691.host, call_600691.base,
                         call_600691.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600691, url, valid)

proc call*(call_600692: Call_GetListTopics_600678; NextToken: string = "";
          Action: string = "ListTopics"; Version: string = "2010-03-31"): Recallable =
  ## getListTopics
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListTopics</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600693 = newJObject()
  add(query_600693, "NextToken", newJString(NextToken))
  add(query_600693, "Action", newJString(Action))
  add(query_600693, "Version", newJString(Version))
  result = call_600692.call(nil, query_600693, nil, nil, nil)

var getListTopics* = Call_GetListTopics_600678(name: "getListTopics",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=ListTopics", validator: validate_GetListTopics_600679,
    base: "/", url: url_GetListTopics_600680, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostOptInPhoneNumber_600727 = ref object of OpenApiRestCall_599368
proc url_PostOptInPhoneNumber_600729(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostOptInPhoneNumber_600728(path: JsonNode; query: JsonNode;
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
  var valid_600730 = query.getOrDefault("Action")
  valid_600730 = validateParameter(valid_600730, JString, required = true,
                                 default = newJString("OptInPhoneNumber"))
  if valid_600730 != nil:
    section.add "Action", valid_600730
  var valid_600731 = query.getOrDefault("Version")
  valid_600731 = validateParameter(valid_600731, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600731 != nil:
    section.add "Version", valid_600731
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600732 = header.getOrDefault("X-Amz-Date")
  valid_600732 = validateParameter(valid_600732, JString, required = false,
                                 default = nil)
  if valid_600732 != nil:
    section.add "X-Amz-Date", valid_600732
  var valid_600733 = header.getOrDefault("X-Amz-Security-Token")
  valid_600733 = validateParameter(valid_600733, JString, required = false,
                                 default = nil)
  if valid_600733 != nil:
    section.add "X-Amz-Security-Token", valid_600733
  var valid_600734 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600734 = validateParameter(valid_600734, JString, required = false,
                                 default = nil)
  if valid_600734 != nil:
    section.add "X-Amz-Content-Sha256", valid_600734
  var valid_600735 = header.getOrDefault("X-Amz-Algorithm")
  valid_600735 = validateParameter(valid_600735, JString, required = false,
                                 default = nil)
  if valid_600735 != nil:
    section.add "X-Amz-Algorithm", valid_600735
  var valid_600736 = header.getOrDefault("X-Amz-Signature")
  valid_600736 = validateParameter(valid_600736, JString, required = false,
                                 default = nil)
  if valid_600736 != nil:
    section.add "X-Amz-Signature", valid_600736
  var valid_600737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600737 = validateParameter(valid_600737, JString, required = false,
                                 default = nil)
  if valid_600737 != nil:
    section.add "X-Amz-SignedHeaders", valid_600737
  var valid_600738 = header.getOrDefault("X-Amz-Credential")
  valid_600738 = validateParameter(valid_600738, JString, required = false,
                                 default = nil)
  if valid_600738 != nil:
    section.add "X-Amz-Credential", valid_600738
  result.add "header", section
  ## parameters in `formData` object:
  ##   phoneNumber: JString (required)
  ##              : The phone number to opt in.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `phoneNumber` field"
  var valid_600739 = formData.getOrDefault("phoneNumber")
  valid_600739 = validateParameter(valid_600739, JString, required = true,
                                 default = nil)
  if valid_600739 != nil:
    section.add "phoneNumber", valid_600739
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600740: Call_PostOptInPhoneNumber_600727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ## 
  let valid = call_600740.validator(path, query, header, formData, body)
  let scheme = call_600740.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600740.url(scheme.get, call_600740.host, call_600740.base,
                         call_600740.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600740, url, valid)

proc call*(call_600741: Call_PostOptInPhoneNumber_600727; phoneNumber: string;
          Action: string = "OptInPhoneNumber"; Version: string = "2010-03-31"): Recallable =
  ## postOptInPhoneNumber
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ##   Action: string (required)
  ##   phoneNumber: string (required)
  ##              : The phone number to opt in.
  ##   Version: string (required)
  var query_600742 = newJObject()
  var formData_600743 = newJObject()
  add(query_600742, "Action", newJString(Action))
  add(formData_600743, "phoneNumber", newJString(phoneNumber))
  add(query_600742, "Version", newJString(Version))
  result = call_600741.call(nil, query_600742, nil, formData_600743, nil)

var postOptInPhoneNumber* = Call_PostOptInPhoneNumber_600727(
    name: "postOptInPhoneNumber", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=OptInPhoneNumber",
    validator: validate_PostOptInPhoneNumber_600728, base: "/",
    url: url_PostOptInPhoneNumber_600729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOptInPhoneNumber_600711 = ref object of OpenApiRestCall_599368
proc url_GetOptInPhoneNumber_600713(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetOptInPhoneNumber_600712(path: JsonNode; query: JsonNode;
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
  var valid_600714 = query.getOrDefault("phoneNumber")
  valid_600714 = validateParameter(valid_600714, JString, required = true,
                                 default = nil)
  if valid_600714 != nil:
    section.add "phoneNumber", valid_600714
  var valid_600715 = query.getOrDefault("Action")
  valid_600715 = validateParameter(valid_600715, JString, required = true,
                                 default = newJString("OptInPhoneNumber"))
  if valid_600715 != nil:
    section.add "Action", valid_600715
  var valid_600716 = query.getOrDefault("Version")
  valid_600716 = validateParameter(valid_600716, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600716 != nil:
    section.add "Version", valid_600716
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600717 = header.getOrDefault("X-Amz-Date")
  valid_600717 = validateParameter(valid_600717, JString, required = false,
                                 default = nil)
  if valid_600717 != nil:
    section.add "X-Amz-Date", valid_600717
  var valid_600718 = header.getOrDefault("X-Amz-Security-Token")
  valid_600718 = validateParameter(valid_600718, JString, required = false,
                                 default = nil)
  if valid_600718 != nil:
    section.add "X-Amz-Security-Token", valid_600718
  var valid_600719 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600719 = validateParameter(valid_600719, JString, required = false,
                                 default = nil)
  if valid_600719 != nil:
    section.add "X-Amz-Content-Sha256", valid_600719
  var valid_600720 = header.getOrDefault("X-Amz-Algorithm")
  valid_600720 = validateParameter(valid_600720, JString, required = false,
                                 default = nil)
  if valid_600720 != nil:
    section.add "X-Amz-Algorithm", valid_600720
  var valid_600721 = header.getOrDefault("X-Amz-Signature")
  valid_600721 = validateParameter(valid_600721, JString, required = false,
                                 default = nil)
  if valid_600721 != nil:
    section.add "X-Amz-Signature", valid_600721
  var valid_600722 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600722 = validateParameter(valid_600722, JString, required = false,
                                 default = nil)
  if valid_600722 != nil:
    section.add "X-Amz-SignedHeaders", valid_600722
  var valid_600723 = header.getOrDefault("X-Amz-Credential")
  valid_600723 = validateParameter(valid_600723, JString, required = false,
                                 default = nil)
  if valid_600723 != nil:
    section.add "X-Amz-Credential", valid_600723
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600724: Call_GetOptInPhoneNumber_600711; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ## 
  let valid = call_600724.validator(path, query, header, formData, body)
  let scheme = call_600724.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600724.url(scheme.get, call_600724.host, call_600724.base,
                         call_600724.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600724, url, valid)

proc call*(call_600725: Call_GetOptInPhoneNumber_600711; phoneNumber: string;
          Action: string = "OptInPhoneNumber"; Version: string = "2010-03-31"): Recallable =
  ## getOptInPhoneNumber
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number to opt in.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600726 = newJObject()
  add(query_600726, "phoneNumber", newJString(phoneNumber))
  add(query_600726, "Action", newJString(Action))
  add(query_600726, "Version", newJString(Version))
  result = call_600725.call(nil, query_600726, nil, nil, nil)

var getOptInPhoneNumber* = Call_GetOptInPhoneNumber_600711(
    name: "getOptInPhoneNumber", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=OptInPhoneNumber",
    validator: validate_GetOptInPhoneNumber_600712, base: "/",
    url: url_GetOptInPhoneNumber_600713, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPublish_600771 = ref object of OpenApiRestCall_599368
proc url_PostPublish_600773(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPublish_600772(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600774 = query.getOrDefault("Action")
  valid_600774 = validateParameter(valid_600774, JString, required = true,
                                 default = newJString("Publish"))
  if valid_600774 != nil:
    section.add "Action", valid_600774
  var valid_600775 = query.getOrDefault("Version")
  valid_600775 = validateParameter(valid_600775, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600775 != nil:
    section.add "Version", valid_600775
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600776 = header.getOrDefault("X-Amz-Date")
  valid_600776 = validateParameter(valid_600776, JString, required = false,
                                 default = nil)
  if valid_600776 != nil:
    section.add "X-Amz-Date", valid_600776
  var valid_600777 = header.getOrDefault("X-Amz-Security-Token")
  valid_600777 = validateParameter(valid_600777, JString, required = false,
                                 default = nil)
  if valid_600777 != nil:
    section.add "X-Amz-Security-Token", valid_600777
  var valid_600778 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600778 = validateParameter(valid_600778, JString, required = false,
                                 default = nil)
  if valid_600778 != nil:
    section.add "X-Amz-Content-Sha256", valid_600778
  var valid_600779 = header.getOrDefault("X-Amz-Algorithm")
  valid_600779 = validateParameter(valid_600779, JString, required = false,
                                 default = nil)
  if valid_600779 != nil:
    section.add "X-Amz-Algorithm", valid_600779
  var valid_600780 = header.getOrDefault("X-Amz-Signature")
  valid_600780 = validateParameter(valid_600780, JString, required = false,
                                 default = nil)
  if valid_600780 != nil:
    section.add "X-Amz-Signature", valid_600780
  var valid_600781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600781 = validateParameter(valid_600781, JString, required = false,
                                 default = nil)
  if valid_600781 != nil:
    section.add "X-Amz-SignedHeaders", valid_600781
  var valid_600782 = header.getOrDefault("X-Amz-Credential")
  valid_600782 = validateParameter(valid_600782, JString, required = false,
                                 default = nil)
  if valid_600782 != nil:
    section.add "X-Amz-Credential", valid_600782
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
  var valid_600783 = formData.getOrDefault("TopicArn")
  valid_600783 = validateParameter(valid_600783, JString, required = false,
                                 default = nil)
  if valid_600783 != nil:
    section.add "TopicArn", valid_600783
  var valid_600784 = formData.getOrDefault("Subject")
  valid_600784 = validateParameter(valid_600784, JString, required = false,
                                 default = nil)
  if valid_600784 != nil:
    section.add "Subject", valid_600784
  var valid_600785 = formData.getOrDefault("MessageAttributes.1.key")
  valid_600785 = validateParameter(valid_600785, JString, required = false,
                                 default = nil)
  if valid_600785 != nil:
    section.add "MessageAttributes.1.key", valid_600785
  var valid_600786 = formData.getOrDefault("TargetArn")
  valid_600786 = validateParameter(valid_600786, JString, required = false,
                                 default = nil)
  if valid_600786 != nil:
    section.add "TargetArn", valid_600786
  var valid_600787 = formData.getOrDefault("PhoneNumber")
  valid_600787 = validateParameter(valid_600787, JString, required = false,
                                 default = nil)
  if valid_600787 != nil:
    section.add "PhoneNumber", valid_600787
  var valid_600788 = formData.getOrDefault("MessageAttributes.0.value")
  valid_600788 = validateParameter(valid_600788, JString, required = false,
                                 default = nil)
  if valid_600788 != nil:
    section.add "MessageAttributes.0.value", valid_600788
  var valid_600789 = formData.getOrDefault("MessageAttributes.1.value")
  valid_600789 = validateParameter(valid_600789, JString, required = false,
                                 default = nil)
  if valid_600789 != nil:
    section.add "MessageAttributes.1.value", valid_600789
  var valid_600790 = formData.getOrDefault("MessageAttributes.0.key")
  valid_600790 = validateParameter(valid_600790, JString, required = false,
                                 default = nil)
  if valid_600790 != nil:
    section.add "MessageAttributes.0.key", valid_600790
  assert formData != nil,
        "formData argument is necessary due to required `Message` field"
  var valid_600791 = formData.getOrDefault("Message")
  valid_600791 = validateParameter(valid_600791, JString, required = true,
                                 default = nil)
  if valid_600791 != nil:
    section.add "Message", valid_600791
  var valid_600792 = formData.getOrDefault("MessageStructure")
  valid_600792 = validateParameter(valid_600792, JString, required = false,
                                 default = nil)
  if valid_600792 != nil:
    section.add "MessageStructure", valid_600792
  var valid_600793 = formData.getOrDefault("MessageAttributes.2.key")
  valid_600793 = validateParameter(valid_600793, JString, required = false,
                                 default = nil)
  if valid_600793 != nil:
    section.add "MessageAttributes.2.key", valid_600793
  var valid_600794 = formData.getOrDefault("MessageAttributes.2.value")
  valid_600794 = validateParameter(valid_600794, JString, required = false,
                                 default = nil)
  if valid_600794 != nil:
    section.add "MessageAttributes.2.value", valid_600794
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600795: Call_PostPublish_600771; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  let valid = call_600795.validator(path, query, header, formData, body)
  let scheme = call_600795.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600795.url(scheme.get, call_600795.host, call_600795.base,
                         call_600795.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600795, url, valid)

proc call*(call_600796: Call_PostPublish_600771; Message: string;
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
  var query_600797 = newJObject()
  var formData_600798 = newJObject()
  add(formData_600798, "TopicArn", newJString(TopicArn))
  add(formData_600798, "Subject", newJString(Subject))
  add(formData_600798, "MessageAttributes.1.key",
      newJString(MessageAttributes1Key))
  add(formData_600798, "TargetArn", newJString(TargetArn))
  add(formData_600798, "PhoneNumber", newJString(PhoneNumber))
  add(formData_600798, "MessageAttributes.0.value",
      newJString(MessageAttributes0Value))
  add(formData_600798, "MessageAttributes.1.value",
      newJString(MessageAttributes1Value))
  add(formData_600798, "MessageAttributes.0.key",
      newJString(MessageAttributes0Key))
  add(formData_600798, "Message", newJString(Message))
  add(query_600797, "Action", newJString(Action))
  add(formData_600798, "MessageStructure", newJString(MessageStructure))
  add(formData_600798, "MessageAttributes.2.key",
      newJString(MessageAttributes2Key))
  add(query_600797, "Version", newJString(Version))
  add(formData_600798, "MessageAttributes.2.value",
      newJString(MessageAttributes2Value))
  result = call_600796.call(nil, query_600797, nil, formData_600798, nil)

var postPublish* = Call_PostPublish_600771(name: "postPublish",
                                        meth: HttpMethod.HttpPost,
                                        host: "sns.amazonaws.com",
                                        route: "/#Action=Publish",
                                        validator: validate_PostPublish_600772,
                                        base: "/", url: url_PostPublish_600773,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublish_600744 = ref object of OpenApiRestCall_599368
proc url_GetPublish_600746(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPublish_600745(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600747 = query.getOrDefault("MessageAttributes.0.value")
  valid_600747 = validateParameter(valid_600747, JString, required = false,
                                 default = nil)
  if valid_600747 != nil:
    section.add "MessageAttributes.0.value", valid_600747
  var valid_600748 = query.getOrDefault("MessageAttributes.0.key")
  valid_600748 = validateParameter(valid_600748, JString, required = false,
                                 default = nil)
  if valid_600748 != nil:
    section.add "MessageAttributes.0.key", valid_600748
  var valid_600749 = query.getOrDefault("MessageAttributes.1.value")
  valid_600749 = validateParameter(valid_600749, JString, required = false,
                                 default = nil)
  if valid_600749 != nil:
    section.add "MessageAttributes.1.value", valid_600749
  assert query != nil, "query argument is necessary due to required `Message` field"
  var valid_600750 = query.getOrDefault("Message")
  valid_600750 = validateParameter(valid_600750, JString, required = true,
                                 default = nil)
  if valid_600750 != nil:
    section.add "Message", valid_600750
  var valid_600751 = query.getOrDefault("Subject")
  valid_600751 = validateParameter(valid_600751, JString, required = false,
                                 default = nil)
  if valid_600751 != nil:
    section.add "Subject", valid_600751
  var valid_600752 = query.getOrDefault("Action")
  valid_600752 = validateParameter(valid_600752, JString, required = true,
                                 default = newJString("Publish"))
  if valid_600752 != nil:
    section.add "Action", valid_600752
  var valid_600753 = query.getOrDefault("MessageAttributes.2.value")
  valid_600753 = validateParameter(valid_600753, JString, required = false,
                                 default = nil)
  if valid_600753 != nil:
    section.add "MessageAttributes.2.value", valid_600753
  var valid_600754 = query.getOrDefault("MessageStructure")
  valid_600754 = validateParameter(valid_600754, JString, required = false,
                                 default = nil)
  if valid_600754 != nil:
    section.add "MessageStructure", valid_600754
  var valid_600755 = query.getOrDefault("TopicArn")
  valid_600755 = validateParameter(valid_600755, JString, required = false,
                                 default = nil)
  if valid_600755 != nil:
    section.add "TopicArn", valid_600755
  var valid_600756 = query.getOrDefault("PhoneNumber")
  valid_600756 = validateParameter(valid_600756, JString, required = false,
                                 default = nil)
  if valid_600756 != nil:
    section.add "PhoneNumber", valid_600756
  var valid_600757 = query.getOrDefault("MessageAttributes.1.key")
  valid_600757 = validateParameter(valid_600757, JString, required = false,
                                 default = nil)
  if valid_600757 != nil:
    section.add "MessageAttributes.1.key", valid_600757
  var valid_600758 = query.getOrDefault("MessageAttributes.2.key")
  valid_600758 = validateParameter(valid_600758, JString, required = false,
                                 default = nil)
  if valid_600758 != nil:
    section.add "MessageAttributes.2.key", valid_600758
  var valid_600759 = query.getOrDefault("TargetArn")
  valid_600759 = validateParameter(valid_600759, JString, required = false,
                                 default = nil)
  if valid_600759 != nil:
    section.add "TargetArn", valid_600759
  var valid_600760 = query.getOrDefault("Version")
  valid_600760 = validateParameter(valid_600760, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600760 != nil:
    section.add "Version", valid_600760
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600761 = header.getOrDefault("X-Amz-Date")
  valid_600761 = validateParameter(valid_600761, JString, required = false,
                                 default = nil)
  if valid_600761 != nil:
    section.add "X-Amz-Date", valid_600761
  var valid_600762 = header.getOrDefault("X-Amz-Security-Token")
  valid_600762 = validateParameter(valid_600762, JString, required = false,
                                 default = nil)
  if valid_600762 != nil:
    section.add "X-Amz-Security-Token", valid_600762
  var valid_600763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600763 = validateParameter(valid_600763, JString, required = false,
                                 default = nil)
  if valid_600763 != nil:
    section.add "X-Amz-Content-Sha256", valid_600763
  var valid_600764 = header.getOrDefault("X-Amz-Algorithm")
  valid_600764 = validateParameter(valid_600764, JString, required = false,
                                 default = nil)
  if valid_600764 != nil:
    section.add "X-Amz-Algorithm", valid_600764
  var valid_600765 = header.getOrDefault("X-Amz-Signature")
  valid_600765 = validateParameter(valid_600765, JString, required = false,
                                 default = nil)
  if valid_600765 != nil:
    section.add "X-Amz-Signature", valid_600765
  var valid_600766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600766 = validateParameter(valid_600766, JString, required = false,
                                 default = nil)
  if valid_600766 != nil:
    section.add "X-Amz-SignedHeaders", valid_600766
  var valid_600767 = header.getOrDefault("X-Amz-Credential")
  valid_600767 = validateParameter(valid_600767, JString, required = false,
                                 default = nil)
  if valid_600767 != nil:
    section.add "X-Amz-Credential", valid_600767
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600768: Call_GetPublish_600744; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  let valid = call_600768.validator(path, query, header, formData, body)
  let scheme = call_600768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600768.url(scheme.get, call_600768.host, call_600768.base,
                         call_600768.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600768, url, valid)

proc call*(call_600769: Call_GetPublish_600744; Message: string;
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
  var query_600770 = newJObject()
  add(query_600770, "MessageAttributes.0.value",
      newJString(MessageAttributes0Value))
  add(query_600770, "MessageAttributes.0.key", newJString(MessageAttributes0Key))
  add(query_600770, "MessageAttributes.1.value",
      newJString(MessageAttributes1Value))
  add(query_600770, "Message", newJString(Message))
  add(query_600770, "Subject", newJString(Subject))
  add(query_600770, "Action", newJString(Action))
  add(query_600770, "MessageAttributes.2.value",
      newJString(MessageAttributes2Value))
  add(query_600770, "MessageStructure", newJString(MessageStructure))
  add(query_600770, "TopicArn", newJString(TopicArn))
  add(query_600770, "PhoneNumber", newJString(PhoneNumber))
  add(query_600770, "MessageAttributes.1.key", newJString(MessageAttributes1Key))
  add(query_600770, "MessageAttributes.2.key", newJString(MessageAttributes2Key))
  add(query_600770, "TargetArn", newJString(TargetArn))
  add(query_600770, "Version", newJString(Version))
  result = call_600769.call(nil, query_600770, nil, nil, nil)

var getPublish* = Call_GetPublish_600744(name: "getPublish",
                                      meth: HttpMethod.HttpGet,
                                      host: "sns.amazonaws.com",
                                      route: "/#Action=Publish",
                                      validator: validate_GetPublish_600745,
                                      base: "/", url: url_GetPublish_600746,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemovePermission_600816 = ref object of OpenApiRestCall_599368
proc url_PostRemovePermission_600818(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemovePermission_600817(path: JsonNode; query: JsonNode;
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
  var valid_600819 = query.getOrDefault("Action")
  valid_600819 = validateParameter(valid_600819, JString, required = true,
                                 default = newJString("RemovePermission"))
  if valid_600819 != nil:
    section.add "Action", valid_600819
  var valid_600820 = query.getOrDefault("Version")
  valid_600820 = validateParameter(valid_600820, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600820 != nil:
    section.add "Version", valid_600820
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600821 = header.getOrDefault("X-Amz-Date")
  valid_600821 = validateParameter(valid_600821, JString, required = false,
                                 default = nil)
  if valid_600821 != nil:
    section.add "X-Amz-Date", valid_600821
  var valid_600822 = header.getOrDefault("X-Amz-Security-Token")
  valid_600822 = validateParameter(valid_600822, JString, required = false,
                                 default = nil)
  if valid_600822 != nil:
    section.add "X-Amz-Security-Token", valid_600822
  var valid_600823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600823 = validateParameter(valid_600823, JString, required = false,
                                 default = nil)
  if valid_600823 != nil:
    section.add "X-Amz-Content-Sha256", valid_600823
  var valid_600824 = header.getOrDefault("X-Amz-Algorithm")
  valid_600824 = validateParameter(valid_600824, JString, required = false,
                                 default = nil)
  if valid_600824 != nil:
    section.add "X-Amz-Algorithm", valid_600824
  var valid_600825 = header.getOrDefault("X-Amz-Signature")
  valid_600825 = validateParameter(valid_600825, JString, required = false,
                                 default = nil)
  if valid_600825 != nil:
    section.add "X-Amz-Signature", valid_600825
  var valid_600826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600826 = validateParameter(valid_600826, JString, required = false,
                                 default = nil)
  if valid_600826 != nil:
    section.add "X-Amz-SignedHeaders", valid_600826
  var valid_600827 = header.getOrDefault("X-Amz-Credential")
  valid_600827 = validateParameter(valid_600827, JString, required = false,
                                 default = nil)
  if valid_600827 != nil:
    section.add "X-Amz-Credential", valid_600827
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Label: JString (required)
  ##        : The unique label of the statement you want to remove.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_600828 = formData.getOrDefault("TopicArn")
  valid_600828 = validateParameter(valid_600828, JString, required = true,
                                 default = nil)
  if valid_600828 != nil:
    section.add "TopicArn", valid_600828
  var valid_600829 = formData.getOrDefault("Label")
  valid_600829 = validateParameter(valid_600829, JString, required = true,
                                 default = nil)
  if valid_600829 != nil:
    section.add "Label", valid_600829
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600830: Call_PostRemovePermission_600816; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a statement from a topic's access control policy.
  ## 
  let valid = call_600830.validator(path, query, header, formData, body)
  let scheme = call_600830.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600830.url(scheme.get, call_600830.host, call_600830.base,
                         call_600830.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600830, url, valid)

proc call*(call_600831: Call_PostRemovePermission_600816; TopicArn: string;
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
  var query_600832 = newJObject()
  var formData_600833 = newJObject()
  add(formData_600833, "TopicArn", newJString(TopicArn))
  add(formData_600833, "Label", newJString(Label))
  add(query_600832, "Action", newJString(Action))
  add(query_600832, "Version", newJString(Version))
  result = call_600831.call(nil, query_600832, nil, formData_600833, nil)

var postRemovePermission* = Call_PostRemovePermission_600816(
    name: "postRemovePermission", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=RemovePermission",
    validator: validate_PostRemovePermission_600817, base: "/",
    url: url_PostRemovePermission_600818, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemovePermission_600799 = ref object of OpenApiRestCall_599368
proc url_GetRemovePermission_600801(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemovePermission_600800(path: JsonNode; query: JsonNode;
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
  var valid_600802 = query.getOrDefault("Action")
  valid_600802 = validateParameter(valid_600802, JString, required = true,
                                 default = newJString("RemovePermission"))
  if valid_600802 != nil:
    section.add "Action", valid_600802
  var valid_600803 = query.getOrDefault("TopicArn")
  valid_600803 = validateParameter(valid_600803, JString, required = true,
                                 default = nil)
  if valid_600803 != nil:
    section.add "TopicArn", valid_600803
  var valid_600804 = query.getOrDefault("Version")
  valid_600804 = validateParameter(valid_600804, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600804 != nil:
    section.add "Version", valid_600804
  var valid_600805 = query.getOrDefault("Label")
  valid_600805 = validateParameter(valid_600805, JString, required = true,
                                 default = nil)
  if valid_600805 != nil:
    section.add "Label", valid_600805
  result.add "query", section
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
  if body != nil:
    result.add "body", body

proc call*(call_600813: Call_GetRemovePermission_600799; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a statement from a topic's access control policy.
  ## 
  let valid = call_600813.validator(path, query, header, formData, body)
  let scheme = call_600813.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600813.url(scheme.get, call_600813.host, call_600813.base,
                         call_600813.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600813, url, valid)

proc call*(call_600814: Call_GetRemovePermission_600799; TopicArn: string;
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
  var query_600815 = newJObject()
  add(query_600815, "Action", newJString(Action))
  add(query_600815, "TopicArn", newJString(TopicArn))
  add(query_600815, "Version", newJString(Version))
  add(query_600815, "Label", newJString(Label))
  result = call_600814.call(nil, query_600815, nil, nil, nil)

var getRemovePermission* = Call_GetRemovePermission_600799(
    name: "getRemovePermission", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=RemovePermission",
    validator: validate_GetRemovePermission_600800, base: "/",
    url: url_GetRemovePermission_600801, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetEndpointAttributes_600856 = ref object of OpenApiRestCall_599368
proc url_PostSetEndpointAttributes_600858(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetEndpointAttributes_600857(path: JsonNode; query: JsonNode;
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
  var valid_600859 = query.getOrDefault("Action")
  valid_600859 = validateParameter(valid_600859, JString, required = true,
                                 default = newJString("SetEndpointAttributes"))
  if valid_600859 != nil:
    section.add "Action", valid_600859
  var valid_600860 = query.getOrDefault("Version")
  valid_600860 = validateParameter(valid_600860, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600860 != nil:
    section.add "Version", valid_600860
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600861 = header.getOrDefault("X-Amz-Date")
  valid_600861 = validateParameter(valid_600861, JString, required = false,
                                 default = nil)
  if valid_600861 != nil:
    section.add "X-Amz-Date", valid_600861
  var valid_600862 = header.getOrDefault("X-Amz-Security-Token")
  valid_600862 = validateParameter(valid_600862, JString, required = false,
                                 default = nil)
  if valid_600862 != nil:
    section.add "X-Amz-Security-Token", valid_600862
  var valid_600863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600863 = validateParameter(valid_600863, JString, required = false,
                                 default = nil)
  if valid_600863 != nil:
    section.add "X-Amz-Content-Sha256", valid_600863
  var valid_600864 = header.getOrDefault("X-Amz-Algorithm")
  valid_600864 = validateParameter(valid_600864, JString, required = false,
                                 default = nil)
  if valid_600864 != nil:
    section.add "X-Amz-Algorithm", valid_600864
  var valid_600865 = header.getOrDefault("X-Amz-Signature")
  valid_600865 = validateParameter(valid_600865, JString, required = false,
                                 default = nil)
  if valid_600865 != nil:
    section.add "X-Amz-Signature", valid_600865
  var valid_600866 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600866 = validateParameter(valid_600866, JString, required = false,
                                 default = nil)
  if valid_600866 != nil:
    section.add "X-Amz-SignedHeaders", valid_600866
  var valid_600867 = header.getOrDefault("X-Amz-Credential")
  valid_600867 = validateParameter(valid_600867, JString, required = false,
                                 default = nil)
  if valid_600867 != nil:
    section.add "X-Amz-Credential", valid_600867
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
  var valid_600868 = formData.getOrDefault("Attributes.0.value")
  valid_600868 = validateParameter(valid_600868, JString, required = false,
                                 default = nil)
  if valid_600868 != nil:
    section.add "Attributes.0.value", valid_600868
  var valid_600869 = formData.getOrDefault("Attributes.0.key")
  valid_600869 = validateParameter(valid_600869, JString, required = false,
                                 default = nil)
  if valid_600869 != nil:
    section.add "Attributes.0.key", valid_600869
  var valid_600870 = formData.getOrDefault("Attributes.1.key")
  valid_600870 = validateParameter(valid_600870, JString, required = false,
                                 default = nil)
  if valid_600870 != nil:
    section.add "Attributes.1.key", valid_600870
  var valid_600871 = formData.getOrDefault("Attributes.2.value")
  valid_600871 = validateParameter(valid_600871, JString, required = false,
                                 default = nil)
  if valid_600871 != nil:
    section.add "Attributes.2.value", valid_600871
  var valid_600872 = formData.getOrDefault("Attributes.2.key")
  valid_600872 = validateParameter(valid_600872, JString, required = false,
                                 default = nil)
  if valid_600872 != nil:
    section.add "Attributes.2.key", valid_600872
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_600873 = formData.getOrDefault("EndpointArn")
  valid_600873 = validateParameter(valid_600873, JString, required = true,
                                 default = nil)
  if valid_600873 != nil:
    section.add "EndpointArn", valid_600873
  var valid_600874 = formData.getOrDefault("Attributes.1.value")
  valid_600874 = validateParameter(valid_600874, JString, required = false,
                                 default = nil)
  if valid_600874 != nil:
    section.add "Attributes.1.value", valid_600874
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600875: Call_PostSetEndpointAttributes_600856; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_600875.validator(path, query, header, formData, body)
  let scheme = call_600875.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600875.url(scheme.get, call_600875.host, call_600875.base,
                         call_600875.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600875, url, valid)

proc call*(call_600876: Call_PostSetEndpointAttributes_600856; EndpointArn: string;
          Attributes0Value: string = ""; Attributes0Key: string = "";
          Attributes1Key: string = ""; Action: string = "SetEndpointAttributes";
          Attributes2Value: string = ""; Attributes2Key: string = "";
          Version: string = "2010-03-31"; Attributes1Value: string = ""): Recallable =
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
  var query_600877 = newJObject()
  var formData_600878 = newJObject()
  add(formData_600878, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_600878, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_600878, "Attributes.1.key", newJString(Attributes1Key))
  add(query_600877, "Action", newJString(Action))
  add(formData_600878, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_600878, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_600878, "EndpointArn", newJString(EndpointArn))
  add(query_600877, "Version", newJString(Version))
  add(formData_600878, "Attributes.1.value", newJString(Attributes1Value))
  result = call_600876.call(nil, query_600877, nil, formData_600878, nil)

var postSetEndpointAttributes* = Call_PostSetEndpointAttributes_600856(
    name: "postSetEndpointAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetEndpointAttributes",
    validator: validate_PostSetEndpointAttributes_600857, base: "/",
    url: url_PostSetEndpointAttributes_600858,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetEndpointAttributes_600834 = ref object of OpenApiRestCall_599368
proc url_GetSetEndpointAttributes_600836(protocol: Scheme; host: string;
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

proc validate_GetSetEndpointAttributes_600835(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600837 = query.getOrDefault("EndpointArn")
  valid_600837 = validateParameter(valid_600837, JString, required = true,
                                 default = nil)
  if valid_600837 != nil:
    section.add "EndpointArn", valid_600837
  var valid_600838 = query.getOrDefault("Attributes.2.key")
  valid_600838 = validateParameter(valid_600838, JString, required = false,
                                 default = nil)
  if valid_600838 != nil:
    section.add "Attributes.2.key", valid_600838
  var valid_600839 = query.getOrDefault("Attributes.1.value")
  valid_600839 = validateParameter(valid_600839, JString, required = false,
                                 default = nil)
  if valid_600839 != nil:
    section.add "Attributes.1.value", valid_600839
  var valid_600840 = query.getOrDefault("Attributes.0.value")
  valid_600840 = validateParameter(valid_600840, JString, required = false,
                                 default = nil)
  if valid_600840 != nil:
    section.add "Attributes.0.value", valid_600840
  var valid_600841 = query.getOrDefault("Action")
  valid_600841 = validateParameter(valid_600841, JString, required = true,
                                 default = newJString("SetEndpointAttributes"))
  if valid_600841 != nil:
    section.add "Action", valid_600841
  var valid_600842 = query.getOrDefault("Attributes.1.key")
  valid_600842 = validateParameter(valid_600842, JString, required = false,
                                 default = nil)
  if valid_600842 != nil:
    section.add "Attributes.1.key", valid_600842
  var valid_600843 = query.getOrDefault("Attributes.2.value")
  valid_600843 = validateParameter(valid_600843, JString, required = false,
                                 default = nil)
  if valid_600843 != nil:
    section.add "Attributes.2.value", valid_600843
  var valid_600844 = query.getOrDefault("Attributes.0.key")
  valid_600844 = validateParameter(valid_600844, JString, required = false,
                                 default = nil)
  if valid_600844 != nil:
    section.add "Attributes.0.key", valid_600844
  var valid_600845 = query.getOrDefault("Version")
  valid_600845 = validateParameter(valid_600845, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600845 != nil:
    section.add "Version", valid_600845
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600846 = header.getOrDefault("X-Amz-Date")
  valid_600846 = validateParameter(valid_600846, JString, required = false,
                                 default = nil)
  if valid_600846 != nil:
    section.add "X-Amz-Date", valid_600846
  var valid_600847 = header.getOrDefault("X-Amz-Security-Token")
  valid_600847 = validateParameter(valid_600847, JString, required = false,
                                 default = nil)
  if valid_600847 != nil:
    section.add "X-Amz-Security-Token", valid_600847
  var valid_600848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600848 = validateParameter(valid_600848, JString, required = false,
                                 default = nil)
  if valid_600848 != nil:
    section.add "X-Amz-Content-Sha256", valid_600848
  var valid_600849 = header.getOrDefault("X-Amz-Algorithm")
  valid_600849 = validateParameter(valid_600849, JString, required = false,
                                 default = nil)
  if valid_600849 != nil:
    section.add "X-Amz-Algorithm", valid_600849
  var valid_600850 = header.getOrDefault("X-Amz-Signature")
  valid_600850 = validateParameter(valid_600850, JString, required = false,
                                 default = nil)
  if valid_600850 != nil:
    section.add "X-Amz-Signature", valid_600850
  var valid_600851 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600851 = validateParameter(valid_600851, JString, required = false,
                                 default = nil)
  if valid_600851 != nil:
    section.add "X-Amz-SignedHeaders", valid_600851
  var valid_600852 = header.getOrDefault("X-Amz-Credential")
  valid_600852 = validateParameter(valid_600852, JString, required = false,
                                 default = nil)
  if valid_600852 != nil:
    section.add "X-Amz-Credential", valid_600852
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600853: Call_GetSetEndpointAttributes_600834; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_600853.validator(path, query, header, formData, body)
  let scheme = call_600853.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600853.url(scheme.get, call_600853.host, call_600853.base,
                         call_600853.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600853, url, valid)

proc call*(call_600854: Call_GetSetEndpointAttributes_600834; EndpointArn: string;
          Attributes2Key: string = ""; Attributes1Value: string = "";
          Attributes0Value: string = ""; Action: string = "SetEndpointAttributes";
          Attributes1Key: string = ""; Attributes2Value: string = "";
          Attributes0Key: string = ""; Version: string = "2010-03-31"): Recallable =
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
  var query_600855 = newJObject()
  add(query_600855, "EndpointArn", newJString(EndpointArn))
  add(query_600855, "Attributes.2.key", newJString(Attributes2Key))
  add(query_600855, "Attributes.1.value", newJString(Attributes1Value))
  add(query_600855, "Attributes.0.value", newJString(Attributes0Value))
  add(query_600855, "Action", newJString(Action))
  add(query_600855, "Attributes.1.key", newJString(Attributes1Key))
  add(query_600855, "Attributes.2.value", newJString(Attributes2Value))
  add(query_600855, "Attributes.0.key", newJString(Attributes0Key))
  add(query_600855, "Version", newJString(Version))
  result = call_600854.call(nil, query_600855, nil, nil, nil)

var getSetEndpointAttributes* = Call_GetSetEndpointAttributes_600834(
    name: "getSetEndpointAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetEndpointAttributes",
    validator: validate_GetSetEndpointAttributes_600835, base: "/",
    url: url_GetSetEndpointAttributes_600836, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetPlatformApplicationAttributes_600901 = ref object of OpenApiRestCall_599368
proc url_PostSetPlatformApplicationAttributes_600903(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetPlatformApplicationAttributes_600902(path: JsonNode;
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
  var valid_600904 = query.getOrDefault("Action")
  valid_600904 = validateParameter(valid_600904, JString, required = true, default = newJString(
      "SetPlatformApplicationAttributes"))
  if valid_600904 != nil:
    section.add "Action", valid_600904
  var valid_600905 = query.getOrDefault("Version")
  valid_600905 = validateParameter(valid_600905, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600905 != nil:
    section.add "Version", valid_600905
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600906 = header.getOrDefault("X-Amz-Date")
  valid_600906 = validateParameter(valid_600906, JString, required = false,
                                 default = nil)
  if valid_600906 != nil:
    section.add "X-Amz-Date", valid_600906
  var valid_600907 = header.getOrDefault("X-Amz-Security-Token")
  valid_600907 = validateParameter(valid_600907, JString, required = false,
                                 default = nil)
  if valid_600907 != nil:
    section.add "X-Amz-Security-Token", valid_600907
  var valid_600908 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600908 = validateParameter(valid_600908, JString, required = false,
                                 default = nil)
  if valid_600908 != nil:
    section.add "X-Amz-Content-Sha256", valid_600908
  var valid_600909 = header.getOrDefault("X-Amz-Algorithm")
  valid_600909 = validateParameter(valid_600909, JString, required = false,
                                 default = nil)
  if valid_600909 != nil:
    section.add "X-Amz-Algorithm", valid_600909
  var valid_600910 = header.getOrDefault("X-Amz-Signature")
  valid_600910 = validateParameter(valid_600910, JString, required = false,
                                 default = nil)
  if valid_600910 != nil:
    section.add "X-Amz-Signature", valid_600910
  var valid_600911 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600911 = validateParameter(valid_600911, JString, required = false,
                                 default = nil)
  if valid_600911 != nil:
    section.add "X-Amz-SignedHeaders", valid_600911
  var valid_600912 = header.getOrDefault("X-Amz-Credential")
  valid_600912 = validateParameter(valid_600912, JString, required = false,
                                 default = nil)
  if valid_600912 != nil:
    section.add "X-Amz-Credential", valid_600912
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
  var valid_600913 = formData.getOrDefault("Attributes.0.value")
  valid_600913 = validateParameter(valid_600913, JString, required = false,
                                 default = nil)
  if valid_600913 != nil:
    section.add "Attributes.0.value", valid_600913
  var valid_600914 = formData.getOrDefault("Attributes.0.key")
  valid_600914 = validateParameter(valid_600914, JString, required = false,
                                 default = nil)
  if valid_600914 != nil:
    section.add "Attributes.0.key", valid_600914
  var valid_600915 = formData.getOrDefault("Attributes.1.key")
  valid_600915 = validateParameter(valid_600915, JString, required = false,
                                 default = nil)
  if valid_600915 != nil:
    section.add "Attributes.1.key", valid_600915
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_600916 = formData.getOrDefault("PlatformApplicationArn")
  valid_600916 = validateParameter(valid_600916, JString, required = true,
                                 default = nil)
  if valid_600916 != nil:
    section.add "PlatformApplicationArn", valid_600916
  var valid_600917 = formData.getOrDefault("Attributes.2.value")
  valid_600917 = validateParameter(valid_600917, JString, required = false,
                                 default = nil)
  if valid_600917 != nil:
    section.add "Attributes.2.value", valid_600917
  var valid_600918 = formData.getOrDefault("Attributes.2.key")
  valid_600918 = validateParameter(valid_600918, JString, required = false,
                                 default = nil)
  if valid_600918 != nil:
    section.add "Attributes.2.key", valid_600918
  var valid_600919 = formData.getOrDefault("Attributes.1.value")
  valid_600919 = validateParameter(valid_600919, JString, required = false,
                                 default = nil)
  if valid_600919 != nil:
    section.add "Attributes.1.value", valid_600919
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600920: Call_PostSetPlatformApplicationAttributes_600901;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  let valid = call_600920.validator(path, query, header, formData, body)
  let scheme = call_600920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600920.url(scheme.get, call_600920.host, call_600920.base,
                         call_600920.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600920, url, valid)

proc call*(call_600921: Call_PostSetPlatformApplicationAttributes_600901;
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
  var query_600922 = newJObject()
  var formData_600923 = newJObject()
  add(formData_600923, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_600923, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_600923, "Attributes.1.key", newJString(Attributes1Key))
  add(query_600922, "Action", newJString(Action))
  add(formData_600923, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(formData_600923, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_600923, "Attributes.2.key", newJString(Attributes2Key))
  add(query_600922, "Version", newJString(Version))
  add(formData_600923, "Attributes.1.value", newJString(Attributes1Value))
  result = call_600921.call(nil, query_600922, nil, formData_600923, nil)

var postSetPlatformApplicationAttributes* = Call_PostSetPlatformApplicationAttributes_600901(
    name: "postSetPlatformApplicationAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetPlatformApplicationAttributes",
    validator: validate_PostSetPlatformApplicationAttributes_600902, base: "/",
    url: url_PostSetPlatformApplicationAttributes_600903,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetPlatformApplicationAttributes_600879 = ref object of OpenApiRestCall_599368
proc url_GetSetPlatformApplicationAttributes_600881(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetPlatformApplicationAttributes_600880(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600882 = query.getOrDefault("Attributes.2.key")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "Attributes.2.key", valid_600882
  var valid_600883 = query.getOrDefault("Attributes.1.value")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "Attributes.1.value", valid_600883
  var valid_600884 = query.getOrDefault("Attributes.0.value")
  valid_600884 = validateParameter(valid_600884, JString, required = false,
                                 default = nil)
  if valid_600884 != nil:
    section.add "Attributes.0.value", valid_600884
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600885 = query.getOrDefault("Action")
  valid_600885 = validateParameter(valid_600885, JString, required = true, default = newJString(
      "SetPlatformApplicationAttributes"))
  if valid_600885 != nil:
    section.add "Action", valid_600885
  var valid_600886 = query.getOrDefault("Attributes.1.key")
  valid_600886 = validateParameter(valid_600886, JString, required = false,
                                 default = nil)
  if valid_600886 != nil:
    section.add "Attributes.1.key", valid_600886
  var valid_600887 = query.getOrDefault("Attributes.2.value")
  valid_600887 = validateParameter(valid_600887, JString, required = false,
                                 default = nil)
  if valid_600887 != nil:
    section.add "Attributes.2.value", valid_600887
  var valid_600888 = query.getOrDefault("Attributes.0.key")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "Attributes.0.key", valid_600888
  var valid_600889 = query.getOrDefault("Version")
  valid_600889 = validateParameter(valid_600889, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600889 != nil:
    section.add "Version", valid_600889
  var valid_600890 = query.getOrDefault("PlatformApplicationArn")
  valid_600890 = validateParameter(valid_600890, JString, required = true,
                                 default = nil)
  if valid_600890 != nil:
    section.add "PlatformApplicationArn", valid_600890
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600891 = header.getOrDefault("X-Amz-Date")
  valid_600891 = validateParameter(valid_600891, JString, required = false,
                                 default = nil)
  if valid_600891 != nil:
    section.add "X-Amz-Date", valid_600891
  var valid_600892 = header.getOrDefault("X-Amz-Security-Token")
  valid_600892 = validateParameter(valid_600892, JString, required = false,
                                 default = nil)
  if valid_600892 != nil:
    section.add "X-Amz-Security-Token", valid_600892
  var valid_600893 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600893 = validateParameter(valid_600893, JString, required = false,
                                 default = nil)
  if valid_600893 != nil:
    section.add "X-Amz-Content-Sha256", valid_600893
  var valid_600894 = header.getOrDefault("X-Amz-Algorithm")
  valid_600894 = validateParameter(valid_600894, JString, required = false,
                                 default = nil)
  if valid_600894 != nil:
    section.add "X-Amz-Algorithm", valid_600894
  var valid_600895 = header.getOrDefault("X-Amz-Signature")
  valid_600895 = validateParameter(valid_600895, JString, required = false,
                                 default = nil)
  if valid_600895 != nil:
    section.add "X-Amz-Signature", valid_600895
  var valid_600896 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600896 = validateParameter(valid_600896, JString, required = false,
                                 default = nil)
  if valid_600896 != nil:
    section.add "X-Amz-SignedHeaders", valid_600896
  var valid_600897 = header.getOrDefault("X-Amz-Credential")
  valid_600897 = validateParameter(valid_600897, JString, required = false,
                                 default = nil)
  if valid_600897 != nil:
    section.add "X-Amz-Credential", valid_600897
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600898: Call_GetSetPlatformApplicationAttributes_600879;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  let valid = call_600898.validator(path, query, header, formData, body)
  let scheme = call_600898.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600898.url(scheme.get, call_600898.host, call_600898.base,
                         call_600898.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600898, url, valid)

proc call*(call_600899: Call_GetSetPlatformApplicationAttributes_600879;
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
  var query_600900 = newJObject()
  add(query_600900, "Attributes.2.key", newJString(Attributes2Key))
  add(query_600900, "Attributes.1.value", newJString(Attributes1Value))
  add(query_600900, "Attributes.0.value", newJString(Attributes0Value))
  add(query_600900, "Action", newJString(Action))
  add(query_600900, "Attributes.1.key", newJString(Attributes1Key))
  add(query_600900, "Attributes.2.value", newJString(Attributes2Value))
  add(query_600900, "Attributes.0.key", newJString(Attributes0Key))
  add(query_600900, "Version", newJString(Version))
  add(query_600900, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  result = call_600899.call(nil, query_600900, nil, nil, nil)

var getSetPlatformApplicationAttributes* = Call_GetSetPlatformApplicationAttributes_600879(
    name: "getSetPlatformApplicationAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetPlatformApplicationAttributes",
    validator: validate_GetSetPlatformApplicationAttributes_600880, base: "/",
    url: url_GetSetPlatformApplicationAttributes_600881,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSMSAttributes_600945 = ref object of OpenApiRestCall_599368
proc url_PostSetSMSAttributes_600947(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetSMSAttributes_600946(path: JsonNode; query: JsonNode;
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
  var valid_600948 = query.getOrDefault("Action")
  valid_600948 = validateParameter(valid_600948, JString, required = true,
                                 default = newJString("SetSMSAttributes"))
  if valid_600948 != nil:
    section.add "Action", valid_600948
  var valid_600949 = query.getOrDefault("Version")
  valid_600949 = validateParameter(valid_600949, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600949 != nil:
    section.add "Version", valid_600949
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600950 = header.getOrDefault("X-Amz-Date")
  valid_600950 = validateParameter(valid_600950, JString, required = false,
                                 default = nil)
  if valid_600950 != nil:
    section.add "X-Amz-Date", valid_600950
  var valid_600951 = header.getOrDefault("X-Amz-Security-Token")
  valid_600951 = validateParameter(valid_600951, JString, required = false,
                                 default = nil)
  if valid_600951 != nil:
    section.add "X-Amz-Security-Token", valid_600951
  var valid_600952 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600952 = validateParameter(valid_600952, JString, required = false,
                                 default = nil)
  if valid_600952 != nil:
    section.add "X-Amz-Content-Sha256", valid_600952
  var valid_600953 = header.getOrDefault("X-Amz-Algorithm")
  valid_600953 = validateParameter(valid_600953, JString, required = false,
                                 default = nil)
  if valid_600953 != nil:
    section.add "X-Amz-Algorithm", valid_600953
  var valid_600954 = header.getOrDefault("X-Amz-Signature")
  valid_600954 = validateParameter(valid_600954, JString, required = false,
                                 default = nil)
  if valid_600954 != nil:
    section.add "X-Amz-Signature", valid_600954
  var valid_600955 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600955 = validateParameter(valid_600955, JString, required = false,
                                 default = nil)
  if valid_600955 != nil:
    section.add "X-Amz-SignedHeaders", valid_600955
  var valid_600956 = header.getOrDefault("X-Amz-Credential")
  valid_600956 = validateParameter(valid_600956, JString, required = false,
                                 default = nil)
  if valid_600956 != nil:
    section.add "X-Amz-Credential", valid_600956
  result.add "header", section
  ## parameters in `formData` object:
  ##   attributes.2.value: JString
  ##   attributes.2.key: JString
  ##   attributes.1.value: JString
  ##   attributes.1.key: JString
  ##   attributes.0.key: JString
  ##   attributes.0.value: JString
  section = newJObject()
  var valid_600957 = formData.getOrDefault("attributes.2.value")
  valid_600957 = validateParameter(valid_600957, JString, required = false,
                                 default = nil)
  if valid_600957 != nil:
    section.add "attributes.2.value", valid_600957
  var valid_600958 = formData.getOrDefault("attributes.2.key")
  valid_600958 = validateParameter(valid_600958, JString, required = false,
                                 default = nil)
  if valid_600958 != nil:
    section.add "attributes.2.key", valid_600958
  var valid_600959 = formData.getOrDefault("attributes.1.value")
  valid_600959 = validateParameter(valid_600959, JString, required = false,
                                 default = nil)
  if valid_600959 != nil:
    section.add "attributes.1.value", valid_600959
  var valid_600960 = formData.getOrDefault("attributes.1.key")
  valid_600960 = validateParameter(valid_600960, JString, required = false,
                                 default = nil)
  if valid_600960 != nil:
    section.add "attributes.1.key", valid_600960
  var valid_600961 = formData.getOrDefault("attributes.0.key")
  valid_600961 = validateParameter(valid_600961, JString, required = false,
                                 default = nil)
  if valid_600961 != nil:
    section.add "attributes.0.key", valid_600961
  var valid_600962 = formData.getOrDefault("attributes.0.value")
  valid_600962 = validateParameter(valid_600962, JString, required = false,
                                 default = nil)
  if valid_600962 != nil:
    section.add "attributes.0.value", valid_600962
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600963: Call_PostSetSMSAttributes_600945; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_600963.validator(path, query, header, formData, body)
  let scheme = call_600963.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600963.url(scheme.get, call_600963.host, call_600963.base,
                         call_600963.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600963, url, valid)

proc call*(call_600964: Call_PostSetSMSAttributes_600945;
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
  var query_600965 = newJObject()
  var formData_600966 = newJObject()
  add(formData_600966, "attributes.2.value", newJString(attributes2Value))
  add(formData_600966, "attributes.2.key", newJString(attributes2Key))
  add(query_600965, "Action", newJString(Action))
  add(formData_600966, "attributes.1.value", newJString(attributes1Value))
  add(formData_600966, "attributes.1.key", newJString(attributes1Key))
  add(formData_600966, "attributes.0.key", newJString(attributes0Key))
  add(query_600965, "Version", newJString(Version))
  add(formData_600966, "attributes.0.value", newJString(attributes0Value))
  result = call_600964.call(nil, query_600965, nil, formData_600966, nil)

var postSetSMSAttributes* = Call_PostSetSMSAttributes_600945(
    name: "postSetSMSAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetSMSAttributes",
    validator: validate_PostSetSMSAttributes_600946, base: "/",
    url: url_PostSetSMSAttributes_600947, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSMSAttributes_600924 = ref object of OpenApiRestCall_599368
proc url_GetSetSMSAttributes_600926(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetSMSAttributes_600925(path: JsonNode; query: JsonNode;
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
  var valid_600927 = query.getOrDefault("attributes.2.key")
  valid_600927 = validateParameter(valid_600927, JString, required = false,
                                 default = nil)
  if valid_600927 != nil:
    section.add "attributes.2.key", valid_600927
  var valid_600928 = query.getOrDefault("attributes.1.key")
  valid_600928 = validateParameter(valid_600928, JString, required = false,
                                 default = nil)
  if valid_600928 != nil:
    section.add "attributes.1.key", valid_600928
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600929 = query.getOrDefault("Action")
  valid_600929 = validateParameter(valid_600929, JString, required = true,
                                 default = newJString("SetSMSAttributes"))
  if valid_600929 != nil:
    section.add "Action", valid_600929
  var valid_600930 = query.getOrDefault("attributes.1.value")
  valid_600930 = validateParameter(valid_600930, JString, required = false,
                                 default = nil)
  if valid_600930 != nil:
    section.add "attributes.1.value", valid_600930
  var valid_600931 = query.getOrDefault("attributes.0.value")
  valid_600931 = validateParameter(valid_600931, JString, required = false,
                                 default = nil)
  if valid_600931 != nil:
    section.add "attributes.0.value", valid_600931
  var valid_600932 = query.getOrDefault("attributes.2.value")
  valid_600932 = validateParameter(valid_600932, JString, required = false,
                                 default = nil)
  if valid_600932 != nil:
    section.add "attributes.2.value", valid_600932
  var valid_600933 = query.getOrDefault("attributes.0.key")
  valid_600933 = validateParameter(valid_600933, JString, required = false,
                                 default = nil)
  if valid_600933 != nil:
    section.add "attributes.0.key", valid_600933
  var valid_600934 = query.getOrDefault("Version")
  valid_600934 = validateParameter(valid_600934, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600934 != nil:
    section.add "Version", valid_600934
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600935 = header.getOrDefault("X-Amz-Date")
  valid_600935 = validateParameter(valid_600935, JString, required = false,
                                 default = nil)
  if valid_600935 != nil:
    section.add "X-Amz-Date", valid_600935
  var valid_600936 = header.getOrDefault("X-Amz-Security-Token")
  valid_600936 = validateParameter(valid_600936, JString, required = false,
                                 default = nil)
  if valid_600936 != nil:
    section.add "X-Amz-Security-Token", valid_600936
  var valid_600937 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600937 = validateParameter(valid_600937, JString, required = false,
                                 default = nil)
  if valid_600937 != nil:
    section.add "X-Amz-Content-Sha256", valid_600937
  var valid_600938 = header.getOrDefault("X-Amz-Algorithm")
  valid_600938 = validateParameter(valid_600938, JString, required = false,
                                 default = nil)
  if valid_600938 != nil:
    section.add "X-Amz-Algorithm", valid_600938
  var valid_600939 = header.getOrDefault("X-Amz-Signature")
  valid_600939 = validateParameter(valid_600939, JString, required = false,
                                 default = nil)
  if valid_600939 != nil:
    section.add "X-Amz-Signature", valid_600939
  var valid_600940 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600940 = validateParameter(valid_600940, JString, required = false,
                                 default = nil)
  if valid_600940 != nil:
    section.add "X-Amz-SignedHeaders", valid_600940
  var valid_600941 = header.getOrDefault("X-Amz-Credential")
  valid_600941 = validateParameter(valid_600941, JString, required = false,
                                 default = nil)
  if valid_600941 != nil:
    section.add "X-Amz-Credential", valid_600941
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600942: Call_GetSetSMSAttributes_600924; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_600942.validator(path, query, header, formData, body)
  let scheme = call_600942.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600942.url(scheme.get, call_600942.host, call_600942.base,
                         call_600942.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600942, url, valid)

proc call*(call_600943: Call_GetSetSMSAttributes_600924;
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
  var query_600944 = newJObject()
  add(query_600944, "attributes.2.key", newJString(attributes2Key))
  add(query_600944, "attributes.1.key", newJString(attributes1Key))
  add(query_600944, "Action", newJString(Action))
  add(query_600944, "attributes.1.value", newJString(attributes1Value))
  add(query_600944, "attributes.0.value", newJString(attributes0Value))
  add(query_600944, "attributes.2.value", newJString(attributes2Value))
  add(query_600944, "attributes.0.key", newJString(attributes0Key))
  add(query_600944, "Version", newJString(Version))
  result = call_600943.call(nil, query_600944, nil, nil, nil)

var getSetSMSAttributes* = Call_GetSetSMSAttributes_600924(
    name: "getSetSMSAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetSMSAttributes",
    validator: validate_GetSetSMSAttributes_600925, base: "/",
    url: url_GetSetSMSAttributes_600926, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSubscriptionAttributes_600985 = ref object of OpenApiRestCall_599368
proc url_PostSetSubscriptionAttributes_600987(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetSubscriptionAttributes_600986(path: JsonNode; query: JsonNode;
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
  var valid_600988 = query.getOrDefault("Action")
  valid_600988 = validateParameter(valid_600988, JString, required = true, default = newJString(
      "SetSubscriptionAttributes"))
  if valid_600988 != nil:
    section.add "Action", valid_600988
  var valid_600989 = query.getOrDefault("Version")
  valid_600989 = validateParameter(valid_600989, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600989 != nil:
    section.add "Version", valid_600989
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600990 = header.getOrDefault("X-Amz-Date")
  valid_600990 = validateParameter(valid_600990, JString, required = false,
                                 default = nil)
  if valid_600990 != nil:
    section.add "X-Amz-Date", valid_600990
  var valid_600991 = header.getOrDefault("X-Amz-Security-Token")
  valid_600991 = validateParameter(valid_600991, JString, required = false,
                                 default = nil)
  if valid_600991 != nil:
    section.add "X-Amz-Security-Token", valid_600991
  var valid_600992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600992 = validateParameter(valid_600992, JString, required = false,
                                 default = nil)
  if valid_600992 != nil:
    section.add "X-Amz-Content-Sha256", valid_600992
  var valid_600993 = header.getOrDefault("X-Amz-Algorithm")
  valid_600993 = validateParameter(valid_600993, JString, required = false,
                                 default = nil)
  if valid_600993 != nil:
    section.add "X-Amz-Algorithm", valid_600993
  var valid_600994 = header.getOrDefault("X-Amz-Signature")
  valid_600994 = validateParameter(valid_600994, JString, required = false,
                                 default = nil)
  if valid_600994 != nil:
    section.add "X-Amz-Signature", valid_600994
  var valid_600995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600995 = validateParameter(valid_600995, JString, required = false,
                                 default = nil)
  if valid_600995 != nil:
    section.add "X-Amz-SignedHeaders", valid_600995
  var valid_600996 = header.getOrDefault("X-Amz-Credential")
  valid_600996 = validateParameter(valid_600996, JString, required = false,
                                 default = nil)
  if valid_600996 != nil:
    section.add "X-Amz-Credential", valid_600996
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
  var valid_600997 = formData.getOrDefault("AttributeName")
  valid_600997 = validateParameter(valid_600997, JString, required = true,
                                 default = nil)
  if valid_600997 != nil:
    section.add "AttributeName", valid_600997
  var valid_600998 = formData.getOrDefault("AttributeValue")
  valid_600998 = validateParameter(valid_600998, JString, required = false,
                                 default = nil)
  if valid_600998 != nil:
    section.add "AttributeValue", valid_600998
  var valid_600999 = formData.getOrDefault("SubscriptionArn")
  valid_600999 = validateParameter(valid_600999, JString, required = true,
                                 default = nil)
  if valid_600999 != nil:
    section.add "SubscriptionArn", valid_600999
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601000: Call_PostSetSubscriptionAttributes_600985; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ## 
  let valid = call_601000.validator(path, query, header, formData, body)
  let scheme = call_601000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601000.url(scheme.get, call_601000.host, call_601000.base,
                         call_601000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601000, url, valid)

proc call*(call_601001: Call_PostSetSubscriptionAttributes_600985;
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
  var query_601002 = newJObject()
  var formData_601003 = newJObject()
  add(formData_601003, "AttributeName", newJString(AttributeName))
  add(formData_601003, "AttributeValue", newJString(AttributeValue))
  add(query_601002, "Action", newJString(Action))
  add(formData_601003, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_601002, "Version", newJString(Version))
  result = call_601001.call(nil, query_601002, nil, formData_601003, nil)

var postSetSubscriptionAttributes* = Call_PostSetSubscriptionAttributes_600985(
    name: "postSetSubscriptionAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetSubscriptionAttributes",
    validator: validate_PostSetSubscriptionAttributes_600986, base: "/",
    url: url_PostSetSubscriptionAttributes_600987,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSubscriptionAttributes_600967 = ref object of OpenApiRestCall_599368
proc url_GetSetSubscriptionAttributes_600969(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetSubscriptionAttributes_600968(path: JsonNode; query: JsonNode;
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
  ##                : <p>A map of attributes with their corresponding values.</p> <p>The following lists the names, descriptions, and values of the special request parameters that the <code>SetTopicAttributes</code> action uses:</p> <ul> <li> <p> <code>DeliveryPolicy</code> – The policy that defines how Amazon SNS retries failed deliveries to HTTP/S endpoints.</p> </li> <li> <p> <code>FilterPolicy</code> – The simple JSON object that lets your subscriber receive only a subset of messages, rather than receiving every message published to the topic.</p> </li> <li> <p> <code>RawMessageDelivery</code> – When set to <code>true</code>, enables raw message delivery to Amazon SQS or HTTP/S endpoints. This eliminates the need for the endpoints to process JSON formatting, which is otherwise created for Amazon SNS metadata.</p> </li> <li> <p> <code>RedrivePolicy</code> – When specified, sends undeliverable messages to the specified Amazon SQS dead-letter queue. Messages that can't be delivered due to client errors (for example, when the subscribed endpoint is unreachable) or server errors (for example, when the service that powers the subscribed endpoint becomes unavailable) are held in the dead-letter queue for further analysis or reprocessing.</p> </li> </ul>
  ##   Action: JString (required)
  ##   AttributeValue: JString
  ##                 : The new value for the attribute in JSON format.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SubscriptionArn` field"
  var valid_600970 = query.getOrDefault("SubscriptionArn")
  valid_600970 = validateParameter(valid_600970, JString, required = true,
                                 default = nil)
  if valid_600970 != nil:
    section.add "SubscriptionArn", valid_600970
  var valid_600971 = query.getOrDefault("AttributeName")
  valid_600971 = validateParameter(valid_600971, JString, required = true,
                                 default = nil)
  if valid_600971 != nil:
    section.add "AttributeName", valid_600971
  var valid_600972 = query.getOrDefault("Action")
  valid_600972 = validateParameter(valid_600972, JString, required = true, default = newJString(
      "SetSubscriptionAttributes"))
  if valid_600972 != nil:
    section.add "Action", valid_600972
  var valid_600973 = query.getOrDefault("AttributeValue")
  valid_600973 = validateParameter(valid_600973, JString, required = false,
                                 default = nil)
  if valid_600973 != nil:
    section.add "AttributeValue", valid_600973
  var valid_600974 = query.getOrDefault("Version")
  valid_600974 = validateParameter(valid_600974, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_600974 != nil:
    section.add "Version", valid_600974
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600975 = header.getOrDefault("X-Amz-Date")
  valid_600975 = validateParameter(valid_600975, JString, required = false,
                                 default = nil)
  if valid_600975 != nil:
    section.add "X-Amz-Date", valid_600975
  var valid_600976 = header.getOrDefault("X-Amz-Security-Token")
  valid_600976 = validateParameter(valid_600976, JString, required = false,
                                 default = nil)
  if valid_600976 != nil:
    section.add "X-Amz-Security-Token", valid_600976
  var valid_600977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600977 = validateParameter(valid_600977, JString, required = false,
                                 default = nil)
  if valid_600977 != nil:
    section.add "X-Amz-Content-Sha256", valid_600977
  var valid_600978 = header.getOrDefault("X-Amz-Algorithm")
  valid_600978 = validateParameter(valid_600978, JString, required = false,
                                 default = nil)
  if valid_600978 != nil:
    section.add "X-Amz-Algorithm", valid_600978
  var valid_600979 = header.getOrDefault("X-Amz-Signature")
  valid_600979 = validateParameter(valid_600979, JString, required = false,
                                 default = nil)
  if valid_600979 != nil:
    section.add "X-Amz-Signature", valid_600979
  var valid_600980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600980 = validateParameter(valid_600980, JString, required = false,
                                 default = nil)
  if valid_600980 != nil:
    section.add "X-Amz-SignedHeaders", valid_600980
  var valid_600981 = header.getOrDefault("X-Amz-Credential")
  valid_600981 = validateParameter(valid_600981, JString, required = false,
                                 default = nil)
  if valid_600981 != nil:
    section.add "X-Amz-Credential", valid_600981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600982: Call_GetSetSubscriptionAttributes_600967; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ## 
  let valid = call_600982.validator(path, query, header, formData, body)
  let scheme = call_600982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600982.url(scheme.get, call_600982.host, call_600982.base,
                         call_600982.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600982, url, valid)

proc call*(call_600983: Call_GetSetSubscriptionAttributes_600967;
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
  var query_600984 = newJObject()
  add(query_600984, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_600984, "AttributeName", newJString(AttributeName))
  add(query_600984, "Action", newJString(Action))
  add(query_600984, "AttributeValue", newJString(AttributeValue))
  add(query_600984, "Version", newJString(Version))
  result = call_600983.call(nil, query_600984, nil, nil, nil)

var getSetSubscriptionAttributes* = Call_GetSetSubscriptionAttributes_600967(
    name: "getSetSubscriptionAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetSubscriptionAttributes",
    validator: validate_GetSetSubscriptionAttributes_600968, base: "/",
    url: url_GetSetSubscriptionAttributes_600969,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetTopicAttributes_601022 = ref object of OpenApiRestCall_599368
proc url_PostSetTopicAttributes_601024(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSetTopicAttributes_601023(path: JsonNode; query: JsonNode;
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
  var valid_601025 = query.getOrDefault("Action")
  valid_601025 = validateParameter(valid_601025, JString, required = true,
                                 default = newJString("SetTopicAttributes"))
  if valid_601025 != nil:
    section.add "Action", valid_601025
  var valid_601026 = query.getOrDefault("Version")
  valid_601026 = validateParameter(valid_601026, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601026 != nil:
    section.add "Version", valid_601026
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601027 = header.getOrDefault("X-Amz-Date")
  valid_601027 = validateParameter(valid_601027, JString, required = false,
                                 default = nil)
  if valid_601027 != nil:
    section.add "X-Amz-Date", valid_601027
  var valid_601028 = header.getOrDefault("X-Amz-Security-Token")
  valid_601028 = validateParameter(valid_601028, JString, required = false,
                                 default = nil)
  if valid_601028 != nil:
    section.add "X-Amz-Security-Token", valid_601028
  var valid_601029 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601029 = validateParameter(valid_601029, JString, required = false,
                                 default = nil)
  if valid_601029 != nil:
    section.add "X-Amz-Content-Sha256", valid_601029
  var valid_601030 = header.getOrDefault("X-Amz-Algorithm")
  valid_601030 = validateParameter(valid_601030, JString, required = false,
                                 default = nil)
  if valid_601030 != nil:
    section.add "X-Amz-Algorithm", valid_601030
  var valid_601031 = header.getOrDefault("X-Amz-Signature")
  valid_601031 = validateParameter(valid_601031, JString, required = false,
                                 default = nil)
  if valid_601031 != nil:
    section.add "X-Amz-Signature", valid_601031
  var valid_601032 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601032 = validateParameter(valid_601032, JString, required = false,
                                 default = nil)
  if valid_601032 != nil:
    section.add "X-Amz-SignedHeaders", valid_601032
  var valid_601033 = header.getOrDefault("X-Amz-Credential")
  valid_601033 = validateParameter(valid_601033, JString, required = false,
                                 default = nil)
  if valid_601033 != nil:
    section.add "X-Amz-Credential", valid_601033
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
  var valid_601034 = formData.getOrDefault("TopicArn")
  valid_601034 = validateParameter(valid_601034, JString, required = true,
                                 default = nil)
  if valid_601034 != nil:
    section.add "TopicArn", valid_601034
  var valid_601035 = formData.getOrDefault("AttributeName")
  valid_601035 = validateParameter(valid_601035, JString, required = true,
                                 default = nil)
  if valid_601035 != nil:
    section.add "AttributeName", valid_601035
  var valid_601036 = formData.getOrDefault("AttributeValue")
  valid_601036 = validateParameter(valid_601036, JString, required = false,
                                 default = nil)
  if valid_601036 != nil:
    section.add "AttributeValue", valid_601036
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601037: Call_PostSetTopicAttributes_601022; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  let valid = call_601037.validator(path, query, header, formData, body)
  let scheme = call_601037.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601037.url(scheme.get, call_601037.host, call_601037.base,
                         call_601037.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601037, url, valid)

proc call*(call_601038: Call_PostSetTopicAttributes_601022; TopicArn: string;
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
  var query_601039 = newJObject()
  var formData_601040 = newJObject()
  add(formData_601040, "TopicArn", newJString(TopicArn))
  add(formData_601040, "AttributeName", newJString(AttributeName))
  add(formData_601040, "AttributeValue", newJString(AttributeValue))
  add(query_601039, "Action", newJString(Action))
  add(query_601039, "Version", newJString(Version))
  result = call_601038.call(nil, query_601039, nil, formData_601040, nil)

var postSetTopicAttributes* = Call_PostSetTopicAttributes_601022(
    name: "postSetTopicAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetTopicAttributes",
    validator: validate_PostSetTopicAttributes_601023, base: "/",
    url: url_PostSetTopicAttributes_601024, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetTopicAttributes_601004 = ref object of OpenApiRestCall_599368
proc url_GetSetTopicAttributes_601006(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSetTopicAttributes_601005(path: JsonNode; query: JsonNode;
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
  var valid_601007 = query.getOrDefault("AttributeName")
  valid_601007 = validateParameter(valid_601007, JString, required = true,
                                 default = nil)
  if valid_601007 != nil:
    section.add "AttributeName", valid_601007
  var valid_601008 = query.getOrDefault("Action")
  valid_601008 = validateParameter(valid_601008, JString, required = true,
                                 default = newJString("SetTopicAttributes"))
  if valid_601008 != nil:
    section.add "Action", valid_601008
  var valid_601009 = query.getOrDefault("AttributeValue")
  valid_601009 = validateParameter(valid_601009, JString, required = false,
                                 default = nil)
  if valid_601009 != nil:
    section.add "AttributeValue", valid_601009
  var valid_601010 = query.getOrDefault("TopicArn")
  valid_601010 = validateParameter(valid_601010, JString, required = true,
                                 default = nil)
  if valid_601010 != nil:
    section.add "TopicArn", valid_601010
  var valid_601011 = query.getOrDefault("Version")
  valid_601011 = validateParameter(valid_601011, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601011 != nil:
    section.add "Version", valid_601011
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601012 = header.getOrDefault("X-Amz-Date")
  valid_601012 = validateParameter(valid_601012, JString, required = false,
                                 default = nil)
  if valid_601012 != nil:
    section.add "X-Amz-Date", valid_601012
  var valid_601013 = header.getOrDefault("X-Amz-Security-Token")
  valid_601013 = validateParameter(valid_601013, JString, required = false,
                                 default = nil)
  if valid_601013 != nil:
    section.add "X-Amz-Security-Token", valid_601013
  var valid_601014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601014 = validateParameter(valid_601014, JString, required = false,
                                 default = nil)
  if valid_601014 != nil:
    section.add "X-Amz-Content-Sha256", valid_601014
  var valid_601015 = header.getOrDefault("X-Amz-Algorithm")
  valid_601015 = validateParameter(valid_601015, JString, required = false,
                                 default = nil)
  if valid_601015 != nil:
    section.add "X-Amz-Algorithm", valid_601015
  var valid_601016 = header.getOrDefault("X-Amz-Signature")
  valid_601016 = validateParameter(valid_601016, JString, required = false,
                                 default = nil)
  if valid_601016 != nil:
    section.add "X-Amz-Signature", valid_601016
  var valid_601017 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601017 = validateParameter(valid_601017, JString, required = false,
                                 default = nil)
  if valid_601017 != nil:
    section.add "X-Amz-SignedHeaders", valid_601017
  var valid_601018 = header.getOrDefault("X-Amz-Credential")
  valid_601018 = validateParameter(valid_601018, JString, required = false,
                                 default = nil)
  if valid_601018 != nil:
    section.add "X-Amz-Credential", valid_601018
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601019: Call_GetSetTopicAttributes_601004; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  let valid = call_601019.validator(path, query, header, formData, body)
  let scheme = call_601019.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601019.url(scheme.get, call_601019.host, call_601019.base,
                         call_601019.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601019, url, valid)

proc call*(call_601020: Call_GetSetTopicAttributes_601004; AttributeName: string;
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
  var query_601021 = newJObject()
  add(query_601021, "AttributeName", newJString(AttributeName))
  add(query_601021, "Action", newJString(Action))
  add(query_601021, "AttributeValue", newJString(AttributeValue))
  add(query_601021, "TopicArn", newJString(TopicArn))
  add(query_601021, "Version", newJString(Version))
  result = call_601020.call(nil, query_601021, nil, nil, nil)

var getSetTopicAttributes* = Call_GetSetTopicAttributes_601004(
    name: "getSetTopicAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetTopicAttributes",
    validator: validate_GetSetTopicAttributes_601005, base: "/",
    url: url_GetSetTopicAttributes_601006, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSubscribe_601066 = ref object of OpenApiRestCall_599368
proc url_PostSubscribe_601068(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSubscribe_601067(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601069 = query.getOrDefault("Action")
  valid_601069 = validateParameter(valid_601069, JString, required = true,
                                 default = newJString("Subscribe"))
  if valid_601069 != nil:
    section.add "Action", valid_601069
  var valid_601070 = query.getOrDefault("Version")
  valid_601070 = validateParameter(valid_601070, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601070 != nil:
    section.add "Version", valid_601070
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601071 = header.getOrDefault("X-Amz-Date")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Date", valid_601071
  var valid_601072 = header.getOrDefault("X-Amz-Security-Token")
  valid_601072 = validateParameter(valid_601072, JString, required = false,
                                 default = nil)
  if valid_601072 != nil:
    section.add "X-Amz-Security-Token", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Content-Sha256", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Algorithm")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Algorithm", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Signature")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Signature", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-SignedHeaders", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Credential")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Credential", valid_601077
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
  var valid_601078 = formData.getOrDefault("Endpoint")
  valid_601078 = validateParameter(valid_601078, JString, required = false,
                                 default = nil)
  if valid_601078 != nil:
    section.add "Endpoint", valid_601078
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_601079 = formData.getOrDefault("TopicArn")
  valid_601079 = validateParameter(valid_601079, JString, required = true,
                                 default = nil)
  if valid_601079 != nil:
    section.add "TopicArn", valid_601079
  var valid_601080 = formData.getOrDefault("Attributes.0.value")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = nil)
  if valid_601080 != nil:
    section.add "Attributes.0.value", valid_601080
  var valid_601081 = formData.getOrDefault("Protocol")
  valid_601081 = validateParameter(valid_601081, JString, required = true,
                                 default = nil)
  if valid_601081 != nil:
    section.add "Protocol", valid_601081
  var valid_601082 = formData.getOrDefault("Attributes.0.key")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "Attributes.0.key", valid_601082
  var valid_601083 = formData.getOrDefault("Attributes.1.key")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "Attributes.1.key", valid_601083
  var valid_601084 = formData.getOrDefault("ReturnSubscriptionArn")
  valid_601084 = validateParameter(valid_601084, JBool, required = false, default = nil)
  if valid_601084 != nil:
    section.add "ReturnSubscriptionArn", valid_601084
  var valid_601085 = formData.getOrDefault("Attributes.2.value")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "Attributes.2.value", valid_601085
  var valid_601086 = formData.getOrDefault("Attributes.2.key")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "Attributes.2.key", valid_601086
  var valid_601087 = formData.getOrDefault("Attributes.1.value")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "Attributes.1.value", valid_601087
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601088: Call_PostSubscribe_601066; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_601088.validator(path, query, header, formData, body)
  let scheme = call_601088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601088.url(scheme.get, call_601088.host, call_601088.base,
                         call_601088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601088, url, valid)

proc call*(call_601089: Call_PostSubscribe_601066; TopicArn: string;
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
  var query_601090 = newJObject()
  var formData_601091 = newJObject()
  add(formData_601091, "Endpoint", newJString(Endpoint))
  add(formData_601091, "TopicArn", newJString(TopicArn))
  add(formData_601091, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_601091, "Protocol", newJString(Protocol))
  add(formData_601091, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_601091, "Attributes.1.key", newJString(Attributes1Key))
  add(formData_601091, "ReturnSubscriptionArn", newJBool(ReturnSubscriptionArn))
  add(query_601090, "Action", newJString(Action))
  add(formData_601091, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_601091, "Attributes.2.key", newJString(Attributes2Key))
  add(query_601090, "Version", newJString(Version))
  add(formData_601091, "Attributes.1.value", newJString(Attributes1Value))
  result = call_601089.call(nil, query_601090, nil, formData_601091, nil)

var postSubscribe* = Call_PostSubscribe_601066(name: "postSubscribe",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=Subscribe", validator: validate_PostSubscribe_601067,
    base: "/", url: url_PostSubscribe_601068, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSubscribe_601041 = ref object of OpenApiRestCall_599368
proc url_GetSubscribe_601043(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSubscribe_601042(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601044 = query.getOrDefault("Attributes.2.key")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "Attributes.2.key", valid_601044
  var valid_601045 = query.getOrDefault("Endpoint")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "Endpoint", valid_601045
  assert query != nil,
        "query argument is necessary due to required `Protocol` field"
  var valid_601046 = query.getOrDefault("Protocol")
  valid_601046 = validateParameter(valid_601046, JString, required = true,
                                 default = nil)
  if valid_601046 != nil:
    section.add "Protocol", valid_601046
  var valid_601047 = query.getOrDefault("Attributes.1.value")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "Attributes.1.value", valid_601047
  var valid_601048 = query.getOrDefault("Attributes.0.value")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "Attributes.0.value", valid_601048
  var valid_601049 = query.getOrDefault("Action")
  valid_601049 = validateParameter(valid_601049, JString, required = true,
                                 default = newJString("Subscribe"))
  if valid_601049 != nil:
    section.add "Action", valid_601049
  var valid_601050 = query.getOrDefault("ReturnSubscriptionArn")
  valid_601050 = validateParameter(valid_601050, JBool, required = false, default = nil)
  if valid_601050 != nil:
    section.add "ReturnSubscriptionArn", valid_601050
  var valid_601051 = query.getOrDefault("Attributes.1.key")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "Attributes.1.key", valid_601051
  var valid_601052 = query.getOrDefault("TopicArn")
  valid_601052 = validateParameter(valid_601052, JString, required = true,
                                 default = nil)
  if valid_601052 != nil:
    section.add "TopicArn", valid_601052
  var valid_601053 = query.getOrDefault("Attributes.2.value")
  valid_601053 = validateParameter(valid_601053, JString, required = false,
                                 default = nil)
  if valid_601053 != nil:
    section.add "Attributes.2.value", valid_601053
  var valid_601054 = query.getOrDefault("Attributes.0.key")
  valid_601054 = validateParameter(valid_601054, JString, required = false,
                                 default = nil)
  if valid_601054 != nil:
    section.add "Attributes.0.key", valid_601054
  var valid_601055 = query.getOrDefault("Version")
  valid_601055 = validateParameter(valid_601055, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601055 != nil:
    section.add "Version", valid_601055
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601056 = header.getOrDefault("X-Amz-Date")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Date", valid_601056
  var valid_601057 = header.getOrDefault("X-Amz-Security-Token")
  valid_601057 = validateParameter(valid_601057, JString, required = false,
                                 default = nil)
  if valid_601057 != nil:
    section.add "X-Amz-Security-Token", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Content-Sha256", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Algorithm")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Algorithm", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Signature")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Signature", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-SignedHeaders", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Credential")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Credential", valid_601062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601063: Call_GetSubscribe_601041; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_601063.validator(path, query, header, formData, body)
  let scheme = call_601063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601063.url(scheme.get, call_601063.host, call_601063.base,
                         call_601063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601063, url, valid)

proc call*(call_601064: Call_GetSubscribe_601041; Protocol: string; TopicArn: string;
          Attributes2Key: string = ""; Endpoint: string = "";
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
  var query_601065 = newJObject()
  add(query_601065, "Attributes.2.key", newJString(Attributes2Key))
  add(query_601065, "Endpoint", newJString(Endpoint))
  add(query_601065, "Protocol", newJString(Protocol))
  add(query_601065, "Attributes.1.value", newJString(Attributes1Value))
  add(query_601065, "Attributes.0.value", newJString(Attributes0Value))
  add(query_601065, "Action", newJString(Action))
  add(query_601065, "ReturnSubscriptionArn", newJBool(ReturnSubscriptionArn))
  add(query_601065, "Attributes.1.key", newJString(Attributes1Key))
  add(query_601065, "TopicArn", newJString(TopicArn))
  add(query_601065, "Attributes.2.value", newJString(Attributes2Value))
  add(query_601065, "Attributes.0.key", newJString(Attributes0Key))
  add(query_601065, "Version", newJString(Version))
  result = call_601064.call(nil, query_601065, nil, nil, nil)

var getSubscribe* = Call_GetSubscribe_601041(name: "getSubscribe",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=Subscribe", validator: validate_GetSubscribe_601042, base: "/",
    url: url_GetSubscribe_601043, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTagResource_601109 = ref object of OpenApiRestCall_599368
proc url_PostTagResource_601111(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostTagResource_601110(path: JsonNode; query: JsonNode;
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
  var valid_601112 = query.getOrDefault("Action")
  valid_601112 = validateParameter(valid_601112, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_601112 != nil:
    section.add "Action", valid_601112
  var valid_601113 = query.getOrDefault("Version")
  valid_601113 = validateParameter(valid_601113, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601113 != nil:
    section.add "Version", valid_601113
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601114 = header.getOrDefault("X-Amz-Date")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "X-Amz-Date", valid_601114
  var valid_601115 = header.getOrDefault("X-Amz-Security-Token")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Security-Token", valid_601115
  var valid_601116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-Content-Sha256", valid_601116
  var valid_601117 = header.getOrDefault("X-Amz-Algorithm")
  valid_601117 = validateParameter(valid_601117, JString, required = false,
                                 default = nil)
  if valid_601117 != nil:
    section.add "X-Amz-Algorithm", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-Signature")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Signature", valid_601118
  var valid_601119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-SignedHeaders", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-Credential")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Credential", valid_601120
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##       : The tags to be added to the specified topic. A tag consists of a required key and an optional value.
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic to which to add tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_601121 = formData.getOrDefault("Tags")
  valid_601121 = validateParameter(valid_601121, JArray, required = true, default = nil)
  if valid_601121 != nil:
    section.add "Tags", valid_601121
  var valid_601122 = formData.getOrDefault("ResourceArn")
  valid_601122 = validateParameter(valid_601122, JString, required = true,
                                 default = nil)
  if valid_601122 != nil:
    section.add "ResourceArn", valid_601122
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601123: Call_PostTagResource_601109; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account, per AWS region. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul>
  ## 
  let valid = call_601123.validator(path, query, header, formData, body)
  let scheme = call_601123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601123.url(scheme.get, call_601123.host, call_601123.base,
                         call_601123.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601123, url, valid)

proc call*(call_601124: Call_PostTagResource_601109; Tags: JsonNode;
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
  var query_601125 = newJObject()
  var formData_601126 = newJObject()
  if Tags != nil:
    formData_601126.add "Tags", Tags
  add(query_601125, "Action", newJString(Action))
  add(formData_601126, "ResourceArn", newJString(ResourceArn))
  add(query_601125, "Version", newJString(Version))
  result = call_601124.call(nil, query_601125, nil, formData_601126, nil)

var postTagResource* = Call_PostTagResource_601109(name: "postTagResource",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_PostTagResource_601110,
    base: "/", url: url_PostTagResource_601111, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagResource_601092 = ref object of OpenApiRestCall_599368
proc url_GetTagResource_601094(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTagResource_601093(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_601095 = query.getOrDefault("ResourceArn")
  valid_601095 = validateParameter(valid_601095, JString, required = true,
                                 default = nil)
  if valid_601095 != nil:
    section.add "ResourceArn", valid_601095
  var valid_601096 = query.getOrDefault("Tags")
  valid_601096 = validateParameter(valid_601096, JArray, required = true, default = nil)
  if valid_601096 != nil:
    section.add "Tags", valid_601096
  var valid_601097 = query.getOrDefault("Action")
  valid_601097 = validateParameter(valid_601097, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_601097 != nil:
    section.add "Action", valid_601097
  var valid_601098 = query.getOrDefault("Version")
  valid_601098 = validateParameter(valid_601098, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601098 != nil:
    section.add "Version", valid_601098
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601099 = header.getOrDefault("X-Amz-Date")
  valid_601099 = validateParameter(valid_601099, JString, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "X-Amz-Date", valid_601099
  var valid_601100 = header.getOrDefault("X-Amz-Security-Token")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Security-Token", valid_601100
  var valid_601101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "X-Amz-Content-Sha256", valid_601101
  var valid_601102 = header.getOrDefault("X-Amz-Algorithm")
  valid_601102 = validateParameter(valid_601102, JString, required = false,
                                 default = nil)
  if valid_601102 != nil:
    section.add "X-Amz-Algorithm", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Signature")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Signature", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-SignedHeaders", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Credential")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Credential", valid_601105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601106: Call_GetTagResource_601092; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account, per AWS region. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul>
  ## 
  let valid = call_601106.validator(path, query, header, formData, body)
  let scheme = call_601106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601106.url(scheme.get, call_601106.host, call_601106.base,
                         call_601106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601106, url, valid)

proc call*(call_601107: Call_GetTagResource_601092; ResourceArn: string;
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
  var query_601108 = newJObject()
  add(query_601108, "ResourceArn", newJString(ResourceArn))
  if Tags != nil:
    query_601108.add "Tags", Tags
  add(query_601108, "Action", newJString(Action))
  add(query_601108, "Version", newJString(Version))
  result = call_601107.call(nil, query_601108, nil, nil, nil)

var getTagResource* = Call_GetTagResource_601092(name: "getTagResource",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_GetTagResource_601093,
    base: "/", url: url_GetTagResource_601094, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUnsubscribe_601143 = ref object of OpenApiRestCall_599368
proc url_PostUnsubscribe_601145(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUnsubscribe_601144(path: JsonNode; query: JsonNode;
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
  var valid_601146 = query.getOrDefault("Action")
  valid_601146 = validateParameter(valid_601146, JString, required = true,
                                 default = newJString("Unsubscribe"))
  if valid_601146 != nil:
    section.add "Action", valid_601146
  var valid_601147 = query.getOrDefault("Version")
  valid_601147 = validateParameter(valid_601147, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601147 != nil:
    section.add "Version", valid_601147
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601148 = header.getOrDefault("X-Amz-Date")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Date", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-Security-Token")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-Security-Token", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Content-Sha256", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-Algorithm")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-Algorithm", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Signature")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Signature", valid_601152
  var valid_601153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "X-Amz-SignedHeaders", valid_601153
  var valid_601154 = header.getOrDefault("X-Amz-Credential")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "X-Amz-Credential", valid_601154
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription to be deleted.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionArn` field"
  var valid_601155 = formData.getOrDefault("SubscriptionArn")
  valid_601155 = validateParameter(valid_601155, JString, required = true,
                                 default = nil)
  if valid_601155 != nil:
    section.add "SubscriptionArn", valid_601155
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601156: Call_PostUnsubscribe_601143; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_601156.validator(path, query, header, formData, body)
  let scheme = call_601156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601156.url(scheme.get, call_601156.host, call_601156.base,
                         call_601156.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601156, url, valid)

proc call*(call_601157: Call_PostUnsubscribe_601143; SubscriptionArn: string;
          Action: string = "Unsubscribe"; Version: string = "2010-03-31"): Recallable =
  ## postUnsubscribe
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   Action: string (required)
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to be deleted.
  ##   Version: string (required)
  var query_601158 = newJObject()
  var formData_601159 = newJObject()
  add(query_601158, "Action", newJString(Action))
  add(formData_601159, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_601158, "Version", newJString(Version))
  result = call_601157.call(nil, query_601158, nil, formData_601159, nil)

var postUnsubscribe* = Call_PostUnsubscribe_601143(name: "postUnsubscribe",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=Unsubscribe", validator: validate_PostUnsubscribe_601144,
    base: "/", url: url_PostUnsubscribe_601145, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUnsubscribe_601127 = ref object of OpenApiRestCall_599368
proc url_GetUnsubscribe_601129(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUnsubscribe_601128(path: JsonNode; query: JsonNode;
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
  var valid_601130 = query.getOrDefault("SubscriptionArn")
  valid_601130 = validateParameter(valid_601130, JString, required = true,
                                 default = nil)
  if valid_601130 != nil:
    section.add "SubscriptionArn", valid_601130
  var valid_601131 = query.getOrDefault("Action")
  valid_601131 = validateParameter(valid_601131, JString, required = true,
                                 default = newJString("Unsubscribe"))
  if valid_601131 != nil:
    section.add "Action", valid_601131
  var valid_601132 = query.getOrDefault("Version")
  valid_601132 = validateParameter(valid_601132, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601132 != nil:
    section.add "Version", valid_601132
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601133 = header.getOrDefault("X-Amz-Date")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Date", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-Security-Token")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-Security-Token", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Content-Sha256", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-Algorithm")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-Algorithm", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Signature")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Signature", valid_601137
  var valid_601138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601138 = validateParameter(valid_601138, JString, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "X-Amz-SignedHeaders", valid_601138
  var valid_601139 = header.getOrDefault("X-Amz-Credential")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "X-Amz-Credential", valid_601139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601140: Call_GetUnsubscribe_601127; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_601140.validator(path, query, header, formData, body)
  let scheme = call_601140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601140.url(scheme.get, call_601140.host, call_601140.base,
                         call_601140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601140, url, valid)

proc call*(call_601141: Call_GetUnsubscribe_601127; SubscriptionArn: string;
          Action: string = "Unsubscribe"; Version: string = "2010-03-31"): Recallable =
  ## getUnsubscribe
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to be deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601142 = newJObject()
  add(query_601142, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_601142, "Action", newJString(Action))
  add(query_601142, "Version", newJString(Version))
  result = call_601141.call(nil, query_601142, nil, nil, nil)

var getUnsubscribe* = Call_GetUnsubscribe_601127(name: "getUnsubscribe",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=Unsubscribe", validator: validate_GetUnsubscribe_601128,
    base: "/", url: url_GetUnsubscribe_601129, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUntagResource_601177 = ref object of OpenApiRestCall_599368
proc url_PostUntagResource_601179(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUntagResource_601178(path: JsonNode; query: JsonNode;
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
  var valid_601180 = query.getOrDefault("Action")
  valid_601180 = validateParameter(valid_601180, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_601180 != nil:
    section.add "Action", valid_601180
  var valid_601181 = query.getOrDefault("Version")
  valid_601181 = validateParameter(valid_601181, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601181 != nil:
    section.add "Version", valid_601181
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601182 = header.getOrDefault("X-Amz-Date")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Date", valid_601182
  var valid_601183 = header.getOrDefault("X-Amz-Security-Token")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-Security-Token", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-Content-Sha256", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-Algorithm")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-Algorithm", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Signature")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Signature", valid_601186
  var valid_601187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-SignedHeaders", valid_601187
  var valid_601188 = header.getOrDefault("X-Amz-Credential")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-Credential", valid_601188
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the specified topic.
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic from which to remove tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_601189 = formData.getOrDefault("TagKeys")
  valid_601189 = validateParameter(valid_601189, JArray, required = true, default = nil)
  if valid_601189 != nil:
    section.add "TagKeys", valid_601189
  var valid_601190 = formData.getOrDefault("ResourceArn")
  valid_601190 = validateParameter(valid_601190, JString, required = true,
                                 default = nil)
  if valid_601190 != nil:
    section.add "ResourceArn", valid_601190
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601191: Call_PostUntagResource_601177; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  let valid = call_601191.validator(path, query, header, formData, body)
  let scheme = call_601191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601191.url(scheme.get, call_601191.host, call_601191.base,
                         call_601191.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601191, url, valid)

proc call*(call_601192: Call_PostUntagResource_601177; TagKeys: JsonNode;
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
  var query_601193 = newJObject()
  var formData_601194 = newJObject()
  add(query_601193, "Action", newJString(Action))
  if TagKeys != nil:
    formData_601194.add "TagKeys", TagKeys
  add(formData_601194, "ResourceArn", newJString(ResourceArn))
  add(query_601193, "Version", newJString(Version))
  result = call_601192.call(nil, query_601193, nil, formData_601194, nil)

var postUntagResource* = Call_PostUntagResource_601177(name: "postUntagResource",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_PostUntagResource_601178,
    base: "/", url: url_PostUntagResource_601179,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUntagResource_601160 = ref object of OpenApiRestCall_599368
proc url_GetUntagResource_601162(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUntagResource_601161(path: JsonNode; query: JsonNode;
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
  var valid_601163 = query.getOrDefault("ResourceArn")
  valid_601163 = validateParameter(valid_601163, JString, required = true,
                                 default = nil)
  if valid_601163 != nil:
    section.add "ResourceArn", valid_601163
  var valid_601164 = query.getOrDefault("Action")
  valid_601164 = validateParameter(valid_601164, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_601164 != nil:
    section.add "Action", valid_601164
  var valid_601165 = query.getOrDefault("TagKeys")
  valid_601165 = validateParameter(valid_601165, JArray, required = true, default = nil)
  if valid_601165 != nil:
    section.add "TagKeys", valid_601165
  var valid_601166 = query.getOrDefault("Version")
  valid_601166 = validateParameter(valid_601166, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601166 != nil:
    section.add "Version", valid_601166
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601167 = header.getOrDefault("X-Amz-Date")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Date", valid_601167
  var valid_601168 = header.getOrDefault("X-Amz-Security-Token")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-Security-Token", valid_601168
  var valid_601169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-Content-Sha256", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-Algorithm")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-Algorithm", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-Signature")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-Signature", valid_601171
  var valid_601172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "X-Amz-SignedHeaders", valid_601172
  var valid_601173 = header.getOrDefault("X-Amz-Credential")
  valid_601173 = validateParameter(valid_601173, JString, required = false,
                                 default = nil)
  if valid_601173 != nil:
    section.add "X-Amz-Credential", valid_601173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601174: Call_GetUntagResource_601160; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  let valid = call_601174.validator(path, query, header, formData, body)
  let scheme = call_601174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601174.url(scheme.get, call_601174.host, call_601174.base,
                         call_601174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601174, url, valid)

proc call*(call_601175: Call_GetUntagResource_601160; ResourceArn: string;
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
  var query_601176 = newJObject()
  add(query_601176, "ResourceArn", newJString(ResourceArn))
  add(query_601176, "Action", newJString(Action))
  if TagKeys != nil:
    query_601176.add "TagKeys", TagKeys
  add(query_601176, "Version", newJString(Version))
  result = call_601175.call(nil, query_601176, nil, nil, nil)

var getUntagResource* = Call_GetUntagResource_601160(name: "getUntagResource",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_GetUntagResource_601161,
    base: "/", url: url_GetUntagResource_601162,
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
