
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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
  Call_PostAddPermission_602001 = ref object of OpenApiRestCall_601389
proc url_PostAddPermission_602003(protocol: Scheme; host: string; base: string;
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

proc validate_PostAddPermission_602002(path: JsonNode; query: JsonNode;
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
  var valid_602004 = query.getOrDefault("Action")
  valid_602004 = validateParameter(valid_602004, JString, required = true,
                                 default = newJString("AddPermission"))
  if valid_602004 != nil:
    section.add "Action", valid_602004
  var valid_602005 = query.getOrDefault("Version")
  valid_602005 = validateParameter(valid_602005, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602005 != nil:
    section.add "Version", valid_602005
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602006 = header.getOrDefault("X-Amz-Signature")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Signature", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Content-Sha256", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-Date")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-Date", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-Credential")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-Credential", valid_602009
  var valid_602010 = header.getOrDefault("X-Amz-Security-Token")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "X-Amz-Security-Token", valid_602010
  var valid_602011 = header.getOrDefault("X-Amz-Algorithm")
  valid_602011 = validateParameter(valid_602011, JString, required = false,
                                 default = nil)
  if valid_602011 != nil:
    section.add "X-Amz-Algorithm", valid_602011
  var valid_602012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602012 = validateParameter(valid_602012, JString, required = false,
                                 default = nil)
  if valid_602012 != nil:
    section.add "X-Amz-SignedHeaders", valid_602012
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
  var valid_602013 = formData.getOrDefault("TopicArn")
  valid_602013 = validateParameter(valid_602013, JString, required = true,
                                 default = nil)
  if valid_602013 != nil:
    section.add "TopicArn", valid_602013
  var valid_602014 = formData.getOrDefault("AWSAccountId")
  valid_602014 = validateParameter(valid_602014, JArray, required = true, default = nil)
  if valid_602014 != nil:
    section.add "AWSAccountId", valid_602014
  var valid_602015 = formData.getOrDefault("Label")
  valid_602015 = validateParameter(valid_602015, JString, required = true,
                                 default = nil)
  if valid_602015 != nil:
    section.add "Label", valid_602015
  var valid_602016 = formData.getOrDefault("ActionName")
  valid_602016 = validateParameter(valid_602016, JArray, required = true, default = nil)
  if valid_602016 != nil:
    section.add "ActionName", valid_602016
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602017: Call_PostAddPermission_602001; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  let valid = call_602017.validator(path, query, header, formData, body)
  let scheme = call_602017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602017.url(scheme.get, call_602017.host, call_602017.base,
                         call_602017.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602017, url, valid)

proc call*(call_602018: Call_PostAddPermission_602001; TopicArn: string;
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
  var query_602019 = newJObject()
  var formData_602020 = newJObject()
  add(formData_602020, "TopicArn", newJString(TopicArn))
  add(query_602019, "Action", newJString(Action))
  if AWSAccountId != nil:
    formData_602020.add "AWSAccountId", AWSAccountId
  add(formData_602020, "Label", newJString(Label))
  if ActionName != nil:
    formData_602020.add "ActionName", ActionName
  add(query_602019, "Version", newJString(Version))
  result = call_602018.call(nil, query_602019, nil, formData_602020, nil)

var postAddPermission* = Call_PostAddPermission_602001(name: "postAddPermission",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=AddPermission", validator: validate_PostAddPermission_602002,
    base: "/", url: url_PostAddPermission_602003,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddPermission_601727 = ref object of OpenApiRestCall_601389
proc url_GetAddPermission_601729(protocol: Scheme; host: string; base: string;
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

proc validate_GetAddPermission_601728(path: JsonNode; query: JsonNode;
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
  var valid_601841 = query.getOrDefault("TopicArn")
  valid_601841 = validateParameter(valid_601841, JString, required = true,
                                 default = nil)
  if valid_601841 != nil:
    section.add "TopicArn", valid_601841
  var valid_601855 = query.getOrDefault("Action")
  valid_601855 = validateParameter(valid_601855, JString, required = true,
                                 default = newJString("AddPermission"))
  if valid_601855 != nil:
    section.add "Action", valid_601855
  var valid_601856 = query.getOrDefault("ActionName")
  valid_601856 = validateParameter(valid_601856, JArray, required = true, default = nil)
  if valid_601856 != nil:
    section.add "ActionName", valid_601856
  var valid_601857 = query.getOrDefault("Version")
  valid_601857 = validateParameter(valid_601857, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_601857 != nil:
    section.add "Version", valid_601857
  var valid_601858 = query.getOrDefault("AWSAccountId")
  valid_601858 = validateParameter(valid_601858, JArray, required = true, default = nil)
  if valid_601858 != nil:
    section.add "AWSAccountId", valid_601858
  var valid_601859 = query.getOrDefault("Label")
  valid_601859 = validateParameter(valid_601859, JString, required = true,
                                 default = nil)
  if valid_601859 != nil:
    section.add "Label", valid_601859
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_601860 = header.getOrDefault("X-Amz-Signature")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Signature", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Content-Sha256", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-Date")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-Date", valid_601862
  var valid_601863 = header.getOrDefault("X-Amz-Credential")
  valid_601863 = validateParameter(valid_601863, JString, required = false,
                                 default = nil)
  if valid_601863 != nil:
    section.add "X-Amz-Credential", valid_601863
  var valid_601864 = header.getOrDefault("X-Amz-Security-Token")
  valid_601864 = validateParameter(valid_601864, JString, required = false,
                                 default = nil)
  if valid_601864 != nil:
    section.add "X-Amz-Security-Token", valid_601864
  var valid_601865 = header.getOrDefault("X-Amz-Algorithm")
  valid_601865 = validateParameter(valid_601865, JString, required = false,
                                 default = nil)
  if valid_601865 != nil:
    section.add "X-Amz-Algorithm", valid_601865
  var valid_601866 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601866 = validateParameter(valid_601866, JString, required = false,
                                 default = nil)
  if valid_601866 != nil:
    section.add "X-Amz-SignedHeaders", valid_601866
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601889: Call_GetAddPermission_601727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a statement to a topic's access control policy, granting access for the specified AWS accounts to the specified actions.
  ## 
  let valid = call_601889.validator(path, query, header, formData, body)
  let scheme = call_601889.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601889.url(scheme.get, call_601889.host, call_601889.base,
                         call_601889.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601889, url, valid)

proc call*(call_601960: Call_GetAddPermission_601727; TopicArn: string;
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
  var query_601961 = newJObject()
  add(query_601961, "TopicArn", newJString(TopicArn))
  add(query_601961, "Action", newJString(Action))
  if ActionName != nil:
    query_601961.add "ActionName", ActionName
  add(query_601961, "Version", newJString(Version))
  if AWSAccountId != nil:
    query_601961.add "AWSAccountId", AWSAccountId
  add(query_601961, "Label", newJString(Label))
  result = call_601960.call(nil, query_601961, nil, nil, nil)

var getAddPermission* = Call_GetAddPermission_601727(name: "getAddPermission",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=AddPermission", validator: validate_GetAddPermission_601728,
    base: "/", url: url_GetAddPermission_601729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCheckIfPhoneNumberIsOptedOut_602037 = ref object of OpenApiRestCall_601389
proc url_PostCheckIfPhoneNumberIsOptedOut_602039(protocol: Scheme; host: string;
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

proc validate_PostCheckIfPhoneNumberIsOptedOut_602038(path: JsonNode;
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
  var valid_602040 = query.getOrDefault("Action")
  valid_602040 = validateParameter(valid_602040, JString, required = true, default = newJString(
      "CheckIfPhoneNumberIsOptedOut"))
  if valid_602040 != nil:
    section.add "Action", valid_602040
  var valid_602041 = query.getOrDefault("Version")
  valid_602041 = validateParameter(valid_602041, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602041 != nil:
    section.add "Version", valid_602041
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602042 = header.getOrDefault("X-Amz-Signature")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "X-Amz-Signature", valid_602042
  var valid_602043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "X-Amz-Content-Sha256", valid_602043
  var valid_602044 = header.getOrDefault("X-Amz-Date")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "X-Amz-Date", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-Credential")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Credential", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Security-Token")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Security-Token", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Algorithm")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Algorithm", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-SignedHeaders", valid_602048
  result.add "header", section
  ## parameters in `formData` object:
  ##   phoneNumber: JString (required)
  ##              : The phone number for which you want to check the opt out status.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `phoneNumber` field"
  var valid_602049 = formData.getOrDefault("phoneNumber")
  valid_602049 = validateParameter(valid_602049, JString, required = true,
                                 default = nil)
  if valid_602049 != nil:
    section.add "phoneNumber", valid_602049
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602050: Call_PostCheckIfPhoneNumberIsOptedOut_602037;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ## 
  let valid = call_602050.validator(path, query, header, formData, body)
  let scheme = call_602050.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602050.url(scheme.get, call_602050.host, call_602050.base,
                         call_602050.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602050, url, valid)

proc call*(call_602051: Call_PostCheckIfPhoneNumberIsOptedOut_602037;
          phoneNumber: string; Action: string = "CheckIfPhoneNumberIsOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## postCheckIfPhoneNumberIsOptedOut
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number for which you want to check the opt out status.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602052 = newJObject()
  var formData_602053 = newJObject()
  add(formData_602053, "phoneNumber", newJString(phoneNumber))
  add(query_602052, "Action", newJString(Action))
  add(query_602052, "Version", newJString(Version))
  result = call_602051.call(nil, query_602052, nil, formData_602053, nil)

var postCheckIfPhoneNumberIsOptedOut* = Call_PostCheckIfPhoneNumberIsOptedOut_602037(
    name: "postCheckIfPhoneNumberIsOptedOut", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CheckIfPhoneNumberIsOptedOut",
    validator: validate_PostCheckIfPhoneNumberIsOptedOut_602038, base: "/",
    url: url_PostCheckIfPhoneNumberIsOptedOut_602039,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCheckIfPhoneNumberIsOptedOut_602021 = ref object of OpenApiRestCall_601389
proc url_GetCheckIfPhoneNumberIsOptedOut_602023(protocol: Scheme; host: string;
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

proc validate_GetCheckIfPhoneNumberIsOptedOut_602022(path: JsonNode;
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
  var valid_602024 = query.getOrDefault("phoneNumber")
  valid_602024 = validateParameter(valid_602024, JString, required = true,
                                 default = nil)
  if valid_602024 != nil:
    section.add "phoneNumber", valid_602024
  var valid_602025 = query.getOrDefault("Action")
  valid_602025 = validateParameter(valid_602025, JString, required = true, default = newJString(
      "CheckIfPhoneNumberIsOptedOut"))
  if valid_602025 != nil:
    section.add "Action", valid_602025
  var valid_602026 = query.getOrDefault("Version")
  valid_602026 = validateParameter(valid_602026, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602026 != nil:
    section.add "Version", valid_602026
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602027 = header.getOrDefault("X-Amz-Signature")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-Signature", valid_602027
  var valid_602028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-Content-Sha256", valid_602028
  var valid_602029 = header.getOrDefault("X-Amz-Date")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "X-Amz-Date", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-Credential")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Credential", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-Security-Token")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Security-Token", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Algorithm")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Algorithm", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-SignedHeaders", valid_602033
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602034: Call_GetCheckIfPhoneNumberIsOptedOut_602021;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ## 
  let valid = call_602034.validator(path, query, header, formData, body)
  let scheme = call_602034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602034.url(scheme.get, call_602034.host, call_602034.base,
                         call_602034.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602034, url, valid)

proc call*(call_602035: Call_GetCheckIfPhoneNumberIsOptedOut_602021;
          phoneNumber: string; Action: string = "CheckIfPhoneNumberIsOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## getCheckIfPhoneNumberIsOptedOut
  ## <p>Accepts a phone number and indicates whether the phone holder has opted out of receiving SMS messages from your account. You cannot send SMS messages to a number that is opted out.</p> <p>To resume sending messages, you can opt in the number by using the <code>OptInPhoneNumber</code> action.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number for which you want to check the opt out status.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602036 = newJObject()
  add(query_602036, "phoneNumber", newJString(phoneNumber))
  add(query_602036, "Action", newJString(Action))
  add(query_602036, "Version", newJString(Version))
  result = call_602035.call(nil, query_602036, nil, nil, nil)

var getCheckIfPhoneNumberIsOptedOut* = Call_GetCheckIfPhoneNumberIsOptedOut_602021(
    name: "getCheckIfPhoneNumberIsOptedOut", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CheckIfPhoneNumberIsOptedOut",
    validator: validate_GetCheckIfPhoneNumberIsOptedOut_602022, base: "/",
    url: url_GetCheckIfPhoneNumberIsOptedOut_602023,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostConfirmSubscription_602072 = ref object of OpenApiRestCall_601389
proc url_PostConfirmSubscription_602074(protocol: Scheme; host: string; base: string;
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

proc validate_PostConfirmSubscription_602073(path: JsonNode; query: JsonNode;
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
  var valid_602075 = query.getOrDefault("Action")
  valid_602075 = validateParameter(valid_602075, JString, required = true,
                                 default = newJString("ConfirmSubscription"))
  if valid_602075 != nil:
    section.add "Action", valid_602075
  var valid_602076 = query.getOrDefault("Version")
  valid_602076 = validateParameter(valid_602076, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602076 != nil:
    section.add "Version", valid_602076
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602077 = header.getOrDefault("X-Amz-Signature")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Signature", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Content-Sha256", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Date")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Date", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-Credential")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-Credential", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-Security-Token")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-Security-Token", valid_602081
  var valid_602082 = header.getOrDefault("X-Amz-Algorithm")
  valid_602082 = validateParameter(valid_602082, JString, required = false,
                                 default = nil)
  if valid_602082 != nil:
    section.add "X-Amz-Algorithm", valid_602082
  var valid_602083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602083 = validateParameter(valid_602083, JString, required = false,
                                 default = nil)
  if valid_602083 != nil:
    section.add "X-Amz-SignedHeaders", valid_602083
  result.add "header", section
  ## parameters in `formData` object:
  ##   AuthenticateOnUnsubscribe: JString
  ##                            : Disallows unauthenticated unsubscribes of the subscription. If the value of this parameter is <code>true</code> and the request has an AWS signature, then only the topic owner and the subscription owner can unsubscribe the endpoint. The unsubscribe action requires AWS authentication. 
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic for which you wish to confirm a subscription.
  ##   Token: JString (required)
  ##        : Short-lived token sent to an endpoint during the <code>Subscribe</code> action.
  section = newJObject()
  var valid_602084 = formData.getOrDefault("AuthenticateOnUnsubscribe")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "AuthenticateOnUnsubscribe", valid_602084
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_602085 = formData.getOrDefault("TopicArn")
  valid_602085 = validateParameter(valid_602085, JString, required = true,
                                 default = nil)
  if valid_602085 != nil:
    section.add "TopicArn", valid_602085
  var valid_602086 = formData.getOrDefault("Token")
  valid_602086 = validateParameter(valid_602086, JString, required = true,
                                 default = nil)
  if valid_602086 != nil:
    section.add "Token", valid_602086
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602087: Call_PostConfirmSubscription_602072; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  let valid = call_602087.validator(path, query, header, formData, body)
  let scheme = call_602087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602087.url(scheme.get, call_602087.host, call_602087.base,
                         call_602087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602087, url, valid)

proc call*(call_602088: Call_PostConfirmSubscription_602072; TopicArn: string;
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
  var query_602089 = newJObject()
  var formData_602090 = newJObject()
  add(formData_602090, "AuthenticateOnUnsubscribe",
      newJString(AuthenticateOnUnsubscribe))
  add(formData_602090, "TopicArn", newJString(TopicArn))
  add(formData_602090, "Token", newJString(Token))
  add(query_602089, "Action", newJString(Action))
  add(query_602089, "Version", newJString(Version))
  result = call_602088.call(nil, query_602089, nil, formData_602090, nil)

var postConfirmSubscription* = Call_PostConfirmSubscription_602072(
    name: "postConfirmSubscription", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ConfirmSubscription",
    validator: validate_PostConfirmSubscription_602073, base: "/",
    url: url_PostConfirmSubscription_602074, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfirmSubscription_602054 = ref object of OpenApiRestCall_601389
proc url_GetConfirmSubscription_602056(protocol: Scheme; host: string; base: string;
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

proc validate_GetConfirmSubscription_602055(path: JsonNode; query: JsonNode;
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
  var valid_602057 = query.getOrDefault("AuthenticateOnUnsubscribe")
  valid_602057 = validateParameter(valid_602057, JString, required = false,
                                 default = nil)
  if valid_602057 != nil:
    section.add "AuthenticateOnUnsubscribe", valid_602057
  assert query != nil, "query argument is necessary due to required `Token` field"
  var valid_602058 = query.getOrDefault("Token")
  valid_602058 = validateParameter(valid_602058, JString, required = true,
                                 default = nil)
  if valid_602058 != nil:
    section.add "Token", valid_602058
  var valid_602059 = query.getOrDefault("Action")
  valid_602059 = validateParameter(valid_602059, JString, required = true,
                                 default = newJString("ConfirmSubscription"))
  if valid_602059 != nil:
    section.add "Action", valid_602059
  var valid_602060 = query.getOrDefault("Version")
  valid_602060 = validateParameter(valid_602060, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602060 != nil:
    section.add "Version", valid_602060
  var valid_602061 = query.getOrDefault("TopicArn")
  valid_602061 = validateParameter(valid_602061, JString, required = true,
                                 default = nil)
  if valid_602061 != nil:
    section.add "TopicArn", valid_602061
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602062 = header.getOrDefault("X-Amz-Signature")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Signature", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Content-Sha256", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Date")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Date", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-Credential")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Credential", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-Security-Token")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-Security-Token", valid_602066
  var valid_602067 = header.getOrDefault("X-Amz-Algorithm")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "X-Amz-Algorithm", valid_602067
  var valid_602068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "X-Amz-SignedHeaders", valid_602068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602069: Call_GetConfirmSubscription_602054; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Verifies an endpoint owner's intent to receive messages by validating the token sent to the endpoint by an earlier <code>Subscribe</code> action. If the token is valid, the action creates a new subscription and returns its Amazon Resource Name (ARN). This call requires an AWS signature only when the <code>AuthenticateOnUnsubscribe</code> flag is set to "true".
  ## 
  let valid = call_602069.validator(path, query, header, formData, body)
  let scheme = call_602069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602069.url(scheme.get, call_602069.host, call_602069.base,
                         call_602069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602069, url, valid)

proc call*(call_602070: Call_GetConfirmSubscription_602054; Token: string;
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
  var query_602071 = newJObject()
  add(query_602071, "AuthenticateOnUnsubscribe",
      newJString(AuthenticateOnUnsubscribe))
  add(query_602071, "Token", newJString(Token))
  add(query_602071, "Action", newJString(Action))
  add(query_602071, "Version", newJString(Version))
  add(query_602071, "TopicArn", newJString(TopicArn))
  result = call_602070.call(nil, query_602071, nil, nil, nil)

var getConfirmSubscription* = Call_GetConfirmSubscription_602054(
    name: "getConfirmSubscription", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ConfirmSubscription",
    validator: validate_GetConfirmSubscription_602055, base: "/",
    url: url_GetConfirmSubscription_602056, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformApplication_602114 = ref object of OpenApiRestCall_601389
proc url_PostCreatePlatformApplication_602116(protocol: Scheme; host: string;
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

proc validate_PostCreatePlatformApplication_602115(path: JsonNode; query: JsonNode;
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
  var valid_602117 = query.getOrDefault("Action")
  valid_602117 = validateParameter(valid_602117, JString, required = true, default = newJString(
      "CreatePlatformApplication"))
  if valid_602117 != nil:
    section.add "Action", valid_602117
  var valid_602118 = query.getOrDefault("Version")
  valid_602118 = validateParameter(valid_602118, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602118 != nil:
    section.add "Version", valid_602118
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602119 = header.getOrDefault("X-Amz-Signature")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "X-Amz-Signature", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-Content-Sha256", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-Date")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Date", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Credential")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Credential", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Security-Token")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Security-Token", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Algorithm")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Algorithm", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-SignedHeaders", valid_602125
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
  var valid_602126 = formData.getOrDefault("Attributes.0.key")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "Attributes.0.key", valid_602126
  assert formData != nil,
        "formData argument is necessary due to required `Platform` field"
  var valid_602127 = formData.getOrDefault("Platform")
  valid_602127 = validateParameter(valid_602127, JString, required = true,
                                 default = nil)
  if valid_602127 != nil:
    section.add "Platform", valid_602127
  var valid_602128 = formData.getOrDefault("Attributes.2.value")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "Attributes.2.value", valid_602128
  var valid_602129 = formData.getOrDefault("Attributes.2.key")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "Attributes.2.key", valid_602129
  var valid_602130 = formData.getOrDefault("Attributes.0.value")
  valid_602130 = validateParameter(valid_602130, JString, required = false,
                                 default = nil)
  if valid_602130 != nil:
    section.add "Attributes.0.value", valid_602130
  var valid_602131 = formData.getOrDefault("Attributes.1.key")
  valid_602131 = validateParameter(valid_602131, JString, required = false,
                                 default = nil)
  if valid_602131 != nil:
    section.add "Attributes.1.key", valid_602131
  var valid_602132 = formData.getOrDefault("Name")
  valid_602132 = validateParameter(valid_602132, JString, required = true,
                                 default = nil)
  if valid_602132 != nil:
    section.add "Name", valid_602132
  var valid_602133 = formData.getOrDefault("Attributes.1.value")
  valid_602133 = validateParameter(valid_602133, JString, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "Attributes.1.value", valid_602133
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602134: Call_PostCreatePlatformApplication_602114; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For FCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For FCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action.</p>
  ## 
  let valid = call_602134.validator(path, query, header, formData, body)
  let scheme = call_602134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602134.url(scheme.get, call_602134.host, call_602134.base,
                         call_602134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602134, url, valid)

proc call*(call_602135: Call_PostCreatePlatformApplication_602114;
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
  var query_602136 = newJObject()
  var formData_602137 = newJObject()
  add(formData_602137, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_602137, "Platform", newJString(Platform))
  add(formData_602137, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_602137, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_602137, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_602137, "Attributes.1.key", newJString(Attributes1Key))
  add(query_602136, "Action", newJString(Action))
  add(formData_602137, "Name", newJString(Name))
  add(query_602136, "Version", newJString(Version))
  add(formData_602137, "Attributes.1.value", newJString(Attributes1Value))
  result = call_602135.call(nil, query_602136, nil, formData_602137, nil)

var postCreatePlatformApplication* = Call_PostCreatePlatformApplication_602114(
    name: "postCreatePlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformApplication",
    validator: validate_PostCreatePlatformApplication_602115, base: "/",
    url: url_PostCreatePlatformApplication_602116,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformApplication_602091 = ref object of OpenApiRestCall_601389
proc url_GetCreatePlatformApplication_602093(protocol: Scheme; host: string;
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

proc validate_GetCreatePlatformApplication_602092(path: JsonNode; query: JsonNode;
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
  var valid_602094 = query.getOrDefault("Attributes.1.key")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "Attributes.1.key", valid_602094
  var valid_602095 = query.getOrDefault("Attributes.0.value")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "Attributes.0.value", valid_602095
  var valid_602096 = query.getOrDefault("Attributes.0.key")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "Attributes.0.key", valid_602096
  assert query != nil,
        "query argument is necessary due to required `Platform` field"
  var valid_602097 = query.getOrDefault("Platform")
  valid_602097 = validateParameter(valid_602097, JString, required = true,
                                 default = nil)
  if valid_602097 != nil:
    section.add "Platform", valid_602097
  var valid_602098 = query.getOrDefault("Attributes.2.value")
  valid_602098 = validateParameter(valid_602098, JString, required = false,
                                 default = nil)
  if valid_602098 != nil:
    section.add "Attributes.2.value", valid_602098
  var valid_602099 = query.getOrDefault("Attributes.1.value")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "Attributes.1.value", valid_602099
  var valid_602100 = query.getOrDefault("Name")
  valid_602100 = validateParameter(valid_602100, JString, required = true,
                                 default = nil)
  if valid_602100 != nil:
    section.add "Name", valid_602100
  var valid_602101 = query.getOrDefault("Action")
  valid_602101 = validateParameter(valid_602101, JString, required = true, default = newJString(
      "CreatePlatformApplication"))
  if valid_602101 != nil:
    section.add "Action", valid_602101
  var valid_602102 = query.getOrDefault("Version")
  valid_602102 = validateParameter(valid_602102, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602102 != nil:
    section.add "Version", valid_602102
  var valid_602103 = query.getOrDefault("Attributes.2.key")
  valid_602103 = validateParameter(valid_602103, JString, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "Attributes.2.key", valid_602103
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602104 = header.getOrDefault("X-Amz-Signature")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "X-Amz-Signature", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Content-Sha256", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Date")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Date", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-Credential")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Credential", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-Security-Token")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Security-Token", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Algorithm")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Algorithm", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-SignedHeaders", valid_602110
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602111: Call_GetCreatePlatformApplication_602091; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a platform application object for one of the supported push notification services, such as APNS and FCM, to which devices and mobile apps may register. You must specify PlatformPrincipal and PlatformCredential attributes when using the <code>CreatePlatformApplication</code> action. The PlatformPrincipal is received from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal is "SSL certificate". For FCM, PlatformPrincipal is not applicable. For ADM, PlatformPrincipal is "client id". The PlatformCredential is also received from the notification service. For WNS, PlatformPrincipal is "Package Security Identifier". For MPNS, PlatformPrincipal is "TLS certificate". For Baidu, PlatformPrincipal is "API key".</p> <p>For APNS/APNS_SANDBOX, PlatformCredential is "private key". For FCM, PlatformCredential is "API key". For ADM, PlatformCredential is "client secret". For WNS, PlatformCredential is "secret key". For MPNS, PlatformCredential is "private key". For Baidu, PlatformCredential is "secret key". The PlatformApplicationArn that is returned when using <code>CreatePlatformApplication</code> is then used as an attribute for the <code>CreatePlatformEndpoint</code> action.</p>
  ## 
  let valid = call_602111.validator(path, query, header, formData, body)
  let scheme = call_602111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602111.url(scheme.get, call_602111.host, call_602111.base,
                         call_602111.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602111, url, valid)

proc call*(call_602112: Call_GetCreatePlatformApplication_602091; Platform: string;
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
  var query_602113 = newJObject()
  add(query_602113, "Attributes.1.key", newJString(Attributes1Key))
  add(query_602113, "Attributes.0.value", newJString(Attributes0Value))
  add(query_602113, "Attributes.0.key", newJString(Attributes0Key))
  add(query_602113, "Platform", newJString(Platform))
  add(query_602113, "Attributes.2.value", newJString(Attributes2Value))
  add(query_602113, "Attributes.1.value", newJString(Attributes1Value))
  add(query_602113, "Name", newJString(Name))
  add(query_602113, "Action", newJString(Action))
  add(query_602113, "Version", newJString(Version))
  add(query_602113, "Attributes.2.key", newJString(Attributes2Key))
  result = call_602112.call(nil, query_602113, nil, nil, nil)

var getCreatePlatformApplication* = Call_GetCreatePlatformApplication_602091(
    name: "getCreatePlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformApplication",
    validator: validate_GetCreatePlatformApplication_602092, base: "/",
    url: url_GetCreatePlatformApplication_602093,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformEndpoint_602162 = ref object of OpenApiRestCall_601389
proc url_PostCreatePlatformEndpoint_602164(protocol: Scheme; host: string;
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

proc validate_PostCreatePlatformEndpoint_602163(path: JsonNode; query: JsonNode;
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
  var valid_602165 = query.getOrDefault("Action")
  valid_602165 = validateParameter(valid_602165, JString, required = true,
                                 default = newJString("CreatePlatformEndpoint"))
  if valid_602165 != nil:
    section.add "Action", valid_602165
  var valid_602166 = query.getOrDefault("Version")
  valid_602166 = validateParameter(valid_602166, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602166 != nil:
    section.add "Version", valid_602166
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602167 = header.getOrDefault("X-Amz-Signature")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-Signature", valid_602167
  var valid_602168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-Content-Sha256", valid_602168
  var valid_602169 = header.getOrDefault("X-Amz-Date")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "X-Amz-Date", valid_602169
  var valid_602170 = header.getOrDefault("X-Amz-Credential")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "X-Amz-Credential", valid_602170
  var valid_602171 = header.getOrDefault("X-Amz-Security-Token")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "X-Amz-Security-Token", valid_602171
  var valid_602172 = header.getOrDefault("X-Amz-Algorithm")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "X-Amz-Algorithm", valid_602172
  var valid_602173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602173 = validateParameter(valid_602173, JString, required = false,
                                 default = nil)
  if valid_602173 != nil:
    section.add "X-Amz-SignedHeaders", valid_602173
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
  var valid_602174 = formData.getOrDefault("PlatformApplicationArn")
  valid_602174 = validateParameter(valid_602174, JString, required = true,
                                 default = nil)
  if valid_602174 != nil:
    section.add "PlatformApplicationArn", valid_602174
  var valid_602175 = formData.getOrDefault("CustomUserData")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "CustomUserData", valid_602175
  var valid_602176 = formData.getOrDefault("Attributes.0.key")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "Attributes.0.key", valid_602176
  var valid_602177 = formData.getOrDefault("Attributes.2.value")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "Attributes.2.value", valid_602177
  var valid_602178 = formData.getOrDefault("Attributes.2.key")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "Attributes.2.key", valid_602178
  var valid_602179 = formData.getOrDefault("Attributes.0.value")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "Attributes.0.value", valid_602179
  var valid_602180 = formData.getOrDefault("Attributes.1.key")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "Attributes.1.key", valid_602180
  var valid_602181 = formData.getOrDefault("Token")
  valid_602181 = validateParameter(valid_602181, JString, required = true,
                                 default = nil)
  if valid_602181 != nil:
    section.add "Token", valid_602181
  var valid_602182 = formData.getOrDefault("Attributes.1.value")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "Attributes.1.value", valid_602182
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602183: Call_PostCreatePlatformEndpoint_602162; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as FCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  let valid = call_602183.validator(path, query, header, formData, body)
  let scheme = call_602183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602183.url(scheme.get, call_602183.host, call_602183.base,
                         call_602183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602183, url, valid)

proc call*(call_602184: Call_PostCreatePlatformEndpoint_602162;
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
  var query_602185 = newJObject()
  var formData_602186 = newJObject()
  add(formData_602186, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(formData_602186, "CustomUserData", newJString(CustomUserData))
  add(formData_602186, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_602186, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_602186, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_602186, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_602186, "Attributes.1.key", newJString(Attributes1Key))
  add(formData_602186, "Token", newJString(Token))
  add(query_602185, "Action", newJString(Action))
  add(query_602185, "Version", newJString(Version))
  add(formData_602186, "Attributes.1.value", newJString(Attributes1Value))
  result = call_602184.call(nil, query_602185, nil, formData_602186, nil)

var postCreatePlatformEndpoint* = Call_PostCreatePlatformEndpoint_602162(
    name: "postCreatePlatformEndpoint", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformEndpoint",
    validator: validate_PostCreatePlatformEndpoint_602163, base: "/",
    url: url_PostCreatePlatformEndpoint_602164,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformEndpoint_602138 = ref object of OpenApiRestCall_601389
proc url_GetCreatePlatformEndpoint_602140(protocol: Scheme; host: string;
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

proc validate_GetCreatePlatformEndpoint_602139(path: JsonNode; query: JsonNode;
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
  var valid_602141 = query.getOrDefault("Attributes.1.key")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "Attributes.1.key", valid_602141
  var valid_602142 = query.getOrDefault("CustomUserData")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "CustomUserData", valid_602142
  var valid_602143 = query.getOrDefault("Attributes.0.value")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "Attributes.0.value", valid_602143
  var valid_602144 = query.getOrDefault("Attributes.0.key")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "Attributes.0.key", valid_602144
  var valid_602145 = query.getOrDefault("Attributes.2.value")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "Attributes.2.value", valid_602145
  assert query != nil, "query argument is necessary due to required `Token` field"
  var valid_602146 = query.getOrDefault("Token")
  valid_602146 = validateParameter(valid_602146, JString, required = true,
                                 default = nil)
  if valid_602146 != nil:
    section.add "Token", valid_602146
  var valid_602147 = query.getOrDefault("Attributes.1.value")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "Attributes.1.value", valid_602147
  var valid_602148 = query.getOrDefault("PlatformApplicationArn")
  valid_602148 = validateParameter(valid_602148, JString, required = true,
                                 default = nil)
  if valid_602148 != nil:
    section.add "PlatformApplicationArn", valid_602148
  var valid_602149 = query.getOrDefault("Action")
  valid_602149 = validateParameter(valid_602149, JString, required = true,
                                 default = newJString("CreatePlatformEndpoint"))
  if valid_602149 != nil:
    section.add "Action", valid_602149
  var valid_602150 = query.getOrDefault("Version")
  valid_602150 = validateParameter(valid_602150, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602150 != nil:
    section.add "Version", valid_602150
  var valid_602151 = query.getOrDefault("Attributes.2.key")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "Attributes.2.key", valid_602151
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602152 = header.getOrDefault("X-Amz-Signature")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-Signature", valid_602152
  var valid_602153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-Content-Sha256", valid_602153
  var valid_602154 = header.getOrDefault("X-Amz-Date")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-Date", valid_602154
  var valid_602155 = header.getOrDefault("X-Amz-Credential")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Credential", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-Security-Token")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-Security-Token", valid_602156
  var valid_602157 = header.getOrDefault("X-Amz-Algorithm")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-Algorithm", valid_602157
  var valid_602158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "X-Amz-SignedHeaders", valid_602158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602159: Call_GetCreatePlatformEndpoint_602138; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an endpoint for a device and mobile app on one of the supported push notification services, such as FCM and APNS. <code>CreatePlatformEndpoint</code> requires the PlatformApplicationArn that is returned from <code>CreatePlatformApplication</code>. The EndpointArn that is returned when using <code>CreatePlatformEndpoint</code> can then be used by the <code>Publish</code> action to send a message to a mobile app or by the <code>Subscribe</code> action for subscription to a topic. The <code>CreatePlatformEndpoint</code> action is idempotent, so if the requester already owns an endpoint with the same device token and attributes, that endpoint's ARN is returned without creating a new endpoint. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When using <code>CreatePlatformEndpoint</code> with Baidu, two attributes must be provided: ChannelId and UserId. The token field must also contain the ChannelId. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePushBaiduEndpoint.html">Creating an Amazon SNS Endpoint for Baidu</a>. </p>
  ## 
  let valid = call_602159.validator(path, query, header, formData, body)
  let scheme = call_602159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602159.url(scheme.get, call_602159.host, call_602159.base,
                         call_602159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602159, url, valid)

proc call*(call_602160: Call_GetCreatePlatformEndpoint_602138; Token: string;
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
  var query_602161 = newJObject()
  add(query_602161, "Attributes.1.key", newJString(Attributes1Key))
  add(query_602161, "CustomUserData", newJString(CustomUserData))
  add(query_602161, "Attributes.0.value", newJString(Attributes0Value))
  add(query_602161, "Attributes.0.key", newJString(Attributes0Key))
  add(query_602161, "Attributes.2.value", newJString(Attributes2Value))
  add(query_602161, "Token", newJString(Token))
  add(query_602161, "Attributes.1.value", newJString(Attributes1Value))
  add(query_602161, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  add(query_602161, "Action", newJString(Action))
  add(query_602161, "Version", newJString(Version))
  add(query_602161, "Attributes.2.key", newJString(Attributes2Key))
  result = call_602160.call(nil, query_602161, nil, nil, nil)

var getCreatePlatformEndpoint* = Call_GetCreatePlatformEndpoint_602138(
    name: "getCreatePlatformEndpoint", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=CreatePlatformEndpoint",
    validator: validate_GetCreatePlatformEndpoint_602139, base: "/",
    url: url_GetCreatePlatformEndpoint_602140,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateTopic_602210 = ref object of OpenApiRestCall_601389
proc url_PostCreateTopic_602212(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateTopic_602211(path: JsonNode; query: JsonNode;
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
  var valid_602213 = query.getOrDefault("Action")
  valid_602213 = validateParameter(valid_602213, JString, required = true,
                                 default = newJString("CreateTopic"))
  if valid_602213 != nil:
    section.add "Action", valid_602213
  var valid_602214 = query.getOrDefault("Version")
  valid_602214 = validateParameter(valid_602214, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602214 != nil:
    section.add "Version", valid_602214
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602215 = header.getOrDefault("X-Amz-Signature")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "X-Amz-Signature", valid_602215
  var valid_602216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "X-Amz-Content-Sha256", valid_602216
  var valid_602217 = header.getOrDefault("X-Amz-Date")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "X-Amz-Date", valid_602217
  var valid_602218 = header.getOrDefault("X-Amz-Credential")
  valid_602218 = validateParameter(valid_602218, JString, required = false,
                                 default = nil)
  if valid_602218 != nil:
    section.add "X-Amz-Credential", valid_602218
  var valid_602219 = header.getOrDefault("X-Amz-Security-Token")
  valid_602219 = validateParameter(valid_602219, JString, required = false,
                                 default = nil)
  if valid_602219 != nil:
    section.add "X-Amz-Security-Token", valid_602219
  var valid_602220 = header.getOrDefault("X-Amz-Algorithm")
  valid_602220 = validateParameter(valid_602220, JString, required = false,
                                 default = nil)
  if valid_602220 != nil:
    section.add "X-Amz-Algorithm", valid_602220
  var valid_602221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602221 = validateParameter(valid_602221, JString, required = false,
                                 default = nil)
  if valid_602221 != nil:
    section.add "X-Amz-SignedHeaders", valid_602221
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
  var valid_602222 = formData.getOrDefault("Attributes.0.key")
  valid_602222 = validateParameter(valid_602222, JString, required = false,
                                 default = nil)
  if valid_602222 != nil:
    section.add "Attributes.0.key", valid_602222
  var valid_602223 = formData.getOrDefault("Attributes.2.value")
  valid_602223 = validateParameter(valid_602223, JString, required = false,
                                 default = nil)
  if valid_602223 != nil:
    section.add "Attributes.2.value", valid_602223
  var valid_602224 = formData.getOrDefault("Attributes.2.key")
  valid_602224 = validateParameter(valid_602224, JString, required = false,
                                 default = nil)
  if valid_602224 != nil:
    section.add "Attributes.2.key", valid_602224
  var valid_602225 = formData.getOrDefault("Attributes.0.value")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "Attributes.0.value", valid_602225
  var valid_602226 = formData.getOrDefault("Attributes.1.key")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "Attributes.1.key", valid_602226
  assert formData != nil,
        "formData argument is necessary due to required `Name` field"
  var valid_602227 = formData.getOrDefault("Name")
  valid_602227 = validateParameter(valid_602227, JString, required = true,
                                 default = nil)
  if valid_602227 != nil:
    section.add "Name", valid_602227
  var valid_602228 = formData.getOrDefault("Tags")
  valid_602228 = validateParameter(valid_602228, JArray, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "Tags", valid_602228
  var valid_602229 = formData.getOrDefault("Attributes.1.value")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "Attributes.1.value", valid_602229
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602230: Call_PostCreateTopic_602210; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  let valid = call_602230.validator(path, query, header, formData, body)
  let scheme = call_602230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602230.url(scheme.get, call_602230.host, call_602230.base,
                         call_602230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602230, url, valid)

proc call*(call_602231: Call_PostCreateTopic_602210; Name: string;
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
  var query_602232 = newJObject()
  var formData_602233 = newJObject()
  add(formData_602233, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_602233, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_602233, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_602233, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_602233, "Attributes.1.key", newJString(Attributes1Key))
  add(query_602232, "Action", newJString(Action))
  add(formData_602233, "Name", newJString(Name))
  if Tags != nil:
    formData_602233.add "Tags", Tags
  add(query_602232, "Version", newJString(Version))
  add(formData_602233, "Attributes.1.value", newJString(Attributes1Value))
  result = call_602231.call(nil, query_602232, nil, formData_602233, nil)

var postCreateTopic* = Call_PostCreateTopic_602210(name: "postCreateTopic",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=CreateTopic", validator: validate_PostCreateTopic_602211,
    base: "/", url: url_PostCreateTopic_602212, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateTopic_602187 = ref object of OpenApiRestCall_601389
proc url_GetCreateTopic_602189(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateTopic_602188(path: JsonNode; query: JsonNode;
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
  var valid_602190 = query.getOrDefault("Attributes.1.key")
  valid_602190 = validateParameter(valid_602190, JString, required = false,
                                 default = nil)
  if valid_602190 != nil:
    section.add "Attributes.1.key", valid_602190
  var valid_602191 = query.getOrDefault("Attributes.0.value")
  valid_602191 = validateParameter(valid_602191, JString, required = false,
                                 default = nil)
  if valid_602191 != nil:
    section.add "Attributes.0.value", valid_602191
  var valid_602192 = query.getOrDefault("Attributes.0.key")
  valid_602192 = validateParameter(valid_602192, JString, required = false,
                                 default = nil)
  if valid_602192 != nil:
    section.add "Attributes.0.key", valid_602192
  var valid_602193 = query.getOrDefault("Tags")
  valid_602193 = validateParameter(valid_602193, JArray, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "Tags", valid_602193
  var valid_602194 = query.getOrDefault("Attributes.2.value")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "Attributes.2.value", valid_602194
  var valid_602195 = query.getOrDefault("Attributes.1.value")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "Attributes.1.value", valid_602195
  assert query != nil, "query argument is necessary due to required `Name` field"
  var valid_602196 = query.getOrDefault("Name")
  valid_602196 = validateParameter(valid_602196, JString, required = true,
                                 default = nil)
  if valid_602196 != nil:
    section.add "Name", valid_602196
  var valid_602197 = query.getOrDefault("Action")
  valid_602197 = validateParameter(valid_602197, JString, required = true,
                                 default = newJString("CreateTopic"))
  if valid_602197 != nil:
    section.add "Action", valid_602197
  var valid_602198 = query.getOrDefault("Version")
  valid_602198 = validateParameter(valid_602198, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602198 != nil:
    section.add "Version", valid_602198
  var valid_602199 = query.getOrDefault("Attributes.2.key")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "Attributes.2.key", valid_602199
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602200 = header.getOrDefault("X-Amz-Signature")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-Signature", valid_602200
  var valid_602201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "X-Amz-Content-Sha256", valid_602201
  var valid_602202 = header.getOrDefault("X-Amz-Date")
  valid_602202 = validateParameter(valid_602202, JString, required = false,
                                 default = nil)
  if valid_602202 != nil:
    section.add "X-Amz-Date", valid_602202
  var valid_602203 = header.getOrDefault("X-Amz-Credential")
  valid_602203 = validateParameter(valid_602203, JString, required = false,
                                 default = nil)
  if valid_602203 != nil:
    section.add "X-Amz-Credential", valid_602203
  var valid_602204 = header.getOrDefault("X-Amz-Security-Token")
  valid_602204 = validateParameter(valid_602204, JString, required = false,
                                 default = nil)
  if valid_602204 != nil:
    section.add "X-Amz-Security-Token", valid_602204
  var valid_602205 = header.getOrDefault("X-Amz-Algorithm")
  valid_602205 = validateParameter(valid_602205, JString, required = false,
                                 default = nil)
  if valid_602205 != nil:
    section.add "X-Amz-Algorithm", valid_602205
  var valid_602206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602206 = validateParameter(valid_602206, JString, required = false,
                                 default = nil)
  if valid_602206 != nil:
    section.add "X-Amz-SignedHeaders", valid_602206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602207: Call_GetCreateTopic_602187; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a topic to which notifications can be published. Users can create at most 100,000 topics. For more information, see <a href="http://aws.amazon.com/sns/">https://aws.amazon.com/sns</a>. This action is idempotent, so if the requester already owns a topic with the specified name, that topic's ARN is returned without creating a new topic.
  ## 
  let valid = call_602207.validator(path, query, header, formData, body)
  let scheme = call_602207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602207.url(scheme.get, call_602207.host, call_602207.base,
                         call_602207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602207, url, valid)

proc call*(call_602208: Call_GetCreateTopic_602187; Name: string;
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
  var query_602209 = newJObject()
  add(query_602209, "Attributes.1.key", newJString(Attributes1Key))
  add(query_602209, "Attributes.0.value", newJString(Attributes0Value))
  add(query_602209, "Attributes.0.key", newJString(Attributes0Key))
  if Tags != nil:
    query_602209.add "Tags", Tags
  add(query_602209, "Attributes.2.value", newJString(Attributes2Value))
  add(query_602209, "Attributes.1.value", newJString(Attributes1Value))
  add(query_602209, "Name", newJString(Name))
  add(query_602209, "Action", newJString(Action))
  add(query_602209, "Version", newJString(Version))
  add(query_602209, "Attributes.2.key", newJString(Attributes2Key))
  result = call_602208.call(nil, query_602209, nil, nil, nil)

var getCreateTopic* = Call_GetCreateTopic_602187(name: "getCreateTopic",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=CreateTopic", validator: validate_GetCreateTopic_602188,
    base: "/", url: url_GetCreateTopic_602189, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEndpoint_602250 = ref object of OpenApiRestCall_601389
proc url_PostDeleteEndpoint_602252(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteEndpoint_602251(path: JsonNode; query: JsonNode;
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
  var valid_602253 = query.getOrDefault("Action")
  valid_602253 = validateParameter(valid_602253, JString, required = true,
                                 default = newJString("DeleteEndpoint"))
  if valid_602253 != nil:
    section.add "Action", valid_602253
  var valid_602254 = query.getOrDefault("Version")
  valid_602254 = validateParameter(valid_602254, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602254 != nil:
    section.add "Version", valid_602254
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602255 = header.getOrDefault("X-Amz-Signature")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "X-Amz-Signature", valid_602255
  var valid_602256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "X-Amz-Content-Sha256", valid_602256
  var valid_602257 = header.getOrDefault("X-Amz-Date")
  valid_602257 = validateParameter(valid_602257, JString, required = false,
                                 default = nil)
  if valid_602257 != nil:
    section.add "X-Amz-Date", valid_602257
  var valid_602258 = header.getOrDefault("X-Amz-Credential")
  valid_602258 = validateParameter(valid_602258, JString, required = false,
                                 default = nil)
  if valid_602258 != nil:
    section.add "X-Amz-Credential", valid_602258
  var valid_602259 = header.getOrDefault("X-Amz-Security-Token")
  valid_602259 = validateParameter(valid_602259, JString, required = false,
                                 default = nil)
  if valid_602259 != nil:
    section.add "X-Amz-Security-Token", valid_602259
  var valid_602260 = header.getOrDefault("X-Amz-Algorithm")
  valid_602260 = validateParameter(valid_602260, JString, required = false,
                                 default = nil)
  if valid_602260 != nil:
    section.add "X-Amz-Algorithm", valid_602260
  var valid_602261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602261 = validateParameter(valid_602261, JString, required = false,
                                 default = nil)
  if valid_602261 != nil:
    section.add "X-Amz-SignedHeaders", valid_602261
  result.add "header", section
  ## parameters in `formData` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn of endpoint to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_602262 = formData.getOrDefault("EndpointArn")
  valid_602262 = validateParameter(valid_602262, JString, required = true,
                                 default = nil)
  if valid_602262 != nil:
    section.add "EndpointArn", valid_602262
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602263: Call_PostDeleteEndpoint_602250; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ## 
  let valid = call_602263.validator(path, query, header, formData, body)
  let scheme = call_602263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602263.url(scheme.get, call_602263.host, call_602263.base,
                         call_602263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602263, url, valid)

proc call*(call_602264: Call_PostDeleteEndpoint_602250; EndpointArn: string;
          Action: string = "DeleteEndpoint"; Version: string = "2010-03-31"): Recallable =
  ## postDeleteEndpoint
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ##   EndpointArn: string (required)
  ##              : EndpointArn of endpoint to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602265 = newJObject()
  var formData_602266 = newJObject()
  add(formData_602266, "EndpointArn", newJString(EndpointArn))
  add(query_602265, "Action", newJString(Action))
  add(query_602265, "Version", newJString(Version))
  result = call_602264.call(nil, query_602265, nil, formData_602266, nil)

var postDeleteEndpoint* = Call_PostDeleteEndpoint_602250(
    name: "postDeleteEndpoint", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=DeleteEndpoint",
    validator: validate_PostDeleteEndpoint_602251, base: "/",
    url: url_PostDeleteEndpoint_602252, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEndpoint_602234 = ref object of OpenApiRestCall_601389
proc url_GetDeleteEndpoint_602236(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteEndpoint_602235(path: JsonNode; query: JsonNode;
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
  var valid_602237 = query.getOrDefault("Action")
  valid_602237 = validateParameter(valid_602237, JString, required = true,
                                 default = newJString("DeleteEndpoint"))
  if valid_602237 != nil:
    section.add "Action", valid_602237
  var valid_602238 = query.getOrDefault("EndpointArn")
  valid_602238 = validateParameter(valid_602238, JString, required = true,
                                 default = nil)
  if valid_602238 != nil:
    section.add "EndpointArn", valid_602238
  var valid_602239 = query.getOrDefault("Version")
  valid_602239 = validateParameter(valid_602239, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602239 != nil:
    section.add "Version", valid_602239
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602240 = header.getOrDefault("X-Amz-Signature")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "X-Amz-Signature", valid_602240
  var valid_602241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "X-Amz-Content-Sha256", valid_602241
  var valid_602242 = header.getOrDefault("X-Amz-Date")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "X-Amz-Date", valid_602242
  var valid_602243 = header.getOrDefault("X-Amz-Credential")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "X-Amz-Credential", valid_602243
  var valid_602244 = header.getOrDefault("X-Amz-Security-Token")
  valid_602244 = validateParameter(valid_602244, JString, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "X-Amz-Security-Token", valid_602244
  var valid_602245 = header.getOrDefault("X-Amz-Algorithm")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-Algorithm", valid_602245
  var valid_602246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-SignedHeaders", valid_602246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602247: Call_GetDeleteEndpoint_602234; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ## 
  let valid = call_602247.validator(path, query, header, formData, body)
  let scheme = call_602247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602247.url(scheme.get, call_602247.host, call_602247.base,
                         call_602247.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602247, url, valid)

proc call*(call_602248: Call_GetDeleteEndpoint_602234; EndpointArn: string;
          Action: string = "DeleteEndpoint"; Version: string = "2010-03-31"): Recallable =
  ## getDeleteEndpoint
  ## <p>Deletes the endpoint for a device and mobile app from Amazon SNS. This action is idempotent. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>When you delete an endpoint that is also subscribed to a topic, then you must also unsubscribe the endpoint from the topic.</p>
  ##   Action: string (required)
  ##   EndpointArn: string (required)
  ##              : EndpointArn of endpoint to delete.
  ##   Version: string (required)
  var query_602249 = newJObject()
  add(query_602249, "Action", newJString(Action))
  add(query_602249, "EndpointArn", newJString(EndpointArn))
  add(query_602249, "Version", newJString(Version))
  result = call_602248.call(nil, query_602249, nil, nil, nil)

var getDeleteEndpoint* = Call_GetDeleteEndpoint_602234(name: "getDeleteEndpoint",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=DeleteEndpoint", validator: validate_GetDeleteEndpoint_602235,
    base: "/", url: url_GetDeleteEndpoint_602236,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeletePlatformApplication_602283 = ref object of OpenApiRestCall_601389
proc url_PostDeletePlatformApplication_602285(protocol: Scheme; host: string;
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

proc validate_PostDeletePlatformApplication_602284(path: JsonNode; query: JsonNode;
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
  var valid_602286 = query.getOrDefault("Action")
  valid_602286 = validateParameter(valid_602286, JString, required = true, default = newJString(
      "DeletePlatformApplication"))
  if valid_602286 != nil:
    section.add "Action", valid_602286
  var valid_602287 = query.getOrDefault("Version")
  valid_602287 = validateParameter(valid_602287, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602287 != nil:
    section.add "Version", valid_602287
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602288 = header.getOrDefault("X-Amz-Signature")
  valid_602288 = validateParameter(valid_602288, JString, required = false,
                                 default = nil)
  if valid_602288 != nil:
    section.add "X-Amz-Signature", valid_602288
  var valid_602289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "X-Amz-Content-Sha256", valid_602289
  var valid_602290 = header.getOrDefault("X-Amz-Date")
  valid_602290 = validateParameter(valid_602290, JString, required = false,
                                 default = nil)
  if valid_602290 != nil:
    section.add "X-Amz-Date", valid_602290
  var valid_602291 = header.getOrDefault("X-Amz-Credential")
  valid_602291 = validateParameter(valid_602291, JString, required = false,
                                 default = nil)
  if valid_602291 != nil:
    section.add "X-Amz-Credential", valid_602291
  var valid_602292 = header.getOrDefault("X-Amz-Security-Token")
  valid_602292 = validateParameter(valid_602292, JString, required = false,
                                 default = nil)
  if valid_602292 != nil:
    section.add "X-Amz-Security-Token", valid_602292
  var valid_602293 = header.getOrDefault("X-Amz-Algorithm")
  valid_602293 = validateParameter(valid_602293, JString, required = false,
                                 default = nil)
  if valid_602293 != nil:
    section.add "X-Amz-Algorithm", valid_602293
  var valid_602294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602294 = validateParameter(valid_602294, JString, required = false,
                                 default = nil)
  if valid_602294 != nil:
    section.add "X-Amz-SignedHeaders", valid_602294
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_602295 = formData.getOrDefault("PlatformApplicationArn")
  valid_602295 = validateParameter(valid_602295, JString, required = true,
                                 default = nil)
  if valid_602295 != nil:
    section.add "PlatformApplicationArn", valid_602295
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602296: Call_PostDeletePlatformApplication_602283; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_602296.validator(path, query, header, formData, body)
  let scheme = call_602296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602296.url(scheme.get, call_602296.host, call_602296.base,
                         call_602296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602296, url, valid)

proc call*(call_602297: Call_PostDeletePlatformApplication_602283;
          PlatformApplicationArn: string;
          Action: string = "DeletePlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## postDeletePlatformApplication
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602298 = newJObject()
  var formData_602299 = newJObject()
  add(formData_602299, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(query_602298, "Action", newJString(Action))
  add(query_602298, "Version", newJString(Version))
  result = call_602297.call(nil, query_602298, nil, formData_602299, nil)

var postDeletePlatformApplication* = Call_PostDeletePlatformApplication_602283(
    name: "postDeletePlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=DeletePlatformApplication",
    validator: validate_PostDeletePlatformApplication_602284, base: "/",
    url: url_PostDeletePlatformApplication_602285,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeletePlatformApplication_602267 = ref object of OpenApiRestCall_601389
proc url_GetDeletePlatformApplication_602269(protocol: Scheme; host: string;
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

proc validate_GetDeletePlatformApplication_602268(path: JsonNode; query: JsonNode;
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
  var valid_602270 = query.getOrDefault("PlatformApplicationArn")
  valid_602270 = validateParameter(valid_602270, JString, required = true,
                                 default = nil)
  if valid_602270 != nil:
    section.add "PlatformApplicationArn", valid_602270
  var valid_602271 = query.getOrDefault("Action")
  valid_602271 = validateParameter(valid_602271, JString, required = true, default = newJString(
      "DeletePlatformApplication"))
  if valid_602271 != nil:
    section.add "Action", valid_602271
  var valid_602272 = query.getOrDefault("Version")
  valid_602272 = validateParameter(valid_602272, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602272 != nil:
    section.add "Version", valid_602272
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602273 = header.getOrDefault("X-Amz-Signature")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "X-Amz-Signature", valid_602273
  var valid_602274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = nil)
  if valid_602274 != nil:
    section.add "X-Amz-Content-Sha256", valid_602274
  var valid_602275 = header.getOrDefault("X-Amz-Date")
  valid_602275 = validateParameter(valid_602275, JString, required = false,
                                 default = nil)
  if valid_602275 != nil:
    section.add "X-Amz-Date", valid_602275
  var valid_602276 = header.getOrDefault("X-Amz-Credential")
  valid_602276 = validateParameter(valid_602276, JString, required = false,
                                 default = nil)
  if valid_602276 != nil:
    section.add "X-Amz-Credential", valid_602276
  var valid_602277 = header.getOrDefault("X-Amz-Security-Token")
  valid_602277 = validateParameter(valid_602277, JString, required = false,
                                 default = nil)
  if valid_602277 != nil:
    section.add "X-Amz-Security-Token", valid_602277
  var valid_602278 = header.getOrDefault("X-Amz-Algorithm")
  valid_602278 = validateParameter(valid_602278, JString, required = false,
                                 default = nil)
  if valid_602278 != nil:
    section.add "X-Amz-Algorithm", valid_602278
  var valid_602279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602279 = validateParameter(valid_602279, JString, required = false,
                                 default = nil)
  if valid_602279 != nil:
    section.add "X-Amz-SignedHeaders", valid_602279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602280: Call_GetDeletePlatformApplication_602267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_602280.validator(path, query, header, formData, body)
  let scheme = call_602280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602280.url(scheme.get, call_602280.host, call_602280.base,
                         call_602280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602280, url, valid)

proc call*(call_602281: Call_GetDeletePlatformApplication_602267;
          PlatformApplicationArn: string;
          Action: string = "DeletePlatformApplication";
          Version: string = "2010-03-31"): Recallable =
  ## getDeletePlatformApplication
  ## Deletes a platform application object for one of the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn of platform application object to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602282 = newJObject()
  add(query_602282, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  add(query_602282, "Action", newJString(Action))
  add(query_602282, "Version", newJString(Version))
  result = call_602281.call(nil, query_602282, nil, nil, nil)

var getDeletePlatformApplication* = Call_GetDeletePlatformApplication_602267(
    name: "getDeletePlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=DeletePlatformApplication",
    validator: validate_GetDeletePlatformApplication_602268, base: "/",
    url: url_GetDeletePlatformApplication_602269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteTopic_602316 = ref object of OpenApiRestCall_601389
proc url_PostDeleteTopic_602318(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteTopic_602317(path: JsonNode; query: JsonNode;
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
  var valid_602319 = query.getOrDefault("Action")
  valid_602319 = validateParameter(valid_602319, JString, required = true,
                                 default = newJString("DeleteTopic"))
  if valid_602319 != nil:
    section.add "Action", valid_602319
  var valid_602320 = query.getOrDefault("Version")
  valid_602320 = validateParameter(valid_602320, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602320 != nil:
    section.add "Version", valid_602320
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602321 = header.getOrDefault("X-Amz-Signature")
  valid_602321 = validateParameter(valid_602321, JString, required = false,
                                 default = nil)
  if valid_602321 != nil:
    section.add "X-Amz-Signature", valid_602321
  var valid_602322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602322 = validateParameter(valid_602322, JString, required = false,
                                 default = nil)
  if valid_602322 != nil:
    section.add "X-Amz-Content-Sha256", valid_602322
  var valid_602323 = header.getOrDefault("X-Amz-Date")
  valid_602323 = validateParameter(valid_602323, JString, required = false,
                                 default = nil)
  if valid_602323 != nil:
    section.add "X-Amz-Date", valid_602323
  var valid_602324 = header.getOrDefault("X-Amz-Credential")
  valid_602324 = validateParameter(valid_602324, JString, required = false,
                                 default = nil)
  if valid_602324 != nil:
    section.add "X-Amz-Credential", valid_602324
  var valid_602325 = header.getOrDefault("X-Amz-Security-Token")
  valid_602325 = validateParameter(valid_602325, JString, required = false,
                                 default = nil)
  if valid_602325 != nil:
    section.add "X-Amz-Security-Token", valid_602325
  var valid_602326 = header.getOrDefault("X-Amz-Algorithm")
  valid_602326 = validateParameter(valid_602326, JString, required = false,
                                 default = nil)
  if valid_602326 != nil:
    section.add "X-Amz-Algorithm", valid_602326
  var valid_602327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602327 = validateParameter(valid_602327, JString, required = false,
                                 default = nil)
  if valid_602327 != nil:
    section.add "X-Amz-SignedHeaders", valid_602327
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic you want to delete.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_602328 = formData.getOrDefault("TopicArn")
  valid_602328 = validateParameter(valid_602328, JString, required = true,
                                 default = nil)
  if valid_602328 != nil:
    section.add "TopicArn", valid_602328
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602329: Call_PostDeleteTopic_602316; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ## 
  let valid = call_602329.validator(path, query, header, formData, body)
  let scheme = call_602329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602329.url(scheme.get, call_602329.host, call_602329.base,
                         call_602329.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602329, url, valid)

proc call*(call_602330: Call_PostDeleteTopic_602316; TopicArn: string;
          Action: string = "DeleteTopic"; Version: string = "2010-03-31"): Recallable =
  ## postDeleteTopic
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602331 = newJObject()
  var formData_602332 = newJObject()
  add(formData_602332, "TopicArn", newJString(TopicArn))
  add(query_602331, "Action", newJString(Action))
  add(query_602331, "Version", newJString(Version))
  result = call_602330.call(nil, query_602331, nil, formData_602332, nil)

var postDeleteTopic* = Call_PostDeleteTopic_602316(name: "postDeleteTopic",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=DeleteTopic", validator: validate_PostDeleteTopic_602317,
    base: "/", url: url_PostDeleteTopic_602318, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteTopic_602300 = ref object of OpenApiRestCall_601389
proc url_GetDeleteTopic_602302(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteTopic_602301(path: JsonNode; query: JsonNode;
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
  var valid_602303 = query.getOrDefault("Action")
  valid_602303 = validateParameter(valid_602303, JString, required = true,
                                 default = newJString("DeleteTopic"))
  if valid_602303 != nil:
    section.add "Action", valid_602303
  var valid_602304 = query.getOrDefault("Version")
  valid_602304 = validateParameter(valid_602304, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602304 != nil:
    section.add "Version", valid_602304
  var valid_602305 = query.getOrDefault("TopicArn")
  valid_602305 = validateParameter(valid_602305, JString, required = true,
                                 default = nil)
  if valid_602305 != nil:
    section.add "TopicArn", valid_602305
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602306 = header.getOrDefault("X-Amz-Signature")
  valid_602306 = validateParameter(valid_602306, JString, required = false,
                                 default = nil)
  if valid_602306 != nil:
    section.add "X-Amz-Signature", valid_602306
  var valid_602307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602307 = validateParameter(valid_602307, JString, required = false,
                                 default = nil)
  if valid_602307 != nil:
    section.add "X-Amz-Content-Sha256", valid_602307
  var valid_602308 = header.getOrDefault("X-Amz-Date")
  valid_602308 = validateParameter(valid_602308, JString, required = false,
                                 default = nil)
  if valid_602308 != nil:
    section.add "X-Amz-Date", valid_602308
  var valid_602309 = header.getOrDefault("X-Amz-Credential")
  valid_602309 = validateParameter(valid_602309, JString, required = false,
                                 default = nil)
  if valid_602309 != nil:
    section.add "X-Amz-Credential", valid_602309
  var valid_602310 = header.getOrDefault("X-Amz-Security-Token")
  valid_602310 = validateParameter(valid_602310, JString, required = false,
                                 default = nil)
  if valid_602310 != nil:
    section.add "X-Amz-Security-Token", valid_602310
  var valid_602311 = header.getOrDefault("X-Amz-Algorithm")
  valid_602311 = validateParameter(valid_602311, JString, required = false,
                                 default = nil)
  if valid_602311 != nil:
    section.add "X-Amz-Algorithm", valid_602311
  var valid_602312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602312 = validateParameter(valid_602312, JString, required = false,
                                 default = nil)
  if valid_602312 != nil:
    section.add "X-Amz-SignedHeaders", valid_602312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602313: Call_GetDeleteTopic_602300; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ## 
  let valid = call_602313.validator(path, query, header, formData, body)
  let scheme = call_602313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602313.url(scheme.get, call_602313.host, call_602313.base,
                         call_602313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602313, url, valid)

proc call*(call_602314: Call_GetDeleteTopic_602300; TopicArn: string;
          Action: string = "DeleteTopic"; Version: string = "2010-03-31"): Recallable =
  ## getDeleteTopic
  ## Deletes a topic and all its subscriptions. Deleting a topic might prevent some messages previously sent to the topic from being delivered to subscribers. This action is idempotent, so deleting a topic that does not exist does not result in an error.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic you want to delete.
  var query_602315 = newJObject()
  add(query_602315, "Action", newJString(Action))
  add(query_602315, "Version", newJString(Version))
  add(query_602315, "TopicArn", newJString(TopicArn))
  result = call_602314.call(nil, query_602315, nil, nil, nil)

var getDeleteTopic* = Call_GetDeleteTopic_602300(name: "getDeleteTopic",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=DeleteTopic", validator: validate_GetDeleteTopic_602301,
    base: "/", url: url_GetDeleteTopic_602302, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetEndpointAttributes_602349 = ref object of OpenApiRestCall_601389
proc url_PostGetEndpointAttributes_602351(protocol: Scheme; host: string;
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

proc validate_PostGetEndpointAttributes_602350(path: JsonNode; query: JsonNode;
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
  var valid_602352 = query.getOrDefault("Action")
  valid_602352 = validateParameter(valid_602352, JString, required = true,
                                 default = newJString("GetEndpointAttributes"))
  if valid_602352 != nil:
    section.add "Action", valid_602352
  var valid_602353 = query.getOrDefault("Version")
  valid_602353 = validateParameter(valid_602353, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602353 != nil:
    section.add "Version", valid_602353
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602354 = header.getOrDefault("X-Amz-Signature")
  valid_602354 = validateParameter(valid_602354, JString, required = false,
                                 default = nil)
  if valid_602354 != nil:
    section.add "X-Amz-Signature", valid_602354
  var valid_602355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602355 = validateParameter(valid_602355, JString, required = false,
                                 default = nil)
  if valid_602355 != nil:
    section.add "X-Amz-Content-Sha256", valid_602355
  var valid_602356 = header.getOrDefault("X-Amz-Date")
  valid_602356 = validateParameter(valid_602356, JString, required = false,
                                 default = nil)
  if valid_602356 != nil:
    section.add "X-Amz-Date", valid_602356
  var valid_602357 = header.getOrDefault("X-Amz-Credential")
  valid_602357 = validateParameter(valid_602357, JString, required = false,
                                 default = nil)
  if valid_602357 != nil:
    section.add "X-Amz-Credential", valid_602357
  var valid_602358 = header.getOrDefault("X-Amz-Security-Token")
  valid_602358 = validateParameter(valid_602358, JString, required = false,
                                 default = nil)
  if valid_602358 != nil:
    section.add "X-Amz-Security-Token", valid_602358
  var valid_602359 = header.getOrDefault("X-Amz-Algorithm")
  valid_602359 = validateParameter(valid_602359, JString, required = false,
                                 default = nil)
  if valid_602359 != nil:
    section.add "X-Amz-Algorithm", valid_602359
  var valid_602360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602360 = validateParameter(valid_602360, JString, required = false,
                                 default = nil)
  if valid_602360 != nil:
    section.add "X-Amz-SignedHeaders", valid_602360
  result.add "header", section
  ## parameters in `formData` object:
  ##   EndpointArn: JString (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_602361 = formData.getOrDefault("EndpointArn")
  valid_602361 = validateParameter(valid_602361, JString, required = true,
                                 default = nil)
  if valid_602361 != nil:
    section.add "EndpointArn", valid_602361
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602362: Call_PostGetEndpointAttributes_602349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_602362.validator(path, query, header, formData, body)
  let scheme = call_602362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602362.url(scheme.get, call_602362.host, call_602362.base,
                         call_602362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602362, url, valid)

proc call*(call_602363: Call_PostGetEndpointAttributes_602349; EndpointArn: string;
          Action: string = "GetEndpointAttributes"; Version: string = "2010-03-31"): Recallable =
  ## postGetEndpointAttributes
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   EndpointArn: string (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602364 = newJObject()
  var formData_602365 = newJObject()
  add(formData_602365, "EndpointArn", newJString(EndpointArn))
  add(query_602364, "Action", newJString(Action))
  add(query_602364, "Version", newJString(Version))
  result = call_602363.call(nil, query_602364, nil, formData_602365, nil)

var postGetEndpointAttributes* = Call_PostGetEndpointAttributes_602349(
    name: "postGetEndpointAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetEndpointAttributes",
    validator: validate_PostGetEndpointAttributes_602350, base: "/",
    url: url_PostGetEndpointAttributes_602351,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetEndpointAttributes_602333 = ref object of OpenApiRestCall_601389
proc url_GetGetEndpointAttributes_602335(protocol: Scheme; host: string;
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

proc validate_GetGetEndpointAttributes_602334(path: JsonNode; query: JsonNode;
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
  var valid_602336 = query.getOrDefault("Action")
  valid_602336 = validateParameter(valid_602336, JString, required = true,
                                 default = newJString("GetEndpointAttributes"))
  if valid_602336 != nil:
    section.add "Action", valid_602336
  var valid_602337 = query.getOrDefault("EndpointArn")
  valid_602337 = validateParameter(valid_602337, JString, required = true,
                                 default = nil)
  if valid_602337 != nil:
    section.add "EndpointArn", valid_602337
  var valid_602338 = query.getOrDefault("Version")
  valid_602338 = validateParameter(valid_602338, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602338 != nil:
    section.add "Version", valid_602338
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602339 = header.getOrDefault("X-Amz-Signature")
  valid_602339 = validateParameter(valid_602339, JString, required = false,
                                 default = nil)
  if valid_602339 != nil:
    section.add "X-Amz-Signature", valid_602339
  var valid_602340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602340 = validateParameter(valid_602340, JString, required = false,
                                 default = nil)
  if valid_602340 != nil:
    section.add "X-Amz-Content-Sha256", valid_602340
  var valid_602341 = header.getOrDefault("X-Amz-Date")
  valid_602341 = validateParameter(valid_602341, JString, required = false,
                                 default = nil)
  if valid_602341 != nil:
    section.add "X-Amz-Date", valid_602341
  var valid_602342 = header.getOrDefault("X-Amz-Credential")
  valid_602342 = validateParameter(valid_602342, JString, required = false,
                                 default = nil)
  if valid_602342 != nil:
    section.add "X-Amz-Credential", valid_602342
  var valid_602343 = header.getOrDefault("X-Amz-Security-Token")
  valid_602343 = validateParameter(valid_602343, JString, required = false,
                                 default = nil)
  if valid_602343 != nil:
    section.add "X-Amz-Security-Token", valid_602343
  var valid_602344 = header.getOrDefault("X-Amz-Algorithm")
  valid_602344 = validateParameter(valid_602344, JString, required = false,
                                 default = nil)
  if valid_602344 != nil:
    section.add "X-Amz-Algorithm", valid_602344
  var valid_602345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602345 = validateParameter(valid_602345, JString, required = false,
                                 default = nil)
  if valid_602345 != nil:
    section.add "X-Amz-SignedHeaders", valid_602345
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602346: Call_GetGetEndpointAttributes_602333; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_602346.validator(path, query, header, formData, body)
  let scheme = call_602346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602346.url(scheme.get, call_602346.host, call_602346.base,
                         call_602346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602346, url, valid)

proc call*(call_602347: Call_GetGetEndpointAttributes_602333; EndpointArn: string;
          Action: string = "GetEndpointAttributes"; Version: string = "2010-03-31"): Recallable =
  ## getGetEndpointAttributes
  ## Retrieves the endpoint attributes for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   Action: string (required)
  ##   EndpointArn: string (required)
  ##              : EndpointArn for GetEndpointAttributes input.
  ##   Version: string (required)
  var query_602348 = newJObject()
  add(query_602348, "Action", newJString(Action))
  add(query_602348, "EndpointArn", newJString(EndpointArn))
  add(query_602348, "Version", newJString(Version))
  result = call_602347.call(nil, query_602348, nil, nil, nil)

var getGetEndpointAttributes* = Call_GetGetEndpointAttributes_602333(
    name: "getGetEndpointAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetEndpointAttributes",
    validator: validate_GetGetEndpointAttributes_602334, base: "/",
    url: url_GetGetEndpointAttributes_602335, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetPlatformApplicationAttributes_602382 = ref object of OpenApiRestCall_601389
proc url_PostGetPlatformApplicationAttributes_602384(protocol: Scheme;
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

proc validate_PostGetPlatformApplicationAttributes_602383(path: JsonNode;
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
  var valid_602385 = query.getOrDefault("Action")
  valid_602385 = validateParameter(valid_602385, JString, required = true, default = newJString(
      "GetPlatformApplicationAttributes"))
  if valid_602385 != nil:
    section.add "Action", valid_602385
  var valid_602386 = query.getOrDefault("Version")
  valid_602386 = validateParameter(valid_602386, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602386 != nil:
    section.add "Version", valid_602386
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602387 = header.getOrDefault("X-Amz-Signature")
  valid_602387 = validateParameter(valid_602387, JString, required = false,
                                 default = nil)
  if valid_602387 != nil:
    section.add "X-Amz-Signature", valid_602387
  var valid_602388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602388 = validateParameter(valid_602388, JString, required = false,
                                 default = nil)
  if valid_602388 != nil:
    section.add "X-Amz-Content-Sha256", valid_602388
  var valid_602389 = header.getOrDefault("X-Amz-Date")
  valid_602389 = validateParameter(valid_602389, JString, required = false,
                                 default = nil)
  if valid_602389 != nil:
    section.add "X-Amz-Date", valid_602389
  var valid_602390 = header.getOrDefault("X-Amz-Credential")
  valid_602390 = validateParameter(valid_602390, JString, required = false,
                                 default = nil)
  if valid_602390 != nil:
    section.add "X-Amz-Credential", valid_602390
  var valid_602391 = header.getOrDefault("X-Amz-Security-Token")
  valid_602391 = validateParameter(valid_602391, JString, required = false,
                                 default = nil)
  if valid_602391 != nil:
    section.add "X-Amz-Security-Token", valid_602391
  var valid_602392 = header.getOrDefault("X-Amz-Algorithm")
  valid_602392 = validateParameter(valid_602392, JString, required = false,
                                 default = nil)
  if valid_602392 != nil:
    section.add "X-Amz-Algorithm", valid_602392
  var valid_602393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602393 = validateParameter(valid_602393, JString, required = false,
                                 default = nil)
  if valid_602393 != nil:
    section.add "X-Amz-SignedHeaders", valid_602393
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_602394 = formData.getOrDefault("PlatformApplicationArn")
  valid_602394 = validateParameter(valid_602394, JString, required = true,
                                 default = nil)
  if valid_602394 != nil:
    section.add "PlatformApplicationArn", valid_602394
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602395: Call_PostGetPlatformApplicationAttributes_602382;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_602395.validator(path, query, header, formData, body)
  let scheme = call_602395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602395.url(scheme.get, call_602395.host, call_602395.base,
                         call_602395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602395, url, valid)

proc call*(call_602396: Call_PostGetPlatformApplicationAttributes_602382;
          PlatformApplicationArn: string;
          Action: string = "GetPlatformApplicationAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetPlatformApplicationAttributes
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602397 = newJObject()
  var formData_602398 = newJObject()
  add(formData_602398, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(query_602397, "Action", newJString(Action))
  add(query_602397, "Version", newJString(Version))
  result = call_602396.call(nil, query_602397, nil, formData_602398, nil)

var postGetPlatformApplicationAttributes* = Call_PostGetPlatformApplicationAttributes_602382(
    name: "postGetPlatformApplicationAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetPlatformApplicationAttributes",
    validator: validate_PostGetPlatformApplicationAttributes_602383, base: "/",
    url: url_PostGetPlatformApplicationAttributes_602384,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetPlatformApplicationAttributes_602366 = ref object of OpenApiRestCall_601389
proc url_GetGetPlatformApplicationAttributes_602368(protocol: Scheme; host: string;
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

proc validate_GetGetPlatformApplicationAttributes_602367(path: JsonNode;
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
  var valid_602369 = query.getOrDefault("PlatformApplicationArn")
  valid_602369 = validateParameter(valid_602369, JString, required = true,
                                 default = nil)
  if valid_602369 != nil:
    section.add "PlatformApplicationArn", valid_602369
  var valid_602370 = query.getOrDefault("Action")
  valid_602370 = validateParameter(valid_602370, JString, required = true, default = newJString(
      "GetPlatformApplicationAttributes"))
  if valid_602370 != nil:
    section.add "Action", valid_602370
  var valid_602371 = query.getOrDefault("Version")
  valid_602371 = validateParameter(valid_602371, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602371 != nil:
    section.add "Version", valid_602371
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602372 = header.getOrDefault("X-Amz-Signature")
  valid_602372 = validateParameter(valid_602372, JString, required = false,
                                 default = nil)
  if valid_602372 != nil:
    section.add "X-Amz-Signature", valid_602372
  var valid_602373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602373 = validateParameter(valid_602373, JString, required = false,
                                 default = nil)
  if valid_602373 != nil:
    section.add "X-Amz-Content-Sha256", valid_602373
  var valid_602374 = header.getOrDefault("X-Amz-Date")
  valid_602374 = validateParameter(valid_602374, JString, required = false,
                                 default = nil)
  if valid_602374 != nil:
    section.add "X-Amz-Date", valid_602374
  var valid_602375 = header.getOrDefault("X-Amz-Credential")
  valid_602375 = validateParameter(valid_602375, JString, required = false,
                                 default = nil)
  if valid_602375 != nil:
    section.add "X-Amz-Credential", valid_602375
  var valid_602376 = header.getOrDefault("X-Amz-Security-Token")
  valid_602376 = validateParameter(valid_602376, JString, required = false,
                                 default = nil)
  if valid_602376 != nil:
    section.add "X-Amz-Security-Token", valid_602376
  var valid_602377 = header.getOrDefault("X-Amz-Algorithm")
  valid_602377 = validateParameter(valid_602377, JString, required = false,
                                 default = nil)
  if valid_602377 != nil:
    section.add "X-Amz-Algorithm", valid_602377
  var valid_602378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602378 = validateParameter(valid_602378, JString, required = false,
                                 default = nil)
  if valid_602378 != nil:
    section.add "X-Amz-SignedHeaders", valid_602378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602379: Call_GetGetPlatformApplicationAttributes_602366;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_602379.validator(path, query, header, formData, body)
  let scheme = call_602379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602379.url(scheme.get, call_602379.host, call_602379.base,
                         call_602379.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602379, url, valid)

proc call*(call_602380: Call_GetGetPlatformApplicationAttributes_602366;
          PlatformApplicationArn: string;
          Action: string = "GetPlatformApplicationAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getGetPlatformApplicationAttributes
  ## Retrieves the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ##   PlatformApplicationArn: string (required)
  ##                         : PlatformApplicationArn for GetPlatformApplicationAttributesInput.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602381 = newJObject()
  add(query_602381, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  add(query_602381, "Action", newJString(Action))
  add(query_602381, "Version", newJString(Version))
  result = call_602380.call(nil, query_602381, nil, nil, nil)

var getGetPlatformApplicationAttributes* = Call_GetGetPlatformApplicationAttributes_602366(
    name: "getGetPlatformApplicationAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetPlatformApplicationAttributes",
    validator: validate_GetGetPlatformApplicationAttributes_602367, base: "/",
    url: url_GetGetPlatformApplicationAttributes_602368,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetSMSAttributes_602415 = ref object of OpenApiRestCall_601389
proc url_PostGetSMSAttributes_602417(protocol: Scheme; host: string; base: string;
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

proc validate_PostGetSMSAttributes_602416(path: JsonNode; query: JsonNode;
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
  var valid_602418 = query.getOrDefault("Action")
  valid_602418 = validateParameter(valid_602418, JString, required = true,
                                 default = newJString("GetSMSAttributes"))
  if valid_602418 != nil:
    section.add "Action", valid_602418
  var valid_602419 = query.getOrDefault("Version")
  valid_602419 = validateParameter(valid_602419, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602419 != nil:
    section.add "Version", valid_602419
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602420 = header.getOrDefault("X-Amz-Signature")
  valid_602420 = validateParameter(valid_602420, JString, required = false,
                                 default = nil)
  if valid_602420 != nil:
    section.add "X-Amz-Signature", valid_602420
  var valid_602421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602421 = validateParameter(valid_602421, JString, required = false,
                                 default = nil)
  if valid_602421 != nil:
    section.add "X-Amz-Content-Sha256", valid_602421
  var valid_602422 = header.getOrDefault("X-Amz-Date")
  valid_602422 = validateParameter(valid_602422, JString, required = false,
                                 default = nil)
  if valid_602422 != nil:
    section.add "X-Amz-Date", valid_602422
  var valid_602423 = header.getOrDefault("X-Amz-Credential")
  valid_602423 = validateParameter(valid_602423, JString, required = false,
                                 default = nil)
  if valid_602423 != nil:
    section.add "X-Amz-Credential", valid_602423
  var valid_602424 = header.getOrDefault("X-Amz-Security-Token")
  valid_602424 = validateParameter(valid_602424, JString, required = false,
                                 default = nil)
  if valid_602424 != nil:
    section.add "X-Amz-Security-Token", valid_602424
  var valid_602425 = header.getOrDefault("X-Amz-Algorithm")
  valid_602425 = validateParameter(valid_602425, JString, required = false,
                                 default = nil)
  if valid_602425 != nil:
    section.add "X-Amz-Algorithm", valid_602425
  var valid_602426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602426 = validateParameter(valid_602426, JString, required = false,
                                 default = nil)
  if valid_602426 != nil:
    section.add "X-Amz-SignedHeaders", valid_602426
  result.add "header", section
  ## parameters in `formData` object:
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  section = newJObject()
  var valid_602427 = formData.getOrDefault("attributes")
  valid_602427 = validateParameter(valid_602427, JArray, required = false,
                                 default = nil)
  if valid_602427 != nil:
    section.add "attributes", valid_602427
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602428: Call_PostGetSMSAttributes_602415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  let valid = call_602428.validator(path, query, header, formData, body)
  let scheme = call_602428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602428.url(scheme.get, call_602428.host, call_602428.base,
                         call_602428.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602428, url, valid)

proc call*(call_602429: Call_PostGetSMSAttributes_602415;
          attributes: JsonNode = nil; Action: string = "GetSMSAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetSMSAttributes
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602430 = newJObject()
  var formData_602431 = newJObject()
  if attributes != nil:
    formData_602431.add "attributes", attributes
  add(query_602430, "Action", newJString(Action))
  add(query_602430, "Version", newJString(Version))
  result = call_602429.call(nil, query_602430, nil, formData_602431, nil)

var postGetSMSAttributes* = Call_PostGetSMSAttributes_602415(
    name: "postGetSMSAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetSMSAttributes",
    validator: validate_PostGetSMSAttributes_602416, base: "/",
    url: url_PostGetSMSAttributes_602417, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetSMSAttributes_602399 = ref object of OpenApiRestCall_601389
proc url_GetGetSMSAttributes_602401(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetSMSAttributes_602400(path: JsonNode; query: JsonNode;
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
  var valid_602402 = query.getOrDefault("Action")
  valid_602402 = validateParameter(valid_602402, JString, required = true,
                                 default = newJString("GetSMSAttributes"))
  if valid_602402 != nil:
    section.add "Action", valid_602402
  var valid_602403 = query.getOrDefault("attributes")
  valid_602403 = validateParameter(valid_602403, JArray, required = false,
                                 default = nil)
  if valid_602403 != nil:
    section.add "attributes", valid_602403
  var valid_602404 = query.getOrDefault("Version")
  valid_602404 = validateParameter(valid_602404, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602404 != nil:
    section.add "Version", valid_602404
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602405 = header.getOrDefault("X-Amz-Signature")
  valid_602405 = validateParameter(valid_602405, JString, required = false,
                                 default = nil)
  if valid_602405 != nil:
    section.add "X-Amz-Signature", valid_602405
  var valid_602406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602406 = validateParameter(valid_602406, JString, required = false,
                                 default = nil)
  if valid_602406 != nil:
    section.add "X-Amz-Content-Sha256", valid_602406
  var valid_602407 = header.getOrDefault("X-Amz-Date")
  valid_602407 = validateParameter(valid_602407, JString, required = false,
                                 default = nil)
  if valid_602407 != nil:
    section.add "X-Amz-Date", valid_602407
  var valid_602408 = header.getOrDefault("X-Amz-Credential")
  valid_602408 = validateParameter(valid_602408, JString, required = false,
                                 default = nil)
  if valid_602408 != nil:
    section.add "X-Amz-Credential", valid_602408
  var valid_602409 = header.getOrDefault("X-Amz-Security-Token")
  valid_602409 = validateParameter(valid_602409, JString, required = false,
                                 default = nil)
  if valid_602409 != nil:
    section.add "X-Amz-Security-Token", valid_602409
  var valid_602410 = header.getOrDefault("X-Amz-Algorithm")
  valid_602410 = validateParameter(valid_602410, JString, required = false,
                                 default = nil)
  if valid_602410 != nil:
    section.add "X-Amz-Algorithm", valid_602410
  var valid_602411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602411 = validateParameter(valid_602411, JString, required = false,
                                 default = nil)
  if valid_602411 != nil:
    section.add "X-Amz-SignedHeaders", valid_602411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602412: Call_GetGetSMSAttributes_602399; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ## 
  let valid = call_602412.validator(path, query, header, formData, body)
  let scheme = call_602412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602412.url(scheme.get, call_602412.host, call_602412.base,
                         call_602412.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602412, url, valid)

proc call*(call_602413: Call_GetGetSMSAttributes_602399;
          Action: string = "GetSMSAttributes"; attributes: JsonNode = nil;
          Version: string = "2010-03-31"): Recallable =
  ## getGetSMSAttributes
  ## <p>Returns the settings for sending SMS messages from your account.</p> <p>These settings are set with the <code>SetSMSAttributes</code> action.</p>
  ##   Action: string (required)
  ##   attributes: JArray
  ##             : <p>A list of the individual attribute names, such as <code>MonthlySpendLimit</code>, for which you want values.</p> <p>For all attribute names, see <a 
  ## href="https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html">SetSMSAttributes</a>.</p> <p>If you don't use this parameter, Amazon SNS returns all SMS attributes.</p>
  ##   Version: string (required)
  var query_602414 = newJObject()
  add(query_602414, "Action", newJString(Action))
  if attributes != nil:
    query_602414.add "attributes", attributes
  add(query_602414, "Version", newJString(Version))
  result = call_602413.call(nil, query_602414, nil, nil, nil)

var getGetSMSAttributes* = Call_GetGetSMSAttributes_602399(
    name: "getGetSMSAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetSMSAttributes",
    validator: validate_GetGetSMSAttributes_602400, base: "/",
    url: url_GetGetSMSAttributes_602401, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetSubscriptionAttributes_602448 = ref object of OpenApiRestCall_601389
proc url_PostGetSubscriptionAttributes_602450(protocol: Scheme; host: string;
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

proc validate_PostGetSubscriptionAttributes_602449(path: JsonNode; query: JsonNode;
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
  var valid_602451 = query.getOrDefault("Action")
  valid_602451 = validateParameter(valid_602451, JString, required = true, default = newJString(
      "GetSubscriptionAttributes"))
  if valid_602451 != nil:
    section.add "Action", valid_602451
  var valid_602452 = query.getOrDefault("Version")
  valid_602452 = validateParameter(valid_602452, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602452 != nil:
    section.add "Version", valid_602452
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602453 = header.getOrDefault("X-Amz-Signature")
  valid_602453 = validateParameter(valid_602453, JString, required = false,
                                 default = nil)
  if valid_602453 != nil:
    section.add "X-Amz-Signature", valid_602453
  var valid_602454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602454 = validateParameter(valid_602454, JString, required = false,
                                 default = nil)
  if valid_602454 != nil:
    section.add "X-Amz-Content-Sha256", valid_602454
  var valid_602455 = header.getOrDefault("X-Amz-Date")
  valid_602455 = validateParameter(valid_602455, JString, required = false,
                                 default = nil)
  if valid_602455 != nil:
    section.add "X-Amz-Date", valid_602455
  var valid_602456 = header.getOrDefault("X-Amz-Credential")
  valid_602456 = validateParameter(valid_602456, JString, required = false,
                                 default = nil)
  if valid_602456 != nil:
    section.add "X-Amz-Credential", valid_602456
  var valid_602457 = header.getOrDefault("X-Amz-Security-Token")
  valid_602457 = validateParameter(valid_602457, JString, required = false,
                                 default = nil)
  if valid_602457 != nil:
    section.add "X-Amz-Security-Token", valid_602457
  var valid_602458 = header.getOrDefault("X-Amz-Algorithm")
  valid_602458 = validateParameter(valid_602458, JString, required = false,
                                 default = nil)
  if valid_602458 != nil:
    section.add "X-Amz-Algorithm", valid_602458
  var valid_602459 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602459 = validateParameter(valid_602459, JString, required = false,
                                 default = nil)
  if valid_602459 != nil:
    section.add "X-Amz-SignedHeaders", valid_602459
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionArn` field"
  var valid_602460 = formData.getOrDefault("SubscriptionArn")
  valid_602460 = validateParameter(valid_602460, JString, required = true,
                                 default = nil)
  if valid_602460 != nil:
    section.add "SubscriptionArn", valid_602460
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602461: Call_PostGetSubscriptionAttributes_602448; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a subscription.
  ## 
  let valid = call_602461.validator(path, query, header, formData, body)
  let scheme = call_602461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602461.url(scheme.get, call_602461.host, call_602461.base,
                         call_602461.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602461, url, valid)

proc call*(call_602462: Call_PostGetSubscriptionAttributes_602448;
          SubscriptionArn: string; Action: string = "GetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## postGetSubscriptionAttributes
  ## Returns all of the properties of a subscription.
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602463 = newJObject()
  var formData_602464 = newJObject()
  add(formData_602464, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_602463, "Action", newJString(Action))
  add(query_602463, "Version", newJString(Version))
  result = call_602462.call(nil, query_602463, nil, formData_602464, nil)

var postGetSubscriptionAttributes* = Call_PostGetSubscriptionAttributes_602448(
    name: "postGetSubscriptionAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetSubscriptionAttributes",
    validator: validate_PostGetSubscriptionAttributes_602449, base: "/",
    url: url_PostGetSubscriptionAttributes_602450,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetSubscriptionAttributes_602432 = ref object of OpenApiRestCall_601389
proc url_GetGetSubscriptionAttributes_602434(protocol: Scheme; host: string;
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

proc validate_GetGetSubscriptionAttributes_602433(path: JsonNode; query: JsonNode;
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
  var valid_602435 = query.getOrDefault("SubscriptionArn")
  valid_602435 = validateParameter(valid_602435, JString, required = true,
                                 default = nil)
  if valid_602435 != nil:
    section.add "SubscriptionArn", valid_602435
  var valid_602436 = query.getOrDefault("Action")
  valid_602436 = validateParameter(valid_602436, JString, required = true, default = newJString(
      "GetSubscriptionAttributes"))
  if valid_602436 != nil:
    section.add "Action", valid_602436
  var valid_602437 = query.getOrDefault("Version")
  valid_602437 = validateParameter(valid_602437, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602437 != nil:
    section.add "Version", valid_602437
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602438 = header.getOrDefault("X-Amz-Signature")
  valid_602438 = validateParameter(valid_602438, JString, required = false,
                                 default = nil)
  if valid_602438 != nil:
    section.add "X-Amz-Signature", valid_602438
  var valid_602439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602439 = validateParameter(valid_602439, JString, required = false,
                                 default = nil)
  if valid_602439 != nil:
    section.add "X-Amz-Content-Sha256", valid_602439
  var valid_602440 = header.getOrDefault("X-Amz-Date")
  valid_602440 = validateParameter(valid_602440, JString, required = false,
                                 default = nil)
  if valid_602440 != nil:
    section.add "X-Amz-Date", valid_602440
  var valid_602441 = header.getOrDefault("X-Amz-Credential")
  valid_602441 = validateParameter(valid_602441, JString, required = false,
                                 default = nil)
  if valid_602441 != nil:
    section.add "X-Amz-Credential", valid_602441
  var valid_602442 = header.getOrDefault("X-Amz-Security-Token")
  valid_602442 = validateParameter(valid_602442, JString, required = false,
                                 default = nil)
  if valid_602442 != nil:
    section.add "X-Amz-Security-Token", valid_602442
  var valid_602443 = header.getOrDefault("X-Amz-Algorithm")
  valid_602443 = validateParameter(valid_602443, JString, required = false,
                                 default = nil)
  if valid_602443 != nil:
    section.add "X-Amz-Algorithm", valid_602443
  var valid_602444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602444 = validateParameter(valid_602444, JString, required = false,
                                 default = nil)
  if valid_602444 != nil:
    section.add "X-Amz-SignedHeaders", valid_602444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602445: Call_GetGetSubscriptionAttributes_602432; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a subscription.
  ## 
  let valid = call_602445.validator(path, query, header, formData, body)
  let scheme = call_602445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602445.url(scheme.get, call_602445.host, call_602445.base,
                         call_602445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602445, url, valid)

proc call*(call_602446: Call_GetGetSubscriptionAttributes_602432;
          SubscriptionArn: string; Action: string = "GetSubscriptionAttributes";
          Version: string = "2010-03-31"): Recallable =
  ## getGetSubscriptionAttributes
  ## Returns all of the properties of a subscription.
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription whose properties you want to get.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602447 = newJObject()
  add(query_602447, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_602447, "Action", newJString(Action))
  add(query_602447, "Version", newJString(Version))
  result = call_602446.call(nil, query_602447, nil, nil, nil)

var getGetSubscriptionAttributes* = Call_GetGetSubscriptionAttributes_602432(
    name: "getGetSubscriptionAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetSubscriptionAttributes",
    validator: validate_GetGetSubscriptionAttributes_602433, base: "/",
    url: url_GetGetSubscriptionAttributes_602434,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetTopicAttributes_602481 = ref object of OpenApiRestCall_601389
proc url_PostGetTopicAttributes_602483(protocol: Scheme; host: string; base: string;
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

proc validate_PostGetTopicAttributes_602482(path: JsonNode; query: JsonNode;
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
  var valid_602484 = query.getOrDefault("Action")
  valid_602484 = validateParameter(valid_602484, JString, required = true,
                                 default = newJString("GetTopicAttributes"))
  if valid_602484 != nil:
    section.add "Action", valid_602484
  var valid_602485 = query.getOrDefault("Version")
  valid_602485 = validateParameter(valid_602485, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602485 != nil:
    section.add "Version", valid_602485
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602486 = header.getOrDefault("X-Amz-Signature")
  valid_602486 = validateParameter(valid_602486, JString, required = false,
                                 default = nil)
  if valid_602486 != nil:
    section.add "X-Amz-Signature", valid_602486
  var valid_602487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602487 = validateParameter(valid_602487, JString, required = false,
                                 default = nil)
  if valid_602487 != nil:
    section.add "X-Amz-Content-Sha256", valid_602487
  var valid_602488 = header.getOrDefault("X-Amz-Date")
  valid_602488 = validateParameter(valid_602488, JString, required = false,
                                 default = nil)
  if valid_602488 != nil:
    section.add "X-Amz-Date", valid_602488
  var valid_602489 = header.getOrDefault("X-Amz-Credential")
  valid_602489 = validateParameter(valid_602489, JString, required = false,
                                 default = nil)
  if valid_602489 != nil:
    section.add "X-Amz-Credential", valid_602489
  var valid_602490 = header.getOrDefault("X-Amz-Security-Token")
  valid_602490 = validateParameter(valid_602490, JString, required = false,
                                 default = nil)
  if valid_602490 != nil:
    section.add "X-Amz-Security-Token", valid_602490
  var valid_602491 = header.getOrDefault("X-Amz-Algorithm")
  valid_602491 = validateParameter(valid_602491, JString, required = false,
                                 default = nil)
  if valid_602491 != nil:
    section.add "X-Amz-Algorithm", valid_602491
  var valid_602492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602492 = validateParameter(valid_602492, JString, required = false,
                                 default = nil)
  if valid_602492 != nil:
    section.add "X-Amz-SignedHeaders", valid_602492
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose properties you want to get.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_602493 = formData.getOrDefault("TopicArn")
  valid_602493 = validateParameter(valid_602493, JString, required = true,
                                 default = nil)
  if valid_602493 != nil:
    section.add "TopicArn", valid_602493
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602494: Call_PostGetTopicAttributes_602481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ## 
  let valid = call_602494.validator(path, query, header, formData, body)
  let scheme = call_602494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602494.url(scheme.get, call_602494.host, call_602494.base,
                         call_602494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602494, url, valid)

proc call*(call_602495: Call_PostGetTopicAttributes_602481; TopicArn: string;
          Action: string = "GetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## postGetTopicAttributes
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose properties you want to get.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602496 = newJObject()
  var formData_602497 = newJObject()
  add(formData_602497, "TopicArn", newJString(TopicArn))
  add(query_602496, "Action", newJString(Action))
  add(query_602496, "Version", newJString(Version))
  result = call_602495.call(nil, query_602496, nil, formData_602497, nil)

var postGetTopicAttributes* = Call_PostGetTopicAttributes_602481(
    name: "postGetTopicAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=GetTopicAttributes",
    validator: validate_PostGetTopicAttributes_602482, base: "/",
    url: url_PostGetTopicAttributes_602483, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetTopicAttributes_602465 = ref object of OpenApiRestCall_601389
proc url_GetGetTopicAttributes_602467(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetTopicAttributes_602466(path: JsonNode; query: JsonNode;
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
  var valid_602468 = query.getOrDefault("Action")
  valid_602468 = validateParameter(valid_602468, JString, required = true,
                                 default = newJString("GetTopicAttributes"))
  if valid_602468 != nil:
    section.add "Action", valid_602468
  var valid_602469 = query.getOrDefault("Version")
  valid_602469 = validateParameter(valid_602469, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602469 != nil:
    section.add "Version", valid_602469
  var valid_602470 = query.getOrDefault("TopicArn")
  valid_602470 = validateParameter(valid_602470, JString, required = true,
                                 default = nil)
  if valid_602470 != nil:
    section.add "TopicArn", valid_602470
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602471 = header.getOrDefault("X-Amz-Signature")
  valid_602471 = validateParameter(valid_602471, JString, required = false,
                                 default = nil)
  if valid_602471 != nil:
    section.add "X-Amz-Signature", valid_602471
  var valid_602472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602472 = validateParameter(valid_602472, JString, required = false,
                                 default = nil)
  if valid_602472 != nil:
    section.add "X-Amz-Content-Sha256", valid_602472
  var valid_602473 = header.getOrDefault("X-Amz-Date")
  valid_602473 = validateParameter(valid_602473, JString, required = false,
                                 default = nil)
  if valid_602473 != nil:
    section.add "X-Amz-Date", valid_602473
  var valid_602474 = header.getOrDefault("X-Amz-Credential")
  valid_602474 = validateParameter(valid_602474, JString, required = false,
                                 default = nil)
  if valid_602474 != nil:
    section.add "X-Amz-Credential", valid_602474
  var valid_602475 = header.getOrDefault("X-Amz-Security-Token")
  valid_602475 = validateParameter(valid_602475, JString, required = false,
                                 default = nil)
  if valid_602475 != nil:
    section.add "X-Amz-Security-Token", valid_602475
  var valid_602476 = header.getOrDefault("X-Amz-Algorithm")
  valid_602476 = validateParameter(valid_602476, JString, required = false,
                                 default = nil)
  if valid_602476 != nil:
    section.add "X-Amz-Algorithm", valid_602476
  var valid_602477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602477 = validateParameter(valid_602477, JString, required = false,
                                 default = nil)
  if valid_602477 != nil:
    section.add "X-Amz-SignedHeaders", valid_602477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602478: Call_GetGetTopicAttributes_602465; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ## 
  let valid = call_602478.validator(path, query, header, formData, body)
  let scheme = call_602478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602478.url(scheme.get, call_602478.host, call_602478.base,
                         call_602478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602478, url, valid)

proc call*(call_602479: Call_GetGetTopicAttributes_602465; TopicArn: string;
          Action: string = "GetTopicAttributes"; Version: string = "2010-03-31"): Recallable =
  ## getGetTopicAttributes
  ## Returns all of the properties of a topic. Topic properties returned might differ based on the authorization of the user.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   TopicArn: string (required)
  ##           : The ARN of the topic whose properties you want to get.
  var query_602480 = newJObject()
  add(query_602480, "Action", newJString(Action))
  add(query_602480, "Version", newJString(Version))
  add(query_602480, "TopicArn", newJString(TopicArn))
  result = call_602479.call(nil, query_602480, nil, nil, nil)

var getGetTopicAttributes* = Call_GetGetTopicAttributes_602465(
    name: "getGetTopicAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=GetTopicAttributes",
    validator: validate_GetGetTopicAttributes_602466, base: "/",
    url: url_GetGetTopicAttributes_602467, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListEndpointsByPlatformApplication_602515 = ref object of OpenApiRestCall_601389
proc url_PostListEndpointsByPlatformApplication_602517(protocol: Scheme;
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

proc validate_PostListEndpointsByPlatformApplication_602516(path: JsonNode;
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
  var valid_602518 = query.getOrDefault("Action")
  valid_602518 = validateParameter(valid_602518, JString, required = true, default = newJString(
      "ListEndpointsByPlatformApplication"))
  if valid_602518 != nil:
    section.add "Action", valid_602518
  var valid_602519 = query.getOrDefault("Version")
  valid_602519 = validateParameter(valid_602519, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602519 != nil:
    section.add "Version", valid_602519
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602520 = header.getOrDefault("X-Amz-Signature")
  valid_602520 = validateParameter(valid_602520, JString, required = false,
                                 default = nil)
  if valid_602520 != nil:
    section.add "X-Amz-Signature", valid_602520
  var valid_602521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602521 = validateParameter(valid_602521, JString, required = false,
                                 default = nil)
  if valid_602521 != nil:
    section.add "X-Amz-Content-Sha256", valid_602521
  var valid_602522 = header.getOrDefault("X-Amz-Date")
  valid_602522 = validateParameter(valid_602522, JString, required = false,
                                 default = nil)
  if valid_602522 != nil:
    section.add "X-Amz-Date", valid_602522
  var valid_602523 = header.getOrDefault("X-Amz-Credential")
  valid_602523 = validateParameter(valid_602523, JString, required = false,
                                 default = nil)
  if valid_602523 != nil:
    section.add "X-Amz-Credential", valid_602523
  var valid_602524 = header.getOrDefault("X-Amz-Security-Token")
  valid_602524 = validateParameter(valid_602524, JString, required = false,
                                 default = nil)
  if valid_602524 != nil:
    section.add "X-Amz-Security-Token", valid_602524
  var valid_602525 = header.getOrDefault("X-Amz-Algorithm")
  valid_602525 = validateParameter(valid_602525, JString, required = false,
                                 default = nil)
  if valid_602525 != nil:
    section.add "X-Amz-Algorithm", valid_602525
  var valid_602526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602526 = validateParameter(valid_602526, JString, required = false,
                                 default = nil)
  if valid_602526 != nil:
    section.add "X-Amz-SignedHeaders", valid_602526
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformApplicationArn: JString (required)
  ##                         : PlatformApplicationArn for ListEndpointsByPlatformApplicationInput action.
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListEndpointsByPlatformApplication action to retrieve additional records that are available after the first page results.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `PlatformApplicationArn` field"
  var valid_602527 = formData.getOrDefault("PlatformApplicationArn")
  valid_602527 = validateParameter(valid_602527, JString, required = true,
                                 default = nil)
  if valid_602527 != nil:
    section.add "PlatformApplicationArn", valid_602527
  var valid_602528 = formData.getOrDefault("NextToken")
  valid_602528 = validateParameter(valid_602528, JString, required = false,
                                 default = nil)
  if valid_602528 != nil:
    section.add "NextToken", valid_602528
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602529: Call_PostListEndpointsByPlatformApplication_602515;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as FCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_602529.validator(path, query, header, formData, body)
  let scheme = call_602529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602529.url(scheme.get, call_602529.host, call_602529.base,
                         call_602529.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602529, url, valid)

proc call*(call_602530: Call_PostListEndpointsByPlatformApplication_602515;
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
  var query_602531 = newJObject()
  var formData_602532 = newJObject()
  add(formData_602532, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(formData_602532, "NextToken", newJString(NextToken))
  add(query_602531, "Action", newJString(Action))
  add(query_602531, "Version", newJString(Version))
  result = call_602530.call(nil, query_602531, nil, formData_602532, nil)

var postListEndpointsByPlatformApplication* = Call_PostListEndpointsByPlatformApplication_602515(
    name: "postListEndpointsByPlatformApplication", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com",
    route: "/#Action=ListEndpointsByPlatformApplication",
    validator: validate_PostListEndpointsByPlatformApplication_602516, base: "/",
    url: url_PostListEndpointsByPlatformApplication_602517,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListEndpointsByPlatformApplication_602498 = ref object of OpenApiRestCall_601389
proc url_GetListEndpointsByPlatformApplication_602500(protocol: Scheme;
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

proc validate_GetListEndpointsByPlatformApplication_602499(path: JsonNode;
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
  var valid_602501 = query.getOrDefault("NextToken")
  valid_602501 = validateParameter(valid_602501, JString, required = false,
                                 default = nil)
  if valid_602501 != nil:
    section.add "NextToken", valid_602501
  assert query != nil, "query argument is necessary due to required `PlatformApplicationArn` field"
  var valid_602502 = query.getOrDefault("PlatformApplicationArn")
  valid_602502 = validateParameter(valid_602502, JString, required = true,
                                 default = nil)
  if valid_602502 != nil:
    section.add "PlatformApplicationArn", valid_602502
  var valid_602503 = query.getOrDefault("Action")
  valid_602503 = validateParameter(valid_602503, JString, required = true, default = newJString(
      "ListEndpointsByPlatformApplication"))
  if valid_602503 != nil:
    section.add "Action", valid_602503
  var valid_602504 = query.getOrDefault("Version")
  valid_602504 = validateParameter(valid_602504, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602504 != nil:
    section.add "Version", valid_602504
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602505 = header.getOrDefault("X-Amz-Signature")
  valid_602505 = validateParameter(valid_602505, JString, required = false,
                                 default = nil)
  if valid_602505 != nil:
    section.add "X-Amz-Signature", valid_602505
  var valid_602506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602506 = validateParameter(valid_602506, JString, required = false,
                                 default = nil)
  if valid_602506 != nil:
    section.add "X-Amz-Content-Sha256", valid_602506
  var valid_602507 = header.getOrDefault("X-Amz-Date")
  valid_602507 = validateParameter(valid_602507, JString, required = false,
                                 default = nil)
  if valid_602507 != nil:
    section.add "X-Amz-Date", valid_602507
  var valid_602508 = header.getOrDefault("X-Amz-Credential")
  valid_602508 = validateParameter(valid_602508, JString, required = false,
                                 default = nil)
  if valid_602508 != nil:
    section.add "X-Amz-Credential", valid_602508
  var valid_602509 = header.getOrDefault("X-Amz-Security-Token")
  valid_602509 = validateParameter(valid_602509, JString, required = false,
                                 default = nil)
  if valid_602509 != nil:
    section.add "X-Amz-Security-Token", valid_602509
  var valid_602510 = header.getOrDefault("X-Amz-Algorithm")
  valid_602510 = validateParameter(valid_602510, JString, required = false,
                                 default = nil)
  if valid_602510 != nil:
    section.add "X-Amz-Algorithm", valid_602510
  var valid_602511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602511 = validateParameter(valid_602511, JString, required = false,
                                 default = nil)
  if valid_602511 != nil:
    section.add "X-Amz-SignedHeaders", valid_602511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602512: Call_GetListEndpointsByPlatformApplication_602498;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Lists the endpoints and endpoint attributes for devices in a supported push notification service, such as FCM and APNS. The results for <code>ListEndpointsByPlatformApplication</code> are paginated and return a limited list of endpoints, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListEndpointsByPlatformApplication</code> again using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_602512.validator(path, query, header, formData, body)
  let scheme = call_602512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602512.url(scheme.get, call_602512.host, call_602512.base,
                         call_602512.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602512, url, valid)

proc call*(call_602513: Call_GetListEndpointsByPlatformApplication_602498;
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
  var query_602514 = newJObject()
  add(query_602514, "NextToken", newJString(NextToken))
  add(query_602514, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  add(query_602514, "Action", newJString(Action))
  add(query_602514, "Version", newJString(Version))
  result = call_602513.call(nil, query_602514, nil, nil, nil)

var getListEndpointsByPlatformApplication* = Call_GetListEndpointsByPlatformApplication_602498(
    name: "getListEndpointsByPlatformApplication", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com",
    route: "/#Action=ListEndpointsByPlatformApplication",
    validator: validate_GetListEndpointsByPlatformApplication_602499, base: "/",
    url: url_GetListEndpointsByPlatformApplication_602500,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPhoneNumbersOptedOut_602549 = ref object of OpenApiRestCall_601389
proc url_PostListPhoneNumbersOptedOut_602551(protocol: Scheme; host: string;
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

proc validate_PostListPhoneNumbersOptedOut_602550(path: JsonNode; query: JsonNode;
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
  var valid_602552 = query.getOrDefault("Action")
  valid_602552 = validateParameter(valid_602552, JString, required = true, default = newJString(
      "ListPhoneNumbersOptedOut"))
  if valid_602552 != nil:
    section.add "Action", valid_602552
  var valid_602553 = query.getOrDefault("Version")
  valid_602553 = validateParameter(valid_602553, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602553 != nil:
    section.add "Version", valid_602553
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602554 = header.getOrDefault("X-Amz-Signature")
  valid_602554 = validateParameter(valid_602554, JString, required = false,
                                 default = nil)
  if valid_602554 != nil:
    section.add "X-Amz-Signature", valid_602554
  var valid_602555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602555 = validateParameter(valid_602555, JString, required = false,
                                 default = nil)
  if valid_602555 != nil:
    section.add "X-Amz-Content-Sha256", valid_602555
  var valid_602556 = header.getOrDefault("X-Amz-Date")
  valid_602556 = validateParameter(valid_602556, JString, required = false,
                                 default = nil)
  if valid_602556 != nil:
    section.add "X-Amz-Date", valid_602556
  var valid_602557 = header.getOrDefault("X-Amz-Credential")
  valid_602557 = validateParameter(valid_602557, JString, required = false,
                                 default = nil)
  if valid_602557 != nil:
    section.add "X-Amz-Credential", valid_602557
  var valid_602558 = header.getOrDefault("X-Amz-Security-Token")
  valid_602558 = validateParameter(valid_602558, JString, required = false,
                                 default = nil)
  if valid_602558 != nil:
    section.add "X-Amz-Security-Token", valid_602558
  var valid_602559 = header.getOrDefault("X-Amz-Algorithm")
  valid_602559 = validateParameter(valid_602559, JString, required = false,
                                 default = nil)
  if valid_602559 != nil:
    section.add "X-Amz-Algorithm", valid_602559
  var valid_602560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602560 = validateParameter(valid_602560, JString, required = false,
                                 default = nil)
  if valid_602560 != nil:
    section.add "X-Amz-SignedHeaders", valid_602560
  result.add "header", section
  ## parameters in `formData` object:
  ##   nextToken: JString
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  section = newJObject()
  var valid_602561 = formData.getOrDefault("nextToken")
  valid_602561 = validateParameter(valid_602561, JString, required = false,
                                 default = nil)
  if valid_602561 != nil:
    section.add "nextToken", valid_602561
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602562: Call_PostListPhoneNumbersOptedOut_602549; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ## 
  let valid = call_602562.validator(path, query, header, formData, body)
  let scheme = call_602562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602562.url(scheme.get, call_602562.host, call_602562.base,
                         call_602562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602562, url, valid)

proc call*(call_602563: Call_PostListPhoneNumbersOptedOut_602549;
          nextToken: string = ""; Action: string = "ListPhoneNumbersOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## postListPhoneNumbersOptedOut
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ##   nextToken: string
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602564 = newJObject()
  var formData_602565 = newJObject()
  add(formData_602565, "nextToken", newJString(nextToken))
  add(query_602564, "Action", newJString(Action))
  add(query_602564, "Version", newJString(Version))
  result = call_602563.call(nil, query_602564, nil, formData_602565, nil)

var postListPhoneNumbersOptedOut* = Call_PostListPhoneNumbersOptedOut_602549(
    name: "postListPhoneNumbersOptedOut", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListPhoneNumbersOptedOut",
    validator: validate_PostListPhoneNumbersOptedOut_602550, base: "/",
    url: url_PostListPhoneNumbersOptedOut_602551,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPhoneNumbersOptedOut_602533 = ref object of OpenApiRestCall_601389
proc url_GetListPhoneNumbersOptedOut_602535(protocol: Scheme; host: string;
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

proc validate_GetListPhoneNumbersOptedOut_602534(path: JsonNode; query: JsonNode;
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
  var valid_602536 = query.getOrDefault("nextToken")
  valid_602536 = validateParameter(valid_602536, JString, required = false,
                                 default = nil)
  if valid_602536 != nil:
    section.add "nextToken", valid_602536
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602537 = query.getOrDefault("Action")
  valid_602537 = validateParameter(valid_602537, JString, required = true, default = newJString(
      "ListPhoneNumbersOptedOut"))
  if valid_602537 != nil:
    section.add "Action", valid_602537
  var valid_602538 = query.getOrDefault("Version")
  valid_602538 = validateParameter(valid_602538, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602538 != nil:
    section.add "Version", valid_602538
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602539 = header.getOrDefault("X-Amz-Signature")
  valid_602539 = validateParameter(valid_602539, JString, required = false,
                                 default = nil)
  if valid_602539 != nil:
    section.add "X-Amz-Signature", valid_602539
  var valid_602540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602540 = validateParameter(valid_602540, JString, required = false,
                                 default = nil)
  if valid_602540 != nil:
    section.add "X-Amz-Content-Sha256", valid_602540
  var valid_602541 = header.getOrDefault("X-Amz-Date")
  valid_602541 = validateParameter(valid_602541, JString, required = false,
                                 default = nil)
  if valid_602541 != nil:
    section.add "X-Amz-Date", valid_602541
  var valid_602542 = header.getOrDefault("X-Amz-Credential")
  valid_602542 = validateParameter(valid_602542, JString, required = false,
                                 default = nil)
  if valid_602542 != nil:
    section.add "X-Amz-Credential", valid_602542
  var valid_602543 = header.getOrDefault("X-Amz-Security-Token")
  valid_602543 = validateParameter(valid_602543, JString, required = false,
                                 default = nil)
  if valid_602543 != nil:
    section.add "X-Amz-Security-Token", valid_602543
  var valid_602544 = header.getOrDefault("X-Amz-Algorithm")
  valid_602544 = validateParameter(valid_602544, JString, required = false,
                                 default = nil)
  if valid_602544 != nil:
    section.add "X-Amz-Algorithm", valid_602544
  var valid_602545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602545 = validateParameter(valid_602545, JString, required = false,
                                 default = nil)
  if valid_602545 != nil:
    section.add "X-Amz-SignedHeaders", valid_602545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602546: Call_GetListPhoneNumbersOptedOut_602533; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ## 
  let valid = call_602546.validator(path, query, header, formData, body)
  let scheme = call_602546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602546.url(scheme.get, call_602546.host, call_602546.base,
                         call_602546.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602546, url, valid)

proc call*(call_602547: Call_GetListPhoneNumbersOptedOut_602533;
          nextToken: string = ""; Action: string = "ListPhoneNumbersOptedOut";
          Version: string = "2010-03-31"): Recallable =
  ## getListPhoneNumbersOptedOut
  ## <p>Returns a list of phone numbers that are opted out, meaning you cannot send SMS messages to them.</p> <p>The results for <code>ListPhoneNumbersOptedOut</code> are paginated, and each page returns up to 100 phone numbers. If additional phone numbers are available after the first page of results, then a <code>NextToken</code> string will be returned. To receive the next page, you call <code>ListPhoneNumbersOptedOut</code> again using the <code>NextToken</code> string received from the previous call. When there are no more records to return, <code>NextToken</code> will be null.</p>
  ##   nextToken: string
  ##            : A <code>NextToken</code> string is used when you call the <code>ListPhoneNumbersOptedOut</code> action to retrieve additional records that are available after the first page of results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602548 = newJObject()
  add(query_602548, "nextToken", newJString(nextToken))
  add(query_602548, "Action", newJString(Action))
  add(query_602548, "Version", newJString(Version))
  result = call_602547.call(nil, query_602548, nil, nil, nil)

var getListPhoneNumbersOptedOut* = Call_GetListPhoneNumbersOptedOut_602533(
    name: "getListPhoneNumbersOptedOut", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListPhoneNumbersOptedOut",
    validator: validate_GetListPhoneNumbersOptedOut_602534, base: "/",
    url: url_GetListPhoneNumbersOptedOut_602535,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPlatformApplications_602582 = ref object of OpenApiRestCall_601389
proc url_PostListPlatformApplications_602584(protocol: Scheme; host: string;
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

proc validate_PostListPlatformApplications_602583(path: JsonNode; query: JsonNode;
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
  var valid_602585 = query.getOrDefault("Action")
  valid_602585 = validateParameter(valid_602585, JString, required = true, default = newJString(
      "ListPlatformApplications"))
  if valid_602585 != nil:
    section.add "Action", valid_602585
  var valid_602586 = query.getOrDefault("Version")
  valid_602586 = validateParameter(valid_602586, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602586 != nil:
    section.add "Version", valid_602586
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602587 = header.getOrDefault("X-Amz-Signature")
  valid_602587 = validateParameter(valid_602587, JString, required = false,
                                 default = nil)
  if valid_602587 != nil:
    section.add "X-Amz-Signature", valid_602587
  var valid_602588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602588 = validateParameter(valid_602588, JString, required = false,
                                 default = nil)
  if valid_602588 != nil:
    section.add "X-Amz-Content-Sha256", valid_602588
  var valid_602589 = header.getOrDefault("X-Amz-Date")
  valid_602589 = validateParameter(valid_602589, JString, required = false,
                                 default = nil)
  if valid_602589 != nil:
    section.add "X-Amz-Date", valid_602589
  var valid_602590 = header.getOrDefault("X-Amz-Credential")
  valid_602590 = validateParameter(valid_602590, JString, required = false,
                                 default = nil)
  if valid_602590 != nil:
    section.add "X-Amz-Credential", valid_602590
  var valid_602591 = header.getOrDefault("X-Amz-Security-Token")
  valid_602591 = validateParameter(valid_602591, JString, required = false,
                                 default = nil)
  if valid_602591 != nil:
    section.add "X-Amz-Security-Token", valid_602591
  var valid_602592 = header.getOrDefault("X-Amz-Algorithm")
  valid_602592 = validateParameter(valid_602592, JString, required = false,
                                 default = nil)
  if valid_602592 != nil:
    section.add "X-Amz-Algorithm", valid_602592
  var valid_602593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602593 = validateParameter(valid_602593, JString, required = false,
                                 default = nil)
  if valid_602593 != nil:
    section.add "X-Amz-SignedHeaders", valid_602593
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  section = newJObject()
  var valid_602594 = formData.getOrDefault("NextToken")
  valid_602594 = validateParameter(valid_602594, JString, required = false,
                                 default = nil)
  if valid_602594 != nil:
    section.add "NextToken", valid_602594
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602595: Call_PostListPlatformApplications_602582; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and FCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  let valid = call_602595.validator(path, query, header, formData, body)
  let scheme = call_602595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602595.url(scheme.get, call_602595.host, call_602595.base,
                         call_602595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602595, url, valid)

proc call*(call_602596: Call_PostListPlatformApplications_602582;
          NextToken: string = ""; Action: string = "ListPlatformApplications";
          Version: string = "2010-03-31"): Recallable =
  ## postListPlatformApplications
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and FCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602597 = newJObject()
  var formData_602598 = newJObject()
  add(formData_602598, "NextToken", newJString(NextToken))
  add(query_602597, "Action", newJString(Action))
  add(query_602597, "Version", newJString(Version))
  result = call_602596.call(nil, query_602597, nil, formData_602598, nil)

var postListPlatformApplications* = Call_PostListPlatformApplications_602582(
    name: "postListPlatformApplications", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListPlatformApplications",
    validator: validate_PostListPlatformApplications_602583, base: "/",
    url: url_PostListPlatformApplications_602584,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPlatformApplications_602566 = ref object of OpenApiRestCall_601389
proc url_GetListPlatformApplications_602568(protocol: Scheme; host: string;
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

proc validate_GetListPlatformApplications_602567(path: JsonNode; query: JsonNode;
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
  var valid_602569 = query.getOrDefault("NextToken")
  valid_602569 = validateParameter(valid_602569, JString, required = false,
                                 default = nil)
  if valid_602569 != nil:
    section.add "NextToken", valid_602569
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602570 = query.getOrDefault("Action")
  valid_602570 = validateParameter(valid_602570, JString, required = true, default = newJString(
      "ListPlatformApplications"))
  if valid_602570 != nil:
    section.add "Action", valid_602570
  var valid_602571 = query.getOrDefault("Version")
  valid_602571 = validateParameter(valid_602571, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602571 != nil:
    section.add "Version", valid_602571
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602572 = header.getOrDefault("X-Amz-Signature")
  valid_602572 = validateParameter(valid_602572, JString, required = false,
                                 default = nil)
  if valid_602572 != nil:
    section.add "X-Amz-Signature", valid_602572
  var valid_602573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602573 = validateParameter(valid_602573, JString, required = false,
                                 default = nil)
  if valid_602573 != nil:
    section.add "X-Amz-Content-Sha256", valid_602573
  var valid_602574 = header.getOrDefault("X-Amz-Date")
  valid_602574 = validateParameter(valid_602574, JString, required = false,
                                 default = nil)
  if valid_602574 != nil:
    section.add "X-Amz-Date", valid_602574
  var valid_602575 = header.getOrDefault("X-Amz-Credential")
  valid_602575 = validateParameter(valid_602575, JString, required = false,
                                 default = nil)
  if valid_602575 != nil:
    section.add "X-Amz-Credential", valid_602575
  var valid_602576 = header.getOrDefault("X-Amz-Security-Token")
  valid_602576 = validateParameter(valid_602576, JString, required = false,
                                 default = nil)
  if valid_602576 != nil:
    section.add "X-Amz-Security-Token", valid_602576
  var valid_602577 = header.getOrDefault("X-Amz-Algorithm")
  valid_602577 = validateParameter(valid_602577, JString, required = false,
                                 default = nil)
  if valid_602577 != nil:
    section.add "X-Amz-Algorithm", valid_602577
  var valid_602578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602578 = validateParameter(valid_602578, JString, required = false,
                                 default = nil)
  if valid_602578 != nil:
    section.add "X-Amz-SignedHeaders", valid_602578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602579: Call_GetListPlatformApplications_602566; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and FCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ## 
  let valid = call_602579.validator(path, query, header, formData, body)
  let scheme = call_602579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602579.url(scheme.get, call_602579.host, call_602579.base,
                         call_602579.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602579, url, valid)

proc call*(call_602580: Call_GetListPlatformApplications_602566;
          NextToken: string = ""; Action: string = "ListPlatformApplications";
          Version: string = "2010-03-31"): Recallable =
  ## getListPlatformApplications
  ## <p>Lists the platform application objects for the supported push notification services, such as APNS and FCM. The results for <code>ListPlatformApplications</code> are paginated and return a limited list of applications, up to 100. If additional records are available after the first page results, then a NextToken string will be returned. To receive the next page, you call <code>ListPlatformApplications</code> using the NextToken string received from the previous call. When there are no more records to return, NextToken will be null. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. </p> <p>This action is throttled at 15 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : NextToken string is used when calling ListPlatformApplications action to retrieve additional records that are available after the first page results.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602581 = newJObject()
  add(query_602581, "NextToken", newJString(NextToken))
  add(query_602581, "Action", newJString(Action))
  add(query_602581, "Version", newJString(Version))
  result = call_602580.call(nil, query_602581, nil, nil, nil)

var getListPlatformApplications* = Call_GetListPlatformApplications_602566(
    name: "getListPlatformApplications", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListPlatformApplications",
    validator: validate_GetListPlatformApplications_602567, base: "/",
    url: url_GetListPlatformApplications_602568,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListSubscriptions_602615 = ref object of OpenApiRestCall_601389
proc url_PostListSubscriptions_602617(protocol: Scheme; host: string; base: string;
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

proc validate_PostListSubscriptions_602616(path: JsonNode; query: JsonNode;
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
  var valid_602618 = query.getOrDefault("Action")
  valid_602618 = validateParameter(valid_602618, JString, required = true,
                                 default = newJString("ListSubscriptions"))
  if valid_602618 != nil:
    section.add "Action", valid_602618
  var valid_602619 = query.getOrDefault("Version")
  valid_602619 = validateParameter(valid_602619, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602619 != nil:
    section.add "Version", valid_602619
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602620 = header.getOrDefault("X-Amz-Signature")
  valid_602620 = validateParameter(valid_602620, JString, required = false,
                                 default = nil)
  if valid_602620 != nil:
    section.add "X-Amz-Signature", valid_602620
  var valid_602621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602621 = validateParameter(valid_602621, JString, required = false,
                                 default = nil)
  if valid_602621 != nil:
    section.add "X-Amz-Content-Sha256", valid_602621
  var valid_602622 = header.getOrDefault("X-Amz-Date")
  valid_602622 = validateParameter(valid_602622, JString, required = false,
                                 default = nil)
  if valid_602622 != nil:
    section.add "X-Amz-Date", valid_602622
  var valid_602623 = header.getOrDefault("X-Amz-Credential")
  valid_602623 = validateParameter(valid_602623, JString, required = false,
                                 default = nil)
  if valid_602623 != nil:
    section.add "X-Amz-Credential", valid_602623
  var valid_602624 = header.getOrDefault("X-Amz-Security-Token")
  valid_602624 = validateParameter(valid_602624, JString, required = false,
                                 default = nil)
  if valid_602624 != nil:
    section.add "X-Amz-Security-Token", valid_602624
  var valid_602625 = header.getOrDefault("X-Amz-Algorithm")
  valid_602625 = validateParameter(valid_602625, JString, required = false,
                                 default = nil)
  if valid_602625 != nil:
    section.add "X-Amz-Algorithm", valid_602625
  var valid_602626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602626 = validateParameter(valid_602626, JString, required = false,
                                 default = nil)
  if valid_602626 != nil:
    section.add "X-Amz-SignedHeaders", valid_602626
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  section = newJObject()
  var valid_602627 = formData.getOrDefault("NextToken")
  valid_602627 = validateParameter(valid_602627, JString, required = false,
                                 default = nil)
  if valid_602627 != nil:
    section.add "NextToken", valid_602627
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602628: Call_PostListSubscriptions_602615; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_602628.validator(path, query, header, formData, body)
  let scheme = call_602628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602628.url(scheme.get, call_602628.host, call_602628.base,
                         call_602628.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602628, url, valid)

proc call*(call_602629: Call_PostListSubscriptions_602615; NextToken: string = "";
          Action: string = "ListSubscriptions"; Version: string = "2010-03-31"): Recallable =
  ## postListSubscriptions
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602630 = newJObject()
  var formData_602631 = newJObject()
  add(formData_602631, "NextToken", newJString(NextToken))
  add(query_602630, "Action", newJString(Action))
  add(query_602630, "Version", newJString(Version))
  result = call_602629.call(nil, query_602630, nil, formData_602631, nil)

var postListSubscriptions* = Call_PostListSubscriptions_602615(
    name: "postListSubscriptions", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptions",
    validator: validate_PostListSubscriptions_602616, base: "/",
    url: url_PostListSubscriptions_602617, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListSubscriptions_602599 = ref object of OpenApiRestCall_601389
proc url_GetListSubscriptions_602601(protocol: Scheme; host: string; base: string;
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

proc validate_GetListSubscriptions_602600(path: JsonNode; query: JsonNode;
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
  var valid_602602 = query.getOrDefault("NextToken")
  valid_602602 = validateParameter(valid_602602, JString, required = false,
                                 default = nil)
  if valid_602602 != nil:
    section.add "NextToken", valid_602602
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602603 = query.getOrDefault("Action")
  valid_602603 = validateParameter(valid_602603, JString, required = true,
                                 default = newJString("ListSubscriptions"))
  if valid_602603 != nil:
    section.add "Action", valid_602603
  var valid_602604 = query.getOrDefault("Version")
  valid_602604 = validateParameter(valid_602604, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602604 != nil:
    section.add "Version", valid_602604
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602605 = header.getOrDefault("X-Amz-Signature")
  valid_602605 = validateParameter(valid_602605, JString, required = false,
                                 default = nil)
  if valid_602605 != nil:
    section.add "X-Amz-Signature", valid_602605
  var valid_602606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602606 = validateParameter(valid_602606, JString, required = false,
                                 default = nil)
  if valid_602606 != nil:
    section.add "X-Amz-Content-Sha256", valid_602606
  var valid_602607 = header.getOrDefault("X-Amz-Date")
  valid_602607 = validateParameter(valid_602607, JString, required = false,
                                 default = nil)
  if valid_602607 != nil:
    section.add "X-Amz-Date", valid_602607
  var valid_602608 = header.getOrDefault("X-Amz-Credential")
  valid_602608 = validateParameter(valid_602608, JString, required = false,
                                 default = nil)
  if valid_602608 != nil:
    section.add "X-Amz-Credential", valid_602608
  var valid_602609 = header.getOrDefault("X-Amz-Security-Token")
  valid_602609 = validateParameter(valid_602609, JString, required = false,
                                 default = nil)
  if valid_602609 != nil:
    section.add "X-Amz-Security-Token", valid_602609
  var valid_602610 = header.getOrDefault("X-Amz-Algorithm")
  valid_602610 = validateParameter(valid_602610, JString, required = false,
                                 default = nil)
  if valid_602610 != nil:
    section.add "X-Amz-Algorithm", valid_602610
  var valid_602611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602611 = validateParameter(valid_602611, JString, required = false,
                                 default = nil)
  if valid_602611 != nil:
    section.add "X-Amz-SignedHeaders", valid_602611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602612: Call_GetListSubscriptions_602599; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_602612.validator(path, query, header, formData, body)
  let scheme = call_602612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602612.url(scheme.get, call_602612.host, call_602612.base,
                         call_602612.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602612, url, valid)

proc call*(call_602613: Call_GetListSubscriptions_602599; NextToken: string = "";
          Action: string = "ListSubscriptions"; Version: string = "2010-03-31"): Recallable =
  ## getListSubscriptions
  ## <p>Returns a list of the requester's subscriptions. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptions</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListSubscriptions</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602614 = newJObject()
  add(query_602614, "NextToken", newJString(NextToken))
  add(query_602614, "Action", newJString(Action))
  add(query_602614, "Version", newJString(Version))
  result = call_602613.call(nil, query_602614, nil, nil, nil)

var getListSubscriptions* = Call_GetListSubscriptions_602599(
    name: "getListSubscriptions", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptions",
    validator: validate_GetListSubscriptions_602600, base: "/",
    url: url_GetListSubscriptions_602601, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListSubscriptionsByTopic_602649 = ref object of OpenApiRestCall_601389
proc url_PostListSubscriptionsByTopic_602651(protocol: Scheme; host: string;
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

proc validate_PostListSubscriptionsByTopic_602650(path: JsonNode; query: JsonNode;
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
  var valid_602652 = query.getOrDefault("Action")
  valid_602652 = validateParameter(valid_602652, JString, required = true, default = newJString(
      "ListSubscriptionsByTopic"))
  if valid_602652 != nil:
    section.add "Action", valid_602652
  var valid_602653 = query.getOrDefault("Version")
  valid_602653 = validateParameter(valid_602653, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602653 != nil:
    section.add "Version", valid_602653
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602654 = header.getOrDefault("X-Amz-Signature")
  valid_602654 = validateParameter(valid_602654, JString, required = false,
                                 default = nil)
  if valid_602654 != nil:
    section.add "X-Amz-Signature", valid_602654
  var valid_602655 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602655 = validateParameter(valid_602655, JString, required = false,
                                 default = nil)
  if valid_602655 != nil:
    section.add "X-Amz-Content-Sha256", valid_602655
  var valid_602656 = header.getOrDefault("X-Amz-Date")
  valid_602656 = validateParameter(valid_602656, JString, required = false,
                                 default = nil)
  if valid_602656 != nil:
    section.add "X-Amz-Date", valid_602656
  var valid_602657 = header.getOrDefault("X-Amz-Credential")
  valid_602657 = validateParameter(valid_602657, JString, required = false,
                                 default = nil)
  if valid_602657 != nil:
    section.add "X-Amz-Credential", valid_602657
  var valid_602658 = header.getOrDefault("X-Amz-Security-Token")
  valid_602658 = validateParameter(valid_602658, JString, required = false,
                                 default = nil)
  if valid_602658 != nil:
    section.add "X-Amz-Security-Token", valid_602658
  var valid_602659 = header.getOrDefault("X-Amz-Algorithm")
  valid_602659 = validateParameter(valid_602659, JString, required = false,
                                 default = nil)
  if valid_602659 != nil:
    section.add "X-Amz-Algorithm", valid_602659
  var valid_602660 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602660 = validateParameter(valid_602660, JString, required = false,
                                 default = nil)
  if valid_602660 != nil:
    section.add "X-Amz-SignedHeaders", valid_602660
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListSubscriptionsByTopic</code> request.
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic for which you wish to find subscriptions.
  section = newJObject()
  var valid_602661 = formData.getOrDefault("NextToken")
  valid_602661 = validateParameter(valid_602661, JString, required = false,
                                 default = nil)
  if valid_602661 != nil:
    section.add "NextToken", valid_602661
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_602662 = formData.getOrDefault("TopicArn")
  valid_602662 = validateParameter(valid_602662, JString, required = true,
                                 default = nil)
  if valid_602662 != nil:
    section.add "TopicArn", valid_602662
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602663: Call_PostListSubscriptionsByTopic_602649; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_602663.validator(path, query, header, formData, body)
  let scheme = call_602663.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602663.url(scheme.get, call_602663.host, call_602663.base,
                         call_602663.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602663, url, valid)

proc call*(call_602664: Call_PostListSubscriptionsByTopic_602649; TopicArn: string;
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
  var query_602665 = newJObject()
  var formData_602666 = newJObject()
  add(formData_602666, "NextToken", newJString(NextToken))
  add(formData_602666, "TopicArn", newJString(TopicArn))
  add(query_602665, "Action", newJString(Action))
  add(query_602665, "Version", newJString(Version))
  result = call_602664.call(nil, query_602665, nil, formData_602666, nil)

var postListSubscriptionsByTopic* = Call_PostListSubscriptionsByTopic_602649(
    name: "postListSubscriptionsByTopic", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptionsByTopic",
    validator: validate_PostListSubscriptionsByTopic_602650, base: "/",
    url: url_PostListSubscriptionsByTopic_602651,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListSubscriptionsByTopic_602632 = ref object of OpenApiRestCall_601389
proc url_GetListSubscriptionsByTopic_602634(protocol: Scheme; host: string;
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

proc validate_GetListSubscriptionsByTopic_602633(path: JsonNode; query: JsonNode;
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
  var valid_602635 = query.getOrDefault("NextToken")
  valid_602635 = validateParameter(valid_602635, JString, required = false,
                                 default = nil)
  if valid_602635 != nil:
    section.add "NextToken", valid_602635
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602636 = query.getOrDefault("Action")
  valid_602636 = validateParameter(valid_602636, JString, required = true, default = newJString(
      "ListSubscriptionsByTopic"))
  if valid_602636 != nil:
    section.add "Action", valid_602636
  var valid_602637 = query.getOrDefault("Version")
  valid_602637 = validateParameter(valid_602637, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602637 != nil:
    section.add "Version", valid_602637
  var valid_602638 = query.getOrDefault("TopicArn")
  valid_602638 = validateParameter(valid_602638, JString, required = true,
                                 default = nil)
  if valid_602638 != nil:
    section.add "TopicArn", valid_602638
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602639 = header.getOrDefault("X-Amz-Signature")
  valid_602639 = validateParameter(valid_602639, JString, required = false,
                                 default = nil)
  if valid_602639 != nil:
    section.add "X-Amz-Signature", valid_602639
  var valid_602640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602640 = validateParameter(valid_602640, JString, required = false,
                                 default = nil)
  if valid_602640 != nil:
    section.add "X-Amz-Content-Sha256", valid_602640
  var valid_602641 = header.getOrDefault("X-Amz-Date")
  valid_602641 = validateParameter(valid_602641, JString, required = false,
                                 default = nil)
  if valid_602641 != nil:
    section.add "X-Amz-Date", valid_602641
  var valid_602642 = header.getOrDefault("X-Amz-Credential")
  valid_602642 = validateParameter(valid_602642, JString, required = false,
                                 default = nil)
  if valid_602642 != nil:
    section.add "X-Amz-Credential", valid_602642
  var valid_602643 = header.getOrDefault("X-Amz-Security-Token")
  valid_602643 = validateParameter(valid_602643, JString, required = false,
                                 default = nil)
  if valid_602643 != nil:
    section.add "X-Amz-Security-Token", valid_602643
  var valid_602644 = header.getOrDefault("X-Amz-Algorithm")
  valid_602644 = validateParameter(valid_602644, JString, required = false,
                                 default = nil)
  if valid_602644 != nil:
    section.add "X-Amz-Algorithm", valid_602644
  var valid_602645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602645 = validateParameter(valid_602645, JString, required = false,
                                 default = nil)
  if valid_602645 != nil:
    section.add "X-Amz-SignedHeaders", valid_602645
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602646: Call_GetListSubscriptionsByTopic_602632; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the subscriptions to a specific topic. Each call returns a limited list of subscriptions, up to 100. If there are more subscriptions, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListSubscriptionsByTopic</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_602646.validator(path, query, header, formData, body)
  let scheme = call_602646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602646.url(scheme.get, call_602646.host, call_602646.base,
                         call_602646.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602646, url, valid)

proc call*(call_602647: Call_GetListSubscriptionsByTopic_602632; TopicArn: string;
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
  var query_602648 = newJObject()
  add(query_602648, "NextToken", newJString(NextToken))
  add(query_602648, "Action", newJString(Action))
  add(query_602648, "Version", newJString(Version))
  add(query_602648, "TopicArn", newJString(TopicArn))
  result = call_602647.call(nil, query_602648, nil, nil, nil)

var getListSubscriptionsByTopic* = Call_GetListSubscriptionsByTopic_602632(
    name: "getListSubscriptionsByTopic", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListSubscriptionsByTopic",
    validator: validate_GetListSubscriptionsByTopic_602633, base: "/",
    url: url_GetListSubscriptionsByTopic_602634,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_602683 = ref object of OpenApiRestCall_601389
proc url_PostListTagsForResource_602685(protocol: Scheme; host: string; base: string;
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

proc validate_PostListTagsForResource_602684(path: JsonNode; query: JsonNode;
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
  var valid_602686 = query.getOrDefault("Action")
  valid_602686 = validateParameter(valid_602686, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_602686 != nil:
    section.add "Action", valid_602686
  var valid_602687 = query.getOrDefault("Version")
  valid_602687 = validateParameter(valid_602687, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602687 != nil:
    section.add "Version", valid_602687
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602688 = header.getOrDefault("X-Amz-Signature")
  valid_602688 = validateParameter(valid_602688, JString, required = false,
                                 default = nil)
  if valid_602688 != nil:
    section.add "X-Amz-Signature", valid_602688
  var valid_602689 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602689 = validateParameter(valid_602689, JString, required = false,
                                 default = nil)
  if valid_602689 != nil:
    section.add "X-Amz-Content-Sha256", valid_602689
  var valid_602690 = header.getOrDefault("X-Amz-Date")
  valid_602690 = validateParameter(valid_602690, JString, required = false,
                                 default = nil)
  if valid_602690 != nil:
    section.add "X-Amz-Date", valid_602690
  var valid_602691 = header.getOrDefault("X-Amz-Credential")
  valid_602691 = validateParameter(valid_602691, JString, required = false,
                                 default = nil)
  if valid_602691 != nil:
    section.add "X-Amz-Credential", valid_602691
  var valid_602692 = header.getOrDefault("X-Amz-Security-Token")
  valid_602692 = validateParameter(valid_602692, JString, required = false,
                                 default = nil)
  if valid_602692 != nil:
    section.add "X-Amz-Security-Token", valid_602692
  var valid_602693 = header.getOrDefault("X-Amz-Algorithm")
  valid_602693 = validateParameter(valid_602693, JString, required = false,
                                 default = nil)
  if valid_602693 != nil:
    section.add "X-Amz-Algorithm", valid_602693
  var valid_602694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602694 = validateParameter(valid_602694, JString, required = false,
                                 default = nil)
  if valid_602694 != nil:
    section.add "X-Amz-SignedHeaders", valid_602694
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic for which to list tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_602695 = formData.getOrDefault("ResourceArn")
  valid_602695 = validateParameter(valid_602695, JString, required = true,
                                 default = nil)
  if valid_602695 != nil:
    section.add "ResourceArn", valid_602695
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602696: Call_PostListTagsForResource_602683; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ## 
  let valid = call_602696.validator(path, query, header, formData, body)
  let scheme = call_602696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602696.url(scheme.get, call_602696.host, call_602696.base,
                         call_602696.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602696, url, valid)

proc call*(call_602697: Call_PostListTagsForResource_602683; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-03-31"): Recallable =
  ## postListTagsForResource
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic for which to list tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602698 = newJObject()
  var formData_602699 = newJObject()
  add(formData_602699, "ResourceArn", newJString(ResourceArn))
  add(query_602698, "Action", newJString(Action))
  add(query_602698, "Version", newJString(Version))
  result = call_602697.call(nil, query_602698, nil, formData_602699, nil)

var postListTagsForResource* = Call_PostListTagsForResource_602683(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_602684, base: "/",
    url: url_PostListTagsForResource_602685, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_602667 = ref object of OpenApiRestCall_601389
proc url_GetListTagsForResource_602669(protocol: Scheme; host: string; base: string;
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

proc validate_GetListTagsForResource_602668(path: JsonNode; query: JsonNode;
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
  var valid_602670 = query.getOrDefault("ResourceArn")
  valid_602670 = validateParameter(valid_602670, JString, required = true,
                                 default = nil)
  if valid_602670 != nil:
    section.add "ResourceArn", valid_602670
  var valid_602671 = query.getOrDefault("Action")
  valid_602671 = validateParameter(valid_602671, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_602671 != nil:
    section.add "Action", valid_602671
  var valid_602672 = query.getOrDefault("Version")
  valid_602672 = validateParameter(valid_602672, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602672 != nil:
    section.add "Version", valid_602672
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602673 = header.getOrDefault("X-Amz-Signature")
  valid_602673 = validateParameter(valid_602673, JString, required = false,
                                 default = nil)
  if valid_602673 != nil:
    section.add "X-Amz-Signature", valid_602673
  var valid_602674 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602674 = validateParameter(valid_602674, JString, required = false,
                                 default = nil)
  if valid_602674 != nil:
    section.add "X-Amz-Content-Sha256", valid_602674
  var valid_602675 = header.getOrDefault("X-Amz-Date")
  valid_602675 = validateParameter(valid_602675, JString, required = false,
                                 default = nil)
  if valid_602675 != nil:
    section.add "X-Amz-Date", valid_602675
  var valid_602676 = header.getOrDefault("X-Amz-Credential")
  valid_602676 = validateParameter(valid_602676, JString, required = false,
                                 default = nil)
  if valid_602676 != nil:
    section.add "X-Amz-Credential", valid_602676
  var valid_602677 = header.getOrDefault("X-Amz-Security-Token")
  valid_602677 = validateParameter(valid_602677, JString, required = false,
                                 default = nil)
  if valid_602677 != nil:
    section.add "X-Amz-Security-Token", valid_602677
  var valid_602678 = header.getOrDefault("X-Amz-Algorithm")
  valid_602678 = validateParameter(valid_602678, JString, required = false,
                                 default = nil)
  if valid_602678 != nil:
    section.add "X-Amz-Algorithm", valid_602678
  var valid_602679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602679 = validateParameter(valid_602679, JString, required = false,
                                 default = nil)
  if valid_602679 != nil:
    section.add "X-Amz-SignedHeaders", valid_602679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602680: Call_GetListTagsForResource_602667; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ## 
  let valid = call_602680.validator(path, query, header, formData, body)
  let scheme = call_602680.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602680.url(scheme.get, call_602680.host, call_602680.base,
                         call_602680.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602680, url, valid)

proc call*(call_602681: Call_GetListTagsForResource_602667; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-03-31"): Recallable =
  ## getListTagsForResource
  ## List all tags added to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon Simple Notification Service Developer Guide</i>.
  ##   ResourceArn: string (required)
  ##              : The ARN of the topic for which to list tags.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602682 = newJObject()
  add(query_602682, "ResourceArn", newJString(ResourceArn))
  add(query_602682, "Action", newJString(Action))
  add(query_602682, "Version", newJString(Version))
  result = call_602681.call(nil, query_602682, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_602667(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_602668, base: "/",
    url: url_GetListTagsForResource_602669, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTopics_602716 = ref object of OpenApiRestCall_601389
proc url_PostListTopics_602718(protocol: Scheme; host: string; base: string;
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

proc validate_PostListTopics_602717(path: JsonNode; query: JsonNode;
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
  var valid_602719 = query.getOrDefault("Action")
  valid_602719 = validateParameter(valid_602719, JString, required = true,
                                 default = newJString("ListTopics"))
  if valid_602719 != nil:
    section.add "Action", valid_602719
  var valid_602720 = query.getOrDefault("Version")
  valid_602720 = validateParameter(valid_602720, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602720 != nil:
    section.add "Version", valid_602720
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602721 = header.getOrDefault("X-Amz-Signature")
  valid_602721 = validateParameter(valid_602721, JString, required = false,
                                 default = nil)
  if valid_602721 != nil:
    section.add "X-Amz-Signature", valid_602721
  var valid_602722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602722 = validateParameter(valid_602722, JString, required = false,
                                 default = nil)
  if valid_602722 != nil:
    section.add "X-Amz-Content-Sha256", valid_602722
  var valid_602723 = header.getOrDefault("X-Amz-Date")
  valid_602723 = validateParameter(valid_602723, JString, required = false,
                                 default = nil)
  if valid_602723 != nil:
    section.add "X-Amz-Date", valid_602723
  var valid_602724 = header.getOrDefault("X-Amz-Credential")
  valid_602724 = validateParameter(valid_602724, JString, required = false,
                                 default = nil)
  if valid_602724 != nil:
    section.add "X-Amz-Credential", valid_602724
  var valid_602725 = header.getOrDefault("X-Amz-Security-Token")
  valid_602725 = validateParameter(valid_602725, JString, required = false,
                                 default = nil)
  if valid_602725 != nil:
    section.add "X-Amz-Security-Token", valid_602725
  var valid_602726 = header.getOrDefault("X-Amz-Algorithm")
  valid_602726 = validateParameter(valid_602726, JString, required = false,
                                 default = nil)
  if valid_602726 != nil:
    section.add "X-Amz-Algorithm", valid_602726
  var valid_602727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602727 = validateParameter(valid_602727, JString, required = false,
                                 default = nil)
  if valid_602727 != nil:
    section.add "X-Amz-SignedHeaders", valid_602727
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Token returned by the previous <code>ListTopics</code> request.
  section = newJObject()
  var valid_602728 = formData.getOrDefault("NextToken")
  valid_602728 = validateParameter(valid_602728, JString, required = false,
                                 default = nil)
  if valid_602728 != nil:
    section.add "NextToken", valid_602728
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602729: Call_PostListTopics_602716; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_602729.validator(path, query, header, formData, body)
  let scheme = call_602729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602729.url(scheme.get, call_602729.host, call_602729.base,
                         call_602729.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602729, url, valid)

proc call*(call_602730: Call_PostListTopics_602716; NextToken: string = "";
          Action: string = "ListTopics"; Version: string = "2010-03-31"): Recallable =
  ## postListTopics
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListTopics</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602731 = newJObject()
  var formData_602732 = newJObject()
  add(formData_602732, "NextToken", newJString(NextToken))
  add(query_602731, "Action", newJString(Action))
  add(query_602731, "Version", newJString(Version))
  result = call_602730.call(nil, query_602731, nil, formData_602732, nil)

var postListTopics* = Call_PostListTopics_602716(name: "postListTopics",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=ListTopics", validator: validate_PostListTopics_602717,
    base: "/", url: url_PostListTopics_602718, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTopics_602700 = ref object of OpenApiRestCall_601389
proc url_GetListTopics_602702(protocol: Scheme; host: string; base: string;
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

proc validate_GetListTopics_602701(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602703 = query.getOrDefault("NextToken")
  valid_602703 = validateParameter(valid_602703, JString, required = false,
                                 default = nil)
  if valid_602703 != nil:
    section.add "NextToken", valid_602703
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602704 = query.getOrDefault("Action")
  valid_602704 = validateParameter(valid_602704, JString, required = true,
                                 default = newJString("ListTopics"))
  if valid_602704 != nil:
    section.add "Action", valid_602704
  var valid_602705 = query.getOrDefault("Version")
  valid_602705 = validateParameter(valid_602705, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602705 != nil:
    section.add "Version", valid_602705
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602706 = header.getOrDefault("X-Amz-Signature")
  valid_602706 = validateParameter(valid_602706, JString, required = false,
                                 default = nil)
  if valid_602706 != nil:
    section.add "X-Amz-Signature", valid_602706
  var valid_602707 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602707 = validateParameter(valid_602707, JString, required = false,
                                 default = nil)
  if valid_602707 != nil:
    section.add "X-Amz-Content-Sha256", valid_602707
  var valid_602708 = header.getOrDefault("X-Amz-Date")
  valid_602708 = validateParameter(valid_602708, JString, required = false,
                                 default = nil)
  if valid_602708 != nil:
    section.add "X-Amz-Date", valid_602708
  var valid_602709 = header.getOrDefault("X-Amz-Credential")
  valid_602709 = validateParameter(valid_602709, JString, required = false,
                                 default = nil)
  if valid_602709 != nil:
    section.add "X-Amz-Credential", valid_602709
  var valid_602710 = header.getOrDefault("X-Amz-Security-Token")
  valid_602710 = validateParameter(valid_602710, JString, required = false,
                                 default = nil)
  if valid_602710 != nil:
    section.add "X-Amz-Security-Token", valid_602710
  var valid_602711 = header.getOrDefault("X-Amz-Algorithm")
  valid_602711 = validateParameter(valid_602711, JString, required = false,
                                 default = nil)
  if valid_602711 != nil:
    section.add "X-Amz-Algorithm", valid_602711
  var valid_602712 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602712 = validateParameter(valid_602712, JString, required = false,
                                 default = nil)
  if valid_602712 != nil:
    section.add "X-Amz-SignedHeaders", valid_602712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602713: Call_GetListTopics_602700; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ## 
  let valid = call_602713.validator(path, query, header, formData, body)
  let scheme = call_602713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602713.url(scheme.get, call_602713.host, call_602713.base,
                         call_602713.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602713, url, valid)

proc call*(call_602714: Call_GetListTopics_602700; NextToken: string = "";
          Action: string = "ListTopics"; Version: string = "2010-03-31"): Recallable =
  ## getListTopics
  ## <p>Returns a list of the requester's topics. Each call returns a limited list of topics, up to 100. If there are more topics, a <code>NextToken</code> is also returned. Use the <code>NextToken</code> parameter in a new <code>ListTopics</code> call to get further results.</p> <p>This action is throttled at 30 transactions per second (TPS).</p>
  ##   NextToken: string
  ##            : Token returned by the previous <code>ListTopics</code> request.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602715 = newJObject()
  add(query_602715, "NextToken", newJString(NextToken))
  add(query_602715, "Action", newJString(Action))
  add(query_602715, "Version", newJString(Version))
  result = call_602714.call(nil, query_602715, nil, nil, nil)

var getListTopics* = Call_GetListTopics_602700(name: "getListTopics",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=ListTopics", validator: validate_GetListTopics_602701,
    base: "/", url: url_GetListTopics_602702, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostOptInPhoneNumber_602749 = ref object of OpenApiRestCall_601389
proc url_PostOptInPhoneNumber_602751(protocol: Scheme; host: string; base: string;
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

proc validate_PostOptInPhoneNumber_602750(path: JsonNode; query: JsonNode;
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
  var valid_602752 = query.getOrDefault("Action")
  valid_602752 = validateParameter(valid_602752, JString, required = true,
                                 default = newJString("OptInPhoneNumber"))
  if valid_602752 != nil:
    section.add "Action", valid_602752
  var valid_602753 = query.getOrDefault("Version")
  valid_602753 = validateParameter(valid_602753, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602753 != nil:
    section.add "Version", valid_602753
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602754 = header.getOrDefault("X-Amz-Signature")
  valid_602754 = validateParameter(valid_602754, JString, required = false,
                                 default = nil)
  if valid_602754 != nil:
    section.add "X-Amz-Signature", valid_602754
  var valid_602755 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602755 = validateParameter(valid_602755, JString, required = false,
                                 default = nil)
  if valid_602755 != nil:
    section.add "X-Amz-Content-Sha256", valid_602755
  var valid_602756 = header.getOrDefault("X-Amz-Date")
  valid_602756 = validateParameter(valid_602756, JString, required = false,
                                 default = nil)
  if valid_602756 != nil:
    section.add "X-Amz-Date", valid_602756
  var valid_602757 = header.getOrDefault("X-Amz-Credential")
  valid_602757 = validateParameter(valid_602757, JString, required = false,
                                 default = nil)
  if valid_602757 != nil:
    section.add "X-Amz-Credential", valid_602757
  var valid_602758 = header.getOrDefault("X-Amz-Security-Token")
  valid_602758 = validateParameter(valid_602758, JString, required = false,
                                 default = nil)
  if valid_602758 != nil:
    section.add "X-Amz-Security-Token", valid_602758
  var valid_602759 = header.getOrDefault("X-Amz-Algorithm")
  valid_602759 = validateParameter(valid_602759, JString, required = false,
                                 default = nil)
  if valid_602759 != nil:
    section.add "X-Amz-Algorithm", valid_602759
  var valid_602760 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602760 = validateParameter(valid_602760, JString, required = false,
                                 default = nil)
  if valid_602760 != nil:
    section.add "X-Amz-SignedHeaders", valid_602760
  result.add "header", section
  ## parameters in `formData` object:
  ##   phoneNumber: JString (required)
  ##              : The phone number to opt in.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `phoneNumber` field"
  var valid_602761 = formData.getOrDefault("phoneNumber")
  valid_602761 = validateParameter(valid_602761, JString, required = true,
                                 default = nil)
  if valid_602761 != nil:
    section.add "phoneNumber", valid_602761
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602762: Call_PostOptInPhoneNumber_602749; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ## 
  let valid = call_602762.validator(path, query, header, formData, body)
  let scheme = call_602762.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602762.url(scheme.get, call_602762.host, call_602762.base,
                         call_602762.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602762, url, valid)

proc call*(call_602763: Call_PostOptInPhoneNumber_602749; phoneNumber: string;
          Action: string = "OptInPhoneNumber"; Version: string = "2010-03-31"): Recallable =
  ## postOptInPhoneNumber
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number to opt in.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602764 = newJObject()
  var formData_602765 = newJObject()
  add(formData_602765, "phoneNumber", newJString(phoneNumber))
  add(query_602764, "Action", newJString(Action))
  add(query_602764, "Version", newJString(Version))
  result = call_602763.call(nil, query_602764, nil, formData_602765, nil)

var postOptInPhoneNumber* = Call_PostOptInPhoneNumber_602749(
    name: "postOptInPhoneNumber", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=OptInPhoneNumber",
    validator: validate_PostOptInPhoneNumber_602750, base: "/",
    url: url_PostOptInPhoneNumber_602751, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOptInPhoneNumber_602733 = ref object of OpenApiRestCall_601389
proc url_GetOptInPhoneNumber_602735(protocol: Scheme; host: string; base: string;
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

proc validate_GetOptInPhoneNumber_602734(path: JsonNode; query: JsonNode;
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
  var valid_602736 = query.getOrDefault("phoneNumber")
  valid_602736 = validateParameter(valid_602736, JString, required = true,
                                 default = nil)
  if valid_602736 != nil:
    section.add "phoneNumber", valid_602736
  var valid_602737 = query.getOrDefault("Action")
  valid_602737 = validateParameter(valid_602737, JString, required = true,
                                 default = newJString("OptInPhoneNumber"))
  if valid_602737 != nil:
    section.add "Action", valid_602737
  var valid_602738 = query.getOrDefault("Version")
  valid_602738 = validateParameter(valid_602738, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602738 != nil:
    section.add "Version", valid_602738
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602739 = header.getOrDefault("X-Amz-Signature")
  valid_602739 = validateParameter(valid_602739, JString, required = false,
                                 default = nil)
  if valid_602739 != nil:
    section.add "X-Amz-Signature", valid_602739
  var valid_602740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602740 = validateParameter(valid_602740, JString, required = false,
                                 default = nil)
  if valid_602740 != nil:
    section.add "X-Amz-Content-Sha256", valid_602740
  var valid_602741 = header.getOrDefault("X-Amz-Date")
  valid_602741 = validateParameter(valid_602741, JString, required = false,
                                 default = nil)
  if valid_602741 != nil:
    section.add "X-Amz-Date", valid_602741
  var valid_602742 = header.getOrDefault("X-Amz-Credential")
  valid_602742 = validateParameter(valid_602742, JString, required = false,
                                 default = nil)
  if valid_602742 != nil:
    section.add "X-Amz-Credential", valid_602742
  var valid_602743 = header.getOrDefault("X-Amz-Security-Token")
  valid_602743 = validateParameter(valid_602743, JString, required = false,
                                 default = nil)
  if valid_602743 != nil:
    section.add "X-Amz-Security-Token", valid_602743
  var valid_602744 = header.getOrDefault("X-Amz-Algorithm")
  valid_602744 = validateParameter(valid_602744, JString, required = false,
                                 default = nil)
  if valid_602744 != nil:
    section.add "X-Amz-Algorithm", valid_602744
  var valid_602745 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602745 = validateParameter(valid_602745, JString, required = false,
                                 default = nil)
  if valid_602745 != nil:
    section.add "X-Amz-SignedHeaders", valid_602745
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602746: Call_GetOptInPhoneNumber_602733; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ## 
  let valid = call_602746.validator(path, query, header, formData, body)
  let scheme = call_602746.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602746.url(scheme.get, call_602746.host, call_602746.base,
                         call_602746.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602746, url, valid)

proc call*(call_602747: Call_GetOptInPhoneNumber_602733; phoneNumber: string;
          Action: string = "OptInPhoneNumber"; Version: string = "2010-03-31"): Recallable =
  ## getOptInPhoneNumber
  ## <p>Use this request to opt in a phone number that is opted out, which enables you to resume sending SMS messages to the number.</p> <p>You can opt in a phone number only once every 30 days.</p>
  ##   phoneNumber: string (required)
  ##              : The phone number to opt in.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602748 = newJObject()
  add(query_602748, "phoneNumber", newJString(phoneNumber))
  add(query_602748, "Action", newJString(Action))
  add(query_602748, "Version", newJString(Version))
  result = call_602747.call(nil, query_602748, nil, nil, nil)

var getOptInPhoneNumber* = Call_GetOptInPhoneNumber_602733(
    name: "getOptInPhoneNumber", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=OptInPhoneNumber",
    validator: validate_GetOptInPhoneNumber_602734, base: "/",
    url: url_GetOptInPhoneNumber_602735, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPublish_602793 = ref object of OpenApiRestCall_601389
proc url_PostPublish_602795(protocol: Scheme; host: string; base: string;
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

proc validate_PostPublish_602794(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602796 = query.getOrDefault("Action")
  valid_602796 = validateParameter(valid_602796, JString, required = true,
                                 default = newJString("Publish"))
  if valid_602796 != nil:
    section.add "Action", valid_602796
  var valid_602797 = query.getOrDefault("Version")
  valid_602797 = validateParameter(valid_602797, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602797 != nil:
    section.add "Version", valid_602797
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602798 = header.getOrDefault("X-Amz-Signature")
  valid_602798 = validateParameter(valid_602798, JString, required = false,
                                 default = nil)
  if valid_602798 != nil:
    section.add "X-Amz-Signature", valid_602798
  var valid_602799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602799 = validateParameter(valid_602799, JString, required = false,
                                 default = nil)
  if valid_602799 != nil:
    section.add "X-Amz-Content-Sha256", valid_602799
  var valid_602800 = header.getOrDefault("X-Amz-Date")
  valid_602800 = validateParameter(valid_602800, JString, required = false,
                                 default = nil)
  if valid_602800 != nil:
    section.add "X-Amz-Date", valid_602800
  var valid_602801 = header.getOrDefault("X-Amz-Credential")
  valid_602801 = validateParameter(valid_602801, JString, required = false,
                                 default = nil)
  if valid_602801 != nil:
    section.add "X-Amz-Credential", valid_602801
  var valid_602802 = header.getOrDefault("X-Amz-Security-Token")
  valid_602802 = validateParameter(valid_602802, JString, required = false,
                                 default = nil)
  if valid_602802 != nil:
    section.add "X-Amz-Security-Token", valid_602802
  var valid_602803 = header.getOrDefault("X-Amz-Algorithm")
  valid_602803 = validateParameter(valid_602803, JString, required = false,
                                 default = nil)
  if valid_602803 != nil:
    section.add "X-Amz-Algorithm", valid_602803
  var valid_602804 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602804 = validateParameter(valid_602804, JString, required = false,
                                 default = nil)
  if valid_602804 != nil:
    section.add "X-Amz-SignedHeaders", valid_602804
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
  var valid_602805 = formData.getOrDefault("MessageAttributes.1.key")
  valid_602805 = validateParameter(valid_602805, JString, required = false,
                                 default = nil)
  if valid_602805 != nil:
    section.add "MessageAttributes.1.key", valid_602805
  var valid_602806 = formData.getOrDefault("PhoneNumber")
  valid_602806 = validateParameter(valid_602806, JString, required = false,
                                 default = nil)
  if valid_602806 != nil:
    section.add "PhoneNumber", valid_602806
  var valid_602807 = formData.getOrDefault("MessageAttributes.2.value")
  valid_602807 = validateParameter(valid_602807, JString, required = false,
                                 default = nil)
  if valid_602807 != nil:
    section.add "MessageAttributes.2.value", valid_602807
  var valid_602808 = formData.getOrDefault("Subject")
  valid_602808 = validateParameter(valid_602808, JString, required = false,
                                 default = nil)
  if valid_602808 != nil:
    section.add "Subject", valid_602808
  var valid_602809 = formData.getOrDefault("MessageAttributes.0.value")
  valid_602809 = validateParameter(valid_602809, JString, required = false,
                                 default = nil)
  if valid_602809 != nil:
    section.add "MessageAttributes.0.value", valid_602809
  var valid_602810 = formData.getOrDefault("MessageAttributes.0.key")
  valid_602810 = validateParameter(valid_602810, JString, required = false,
                                 default = nil)
  if valid_602810 != nil:
    section.add "MessageAttributes.0.key", valid_602810
  var valid_602811 = formData.getOrDefault("MessageAttributes.2.key")
  valid_602811 = validateParameter(valid_602811, JString, required = false,
                                 default = nil)
  if valid_602811 != nil:
    section.add "MessageAttributes.2.key", valid_602811
  assert formData != nil,
        "formData argument is necessary due to required `Message` field"
  var valid_602812 = formData.getOrDefault("Message")
  valid_602812 = validateParameter(valid_602812, JString, required = true,
                                 default = nil)
  if valid_602812 != nil:
    section.add "Message", valid_602812
  var valid_602813 = formData.getOrDefault("TopicArn")
  valid_602813 = validateParameter(valid_602813, JString, required = false,
                                 default = nil)
  if valid_602813 != nil:
    section.add "TopicArn", valid_602813
  var valid_602814 = formData.getOrDefault("MessageStructure")
  valid_602814 = validateParameter(valid_602814, JString, required = false,
                                 default = nil)
  if valid_602814 != nil:
    section.add "MessageStructure", valid_602814
  var valid_602815 = formData.getOrDefault("MessageAttributes.1.value")
  valid_602815 = validateParameter(valid_602815, JString, required = false,
                                 default = nil)
  if valid_602815 != nil:
    section.add "MessageAttributes.1.value", valid_602815
  var valid_602816 = formData.getOrDefault("TargetArn")
  valid_602816 = validateParameter(valid_602816, JString, required = false,
                                 default = nil)
  if valid_602816 != nil:
    section.add "TargetArn", valid_602816
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602817: Call_PostPublish_602793; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  let valid = call_602817.validator(path, query, header, formData, body)
  let scheme = call_602817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602817.url(scheme.get, call_602817.host, call_602817.base,
                         call_602817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602817, url, valid)

proc call*(call_602818: Call_PostPublish_602793; Message: string;
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
  var query_602819 = newJObject()
  var formData_602820 = newJObject()
  add(formData_602820, "MessageAttributes.1.key",
      newJString(MessageAttributes1Key))
  add(formData_602820, "PhoneNumber", newJString(PhoneNumber))
  add(formData_602820, "MessageAttributes.2.value",
      newJString(MessageAttributes2Value))
  add(formData_602820, "Subject", newJString(Subject))
  add(formData_602820, "MessageAttributes.0.value",
      newJString(MessageAttributes0Value))
  add(formData_602820, "MessageAttributes.0.key",
      newJString(MessageAttributes0Key))
  add(formData_602820, "MessageAttributes.2.key",
      newJString(MessageAttributes2Key))
  add(formData_602820, "Message", newJString(Message))
  add(formData_602820, "TopicArn", newJString(TopicArn))
  add(query_602819, "Action", newJString(Action))
  add(formData_602820, "MessageStructure", newJString(MessageStructure))
  add(formData_602820, "MessageAttributes.1.value",
      newJString(MessageAttributes1Value))
  add(formData_602820, "TargetArn", newJString(TargetArn))
  add(query_602819, "Version", newJString(Version))
  result = call_602818.call(nil, query_602819, nil, formData_602820, nil)

var postPublish* = Call_PostPublish_602793(name: "postPublish",
                                        meth: HttpMethod.HttpPost,
                                        host: "sns.amazonaws.com",
                                        route: "/#Action=Publish",
                                        validator: validate_PostPublish_602794,
                                        base: "/", url: url_PostPublish_602795,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublish_602766 = ref object of OpenApiRestCall_601389
proc url_GetPublish_602768(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetPublish_602767(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602769 = query.getOrDefault("PhoneNumber")
  valid_602769 = validateParameter(valid_602769, JString, required = false,
                                 default = nil)
  if valid_602769 != nil:
    section.add "PhoneNumber", valid_602769
  var valid_602770 = query.getOrDefault("MessageStructure")
  valid_602770 = validateParameter(valid_602770, JString, required = false,
                                 default = nil)
  if valid_602770 != nil:
    section.add "MessageStructure", valid_602770
  var valid_602771 = query.getOrDefault("MessageAttributes.0.value")
  valid_602771 = validateParameter(valid_602771, JString, required = false,
                                 default = nil)
  if valid_602771 != nil:
    section.add "MessageAttributes.0.value", valid_602771
  var valid_602772 = query.getOrDefault("MessageAttributes.2.key")
  valid_602772 = validateParameter(valid_602772, JString, required = false,
                                 default = nil)
  if valid_602772 != nil:
    section.add "MessageAttributes.2.key", valid_602772
  assert query != nil, "query argument is necessary due to required `Message` field"
  var valid_602773 = query.getOrDefault("Message")
  valid_602773 = validateParameter(valid_602773, JString, required = true,
                                 default = nil)
  if valid_602773 != nil:
    section.add "Message", valid_602773
  var valid_602774 = query.getOrDefault("MessageAttributes.2.value")
  valid_602774 = validateParameter(valid_602774, JString, required = false,
                                 default = nil)
  if valid_602774 != nil:
    section.add "MessageAttributes.2.value", valid_602774
  var valid_602775 = query.getOrDefault("Action")
  valid_602775 = validateParameter(valid_602775, JString, required = true,
                                 default = newJString("Publish"))
  if valid_602775 != nil:
    section.add "Action", valid_602775
  var valid_602776 = query.getOrDefault("MessageAttributes.1.key")
  valid_602776 = validateParameter(valid_602776, JString, required = false,
                                 default = nil)
  if valid_602776 != nil:
    section.add "MessageAttributes.1.key", valid_602776
  var valid_602777 = query.getOrDefault("MessageAttributes.0.key")
  valid_602777 = validateParameter(valid_602777, JString, required = false,
                                 default = nil)
  if valid_602777 != nil:
    section.add "MessageAttributes.0.key", valid_602777
  var valid_602778 = query.getOrDefault("Subject")
  valid_602778 = validateParameter(valid_602778, JString, required = false,
                                 default = nil)
  if valid_602778 != nil:
    section.add "Subject", valid_602778
  var valid_602779 = query.getOrDefault("MessageAttributes.1.value")
  valid_602779 = validateParameter(valid_602779, JString, required = false,
                                 default = nil)
  if valid_602779 != nil:
    section.add "MessageAttributes.1.value", valid_602779
  var valid_602780 = query.getOrDefault("Version")
  valid_602780 = validateParameter(valid_602780, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602780 != nil:
    section.add "Version", valid_602780
  var valid_602781 = query.getOrDefault("TargetArn")
  valid_602781 = validateParameter(valid_602781, JString, required = false,
                                 default = nil)
  if valid_602781 != nil:
    section.add "TargetArn", valid_602781
  var valid_602782 = query.getOrDefault("TopicArn")
  valid_602782 = validateParameter(valid_602782, JString, required = false,
                                 default = nil)
  if valid_602782 != nil:
    section.add "TopicArn", valid_602782
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602783 = header.getOrDefault("X-Amz-Signature")
  valid_602783 = validateParameter(valid_602783, JString, required = false,
                                 default = nil)
  if valid_602783 != nil:
    section.add "X-Amz-Signature", valid_602783
  var valid_602784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602784 = validateParameter(valid_602784, JString, required = false,
                                 default = nil)
  if valid_602784 != nil:
    section.add "X-Amz-Content-Sha256", valid_602784
  var valid_602785 = header.getOrDefault("X-Amz-Date")
  valid_602785 = validateParameter(valid_602785, JString, required = false,
                                 default = nil)
  if valid_602785 != nil:
    section.add "X-Amz-Date", valid_602785
  var valid_602786 = header.getOrDefault("X-Amz-Credential")
  valid_602786 = validateParameter(valid_602786, JString, required = false,
                                 default = nil)
  if valid_602786 != nil:
    section.add "X-Amz-Credential", valid_602786
  var valid_602787 = header.getOrDefault("X-Amz-Security-Token")
  valid_602787 = validateParameter(valid_602787, JString, required = false,
                                 default = nil)
  if valid_602787 != nil:
    section.add "X-Amz-Security-Token", valid_602787
  var valid_602788 = header.getOrDefault("X-Amz-Algorithm")
  valid_602788 = validateParameter(valid_602788, JString, required = false,
                                 default = nil)
  if valid_602788 != nil:
    section.add "X-Amz-Algorithm", valid_602788
  var valid_602789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602789 = validateParameter(valid_602789, JString, required = false,
                                 default = nil)
  if valid_602789 != nil:
    section.add "X-Amz-SignedHeaders", valid_602789
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602790: Call_GetPublish_602766; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends a message to an Amazon SNS topic or sends a text message (SMS message) directly to a phone number. </p> <p>If you send a message to a topic, Amazon SNS delivers the message to each endpoint that is subscribed to the topic. The format of the message depends on the notification protocol for each subscribed endpoint.</p> <p>When a <code>messageId</code> is returned, the message has been saved and Amazon SNS will attempt to deliver it shortly.</p> <p>To use the <code>Publish</code> action for sending a message to a mobile endpoint, such as an app on a Kindle device or mobile phone, you must specify the EndpointArn for the TargetArn parameter. The EndpointArn is returned when making a call with the <code>CreatePlatformEndpoint</code> action. </p> <p>For more information about formatting messages, see <a href="https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-custommessage.html">Send Custom Platform-Specific Payloads in Messages to Mobile Devices</a>. </p>
  ## 
  let valid = call_602790.validator(path, query, header, formData, body)
  let scheme = call_602790.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602790.url(scheme.get, call_602790.host, call_602790.base,
                         call_602790.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602790, url, valid)

proc call*(call_602791: Call_GetPublish_602766; Message: string;
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
  var query_602792 = newJObject()
  add(query_602792, "PhoneNumber", newJString(PhoneNumber))
  add(query_602792, "MessageStructure", newJString(MessageStructure))
  add(query_602792, "MessageAttributes.0.value",
      newJString(MessageAttributes0Value))
  add(query_602792, "MessageAttributes.2.key", newJString(MessageAttributes2Key))
  add(query_602792, "Message", newJString(Message))
  add(query_602792, "MessageAttributes.2.value",
      newJString(MessageAttributes2Value))
  add(query_602792, "Action", newJString(Action))
  add(query_602792, "MessageAttributes.1.key", newJString(MessageAttributes1Key))
  add(query_602792, "MessageAttributes.0.key", newJString(MessageAttributes0Key))
  add(query_602792, "Subject", newJString(Subject))
  add(query_602792, "MessageAttributes.1.value",
      newJString(MessageAttributes1Value))
  add(query_602792, "Version", newJString(Version))
  add(query_602792, "TargetArn", newJString(TargetArn))
  add(query_602792, "TopicArn", newJString(TopicArn))
  result = call_602791.call(nil, query_602792, nil, nil, nil)

var getPublish* = Call_GetPublish_602766(name: "getPublish",
                                      meth: HttpMethod.HttpGet,
                                      host: "sns.amazonaws.com",
                                      route: "/#Action=Publish",
                                      validator: validate_GetPublish_602767,
                                      base: "/", url: url_GetPublish_602768,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemovePermission_602838 = ref object of OpenApiRestCall_601389
proc url_PostRemovePermission_602840(protocol: Scheme; host: string; base: string;
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

proc validate_PostRemovePermission_602839(path: JsonNode; query: JsonNode;
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
  var valid_602841 = query.getOrDefault("Action")
  valid_602841 = validateParameter(valid_602841, JString, required = true,
                                 default = newJString("RemovePermission"))
  if valid_602841 != nil:
    section.add "Action", valid_602841
  var valid_602842 = query.getOrDefault("Version")
  valid_602842 = validateParameter(valid_602842, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602842 != nil:
    section.add "Version", valid_602842
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602843 = header.getOrDefault("X-Amz-Signature")
  valid_602843 = validateParameter(valid_602843, JString, required = false,
                                 default = nil)
  if valid_602843 != nil:
    section.add "X-Amz-Signature", valid_602843
  var valid_602844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602844 = validateParameter(valid_602844, JString, required = false,
                                 default = nil)
  if valid_602844 != nil:
    section.add "X-Amz-Content-Sha256", valid_602844
  var valid_602845 = header.getOrDefault("X-Amz-Date")
  valid_602845 = validateParameter(valid_602845, JString, required = false,
                                 default = nil)
  if valid_602845 != nil:
    section.add "X-Amz-Date", valid_602845
  var valid_602846 = header.getOrDefault("X-Amz-Credential")
  valid_602846 = validateParameter(valid_602846, JString, required = false,
                                 default = nil)
  if valid_602846 != nil:
    section.add "X-Amz-Credential", valid_602846
  var valid_602847 = header.getOrDefault("X-Amz-Security-Token")
  valid_602847 = validateParameter(valid_602847, JString, required = false,
                                 default = nil)
  if valid_602847 != nil:
    section.add "X-Amz-Security-Token", valid_602847
  var valid_602848 = header.getOrDefault("X-Amz-Algorithm")
  valid_602848 = validateParameter(valid_602848, JString, required = false,
                                 default = nil)
  if valid_602848 != nil:
    section.add "X-Amz-Algorithm", valid_602848
  var valid_602849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602849 = validateParameter(valid_602849, JString, required = false,
                                 default = nil)
  if valid_602849 != nil:
    section.add "X-Amz-SignedHeaders", valid_602849
  result.add "header", section
  ## parameters in `formData` object:
  ##   TopicArn: JString (required)
  ##           : The ARN of the topic whose access control policy you wish to modify.
  ##   Label: JString (required)
  ##        : The unique label of the statement you want to remove.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TopicArn` field"
  var valid_602850 = formData.getOrDefault("TopicArn")
  valid_602850 = validateParameter(valid_602850, JString, required = true,
                                 default = nil)
  if valid_602850 != nil:
    section.add "TopicArn", valid_602850
  var valid_602851 = formData.getOrDefault("Label")
  valid_602851 = validateParameter(valid_602851, JString, required = true,
                                 default = nil)
  if valid_602851 != nil:
    section.add "Label", valid_602851
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602852: Call_PostRemovePermission_602838; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a statement from a topic's access control policy.
  ## 
  let valid = call_602852.validator(path, query, header, formData, body)
  let scheme = call_602852.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602852.url(scheme.get, call_602852.host, call_602852.base,
                         call_602852.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602852, url, valid)

proc call*(call_602853: Call_PostRemovePermission_602838; TopicArn: string;
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
  var query_602854 = newJObject()
  var formData_602855 = newJObject()
  add(formData_602855, "TopicArn", newJString(TopicArn))
  add(query_602854, "Action", newJString(Action))
  add(formData_602855, "Label", newJString(Label))
  add(query_602854, "Version", newJString(Version))
  result = call_602853.call(nil, query_602854, nil, formData_602855, nil)

var postRemovePermission* = Call_PostRemovePermission_602838(
    name: "postRemovePermission", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=RemovePermission",
    validator: validate_PostRemovePermission_602839, base: "/",
    url: url_PostRemovePermission_602840, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemovePermission_602821 = ref object of OpenApiRestCall_601389
proc url_GetRemovePermission_602823(protocol: Scheme; host: string; base: string;
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

proc validate_GetRemovePermission_602822(path: JsonNode; query: JsonNode;
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
  var valid_602824 = query.getOrDefault("TopicArn")
  valid_602824 = validateParameter(valid_602824, JString, required = true,
                                 default = nil)
  if valid_602824 != nil:
    section.add "TopicArn", valid_602824
  var valid_602825 = query.getOrDefault("Action")
  valid_602825 = validateParameter(valid_602825, JString, required = true,
                                 default = newJString("RemovePermission"))
  if valid_602825 != nil:
    section.add "Action", valid_602825
  var valid_602826 = query.getOrDefault("Version")
  valid_602826 = validateParameter(valid_602826, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602826 != nil:
    section.add "Version", valid_602826
  var valid_602827 = query.getOrDefault("Label")
  valid_602827 = validateParameter(valid_602827, JString, required = true,
                                 default = nil)
  if valid_602827 != nil:
    section.add "Label", valid_602827
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602828 = header.getOrDefault("X-Amz-Signature")
  valid_602828 = validateParameter(valid_602828, JString, required = false,
                                 default = nil)
  if valid_602828 != nil:
    section.add "X-Amz-Signature", valid_602828
  var valid_602829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602829 = validateParameter(valid_602829, JString, required = false,
                                 default = nil)
  if valid_602829 != nil:
    section.add "X-Amz-Content-Sha256", valid_602829
  var valid_602830 = header.getOrDefault("X-Amz-Date")
  valid_602830 = validateParameter(valid_602830, JString, required = false,
                                 default = nil)
  if valid_602830 != nil:
    section.add "X-Amz-Date", valid_602830
  var valid_602831 = header.getOrDefault("X-Amz-Credential")
  valid_602831 = validateParameter(valid_602831, JString, required = false,
                                 default = nil)
  if valid_602831 != nil:
    section.add "X-Amz-Credential", valid_602831
  var valid_602832 = header.getOrDefault("X-Amz-Security-Token")
  valid_602832 = validateParameter(valid_602832, JString, required = false,
                                 default = nil)
  if valid_602832 != nil:
    section.add "X-Amz-Security-Token", valid_602832
  var valid_602833 = header.getOrDefault("X-Amz-Algorithm")
  valid_602833 = validateParameter(valid_602833, JString, required = false,
                                 default = nil)
  if valid_602833 != nil:
    section.add "X-Amz-Algorithm", valid_602833
  var valid_602834 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602834 = validateParameter(valid_602834, JString, required = false,
                                 default = nil)
  if valid_602834 != nil:
    section.add "X-Amz-SignedHeaders", valid_602834
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602835: Call_GetRemovePermission_602821; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a statement from a topic's access control policy.
  ## 
  let valid = call_602835.validator(path, query, header, formData, body)
  let scheme = call_602835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602835.url(scheme.get, call_602835.host, call_602835.base,
                         call_602835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602835, url, valid)

proc call*(call_602836: Call_GetRemovePermission_602821; TopicArn: string;
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
  var query_602837 = newJObject()
  add(query_602837, "TopicArn", newJString(TopicArn))
  add(query_602837, "Action", newJString(Action))
  add(query_602837, "Version", newJString(Version))
  add(query_602837, "Label", newJString(Label))
  result = call_602836.call(nil, query_602837, nil, nil, nil)

var getRemovePermission* = Call_GetRemovePermission_602821(
    name: "getRemovePermission", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=RemovePermission",
    validator: validate_GetRemovePermission_602822, base: "/",
    url: url_GetRemovePermission_602823, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetEndpointAttributes_602878 = ref object of OpenApiRestCall_601389
proc url_PostSetEndpointAttributes_602880(protocol: Scheme; host: string;
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

proc validate_PostSetEndpointAttributes_602879(path: JsonNode; query: JsonNode;
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
  var valid_602881 = query.getOrDefault("Action")
  valid_602881 = validateParameter(valid_602881, JString, required = true,
                                 default = newJString("SetEndpointAttributes"))
  if valid_602881 != nil:
    section.add "Action", valid_602881
  var valid_602882 = query.getOrDefault("Version")
  valid_602882 = validateParameter(valid_602882, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602882 != nil:
    section.add "Version", valid_602882
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602883 = header.getOrDefault("X-Amz-Signature")
  valid_602883 = validateParameter(valid_602883, JString, required = false,
                                 default = nil)
  if valid_602883 != nil:
    section.add "X-Amz-Signature", valid_602883
  var valid_602884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602884 = validateParameter(valid_602884, JString, required = false,
                                 default = nil)
  if valid_602884 != nil:
    section.add "X-Amz-Content-Sha256", valid_602884
  var valid_602885 = header.getOrDefault("X-Amz-Date")
  valid_602885 = validateParameter(valid_602885, JString, required = false,
                                 default = nil)
  if valid_602885 != nil:
    section.add "X-Amz-Date", valid_602885
  var valid_602886 = header.getOrDefault("X-Amz-Credential")
  valid_602886 = validateParameter(valid_602886, JString, required = false,
                                 default = nil)
  if valid_602886 != nil:
    section.add "X-Amz-Credential", valid_602886
  var valid_602887 = header.getOrDefault("X-Amz-Security-Token")
  valid_602887 = validateParameter(valid_602887, JString, required = false,
                                 default = nil)
  if valid_602887 != nil:
    section.add "X-Amz-Security-Token", valid_602887
  var valid_602888 = header.getOrDefault("X-Amz-Algorithm")
  valid_602888 = validateParameter(valid_602888, JString, required = false,
                                 default = nil)
  if valid_602888 != nil:
    section.add "X-Amz-Algorithm", valid_602888
  var valid_602889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602889 = validateParameter(valid_602889, JString, required = false,
                                 default = nil)
  if valid_602889 != nil:
    section.add "X-Amz-SignedHeaders", valid_602889
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
  var valid_602890 = formData.getOrDefault("Attributes.0.key")
  valid_602890 = validateParameter(valid_602890, JString, required = false,
                                 default = nil)
  if valid_602890 != nil:
    section.add "Attributes.0.key", valid_602890
  assert formData != nil,
        "formData argument is necessary due to required `EndpointArn` field"
  var valid_602891 = formData.getOrDefault("EndpointArn")
  valid_602891 = validateParameter(valid_602891, JString, required = true,
                                 default = nil)
  if valid_602891 != nil:
    section.add "EndpointArn", valid_602891
  var valid_602892 = formData.getOrDefault("Attributes.2.value")
  valid_602892 = validateParameter(valid_602892, JString, required = false,
                                 default = nil)
  if valid_602892 != nil:
    section.add "Attributes.2.value", valid_602892
  var valid_602893 = formData.getOrDefault("Attributes.2.key")
  valid_602893 = validateParameter(valid_602893, JString, required = false,
                                 default = nil)
  if valid_602893 != nil:
    section.add "Attributes.2.key", valid_602893
  var valid_602894 = formData.getOrDefault("Attributes.0.value")
  valid_602894 = validateParameter(valid_602894, JString, required = false,
                                 default = nil)
  if valid_602894 != nil:
    section.add "Attributes.0.value", valid_602894
  var valid_602895 = formData.getOrDefault("Attributes.1.key")
  valid_602895 = validateParameter(valid_602895, JString, required = false,
                                 default = nil)
  if valid_602895 != nil:
    section.add "Attributes.1.key", valid_602895
  var valid_602896 = formData.getOrDefault("Attributes.1.value")
  valid_602896 = validateParameter(valid_602896, JString, required = false,
                                 default = nil)
  if valid_602896 != nil:
    section.add "Attributes.1.value", valid_602896
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602897: Call_PostSetEndpointAttributes_602878; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_602897.validator(path, query, header, formData, body)
  let scheme = call_602897.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602897.url(scheme.get, call_602897.host, call_602897.base,
                         call_602897.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602897, url, valid)

proc call*(call_602898: Call_PostSetEndpointAttributes_602878; EndpointArn: string;
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
  var query_602899 = newJObject()
  var formData_602900 = newJObject()
  add(formData_602900, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_602900, "EndpointArn", newJString(EndpointArn))
  add(formData_602900, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_602900, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_602900, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_602900, "Attributes.1.key", newJString(Attributes1Key))
  add(query_602899, "Action", newJString(Action))
  add(query_602899, "Version", newJString(Version))
  add(formData_602900, "Attributes.1.value", newJString(Attributes1Value))
  result = call_602898.call(nil, query_602899, nil, formData_602900, nil)

var postSetEndpointAttributes* = Call_PostSetEndpointAttributes_602878(
    name: "postSetEndpointAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetEndpointAttributes",
    validator: validate_PostSetEndpointAttributes_602879, base: "/",
    url: url_PostSetEndpointAttributes_602880,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetEndpointAttributes_602856 = ref object of OpenApiRestCall_601389
proc url_GetSetEndpointAttributes_602858(protocol: Scheme; host: string;
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

proc validate_GetSetEndpointAttributes_602857(path: JsonNode; query: JsonNode;
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
  var valid_602859 = query.getOrDefault("Attributes.1.key")
  valid_602859 = validateParameter(valid_602859, JString, required = false,
                                 default = nil)
  if valid_602859 != nil:
    section.add "Attributes.1.key", valid_602859
  var valid_602860 = query.getOrDefault("Attributes.0.value")
  valid_602860 = validateParameter(valid_602860, JString, required = false,
                                 default = nil)
  if valid_602860 != nil:
    section.add "Attributes.0.value", valid_602860
  var valid_602861 = query.getOrDefault("Attributes.0.key")
  valid_602861 = validateParameter(valid_602861, JString, required = false,
                                 default = nil)
  if valid_602861 != nil:
    section.add "Attributes.0.key", valid_602861
  var valid_602862 = query.getOrDefault("Attributes.2.value")
  valid_602862 = validateParameter(valid_602862, JString, required = false,
                                 default = nil)
  if valid_602862 != nil:
    section.add "Attributes.2.value", valid_602862
  var valid_602863 = query.getOrDefault("Attributes.1.value")
  valid_602863 = validateParameter(valid_602863, JString, required = false,
                                 default = nil)
  if valid_602863 != nil:
    section.add "Attributes.1.value", valid_602863
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602864 = query.getOrDefault("Action")
  valid_602864 = validateParameter(valid_602864, JString, required = true,
                                 default = newJString("SetEndpointAttributes"))
  if valid_602864 != nil:
    section.add "Action", valid_602864
  var valid_602865 = query.getOrDefault("EndpointArn")
  valid_602865 = validateParameter(valid_602865, JString, required = true,
                                 default = nil)
  if valid_602865 != nil:
    section.add "EndpointArn", valid_602865
  var valid_602866 = query.getOrDefault("Version")
  valid_602866 = validateParameter(valid_602866, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602866 != nil:
    section.add "Version", valid_602866
  var valid_602867 = query.getOrDefault("Attributes.2.key")
  valid_602867 = validateParameter(valid_602867, JString, required = false,
                                 default = nil)
  if valid_602867 != nil:
    section.add "Attributes.2.key", valid_602867
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602868 = header.getOrDefault("X-Amz-Signature")
  valid_602868 = validateParameter(valid_602868, JString, required = false,
                                 default = nil)
  if valid_602868 != nil:
    section.add "X-Amz-Signature", valid_602868
  var valid_602869 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602869 = validateParameter(valid_602869, JString, required = false,
                                 default = nil)
  if valid_602869 != nil:
    section.add "X-Amz-Content-Sha256", valid_602869
  var valid_602870 = header.getOrDefault("X-Amz-Date")
  valid_602870 = validateParameter(valid_602870, JString, required = false,
                                 default = nil)
  if valid_602870 != nil:
    section.add "X-Amz-Date", valid_602870
  var valid_602871 = header.getOrDefault("X-Amz-Credential")
  valid_602871 = validateParameter(valid_602871, JString, required = false,
                                 default = nil)
  if valid_602871 != nil:
    section.add "X-Amz-Credential", valid_602871
  var valid_602872 = header.getOrDefault("X-Amz-Security-Token")
  valid_602872 = validateParameter(valid_602872, JString, required = false,
                                 default = nil)
  if valid_602872 != nil:
    section.add "X-Amz-Security-Token", valid_602872
  var valid_602873 = header.getOrDefault("X-Amz-Algorithm")
  valid_602873 = validateParameter(valid_602873, JString, required = false,
                                 default = nil)
  if valid_602873 != nil:
    section.add "X-Amz-Algorithm", valid_602873
  var valid_602874 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602874 = validateParameter(valid_602874, JString, required = false,
                                 default = nil)
  if valid_602874 != nil:
    section.add "X-Amz-SignedHeaders", valid_602874
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602875: Call_GetSetEndpointAttributes_602856; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sets the attributes for an endpoint for a device on one of the supported push notification services, such as FCM and APNS. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. 
  ## 
  let valid = call_602875.validator(path, query, header, formData, body)
  let scheme = call_602875.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602875.url(scheme.get, call_602875.host, call_602875.base,
                         call_602875.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602875, url, valid)

proc call*(call_602876: Call_GetSetEndpointAttributes_602856; EndpointArn: string;
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
  var query_602877 = newJObject()
  add(query_602877, "Attributes.1.key", newJString(Attributes1Key))
  add(query_602877, "Attributes.0.value", newJString(Attributes0Value))
  add(query_602877, "Attributes.0.key", newJString(Attributes0Key))
  add(query_602877, "Attributes.2.value", newJString(Attributes2Value))
  add(query_602877, "Attributes.1.value", newJString(Attributes1Value))
  add(query_602877, "Action", newJString(Action))
  add(query_602877, "EndpointArn", newJString(EndpointArn))
  add(query_602877, "Version", newJString(Version))
  add(query_602877, "Attributes.2.key", newJString(Attributes2Key))
  result = call_602876.call(nil, query_602877, nil, nil, nil)

var getSetEndpointAttributes* = Call_GetSetEndpointAttributes_602856(
    name: "getSetEndpointAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetEndpointAttributes",
    validator: validate_GetSetEndpointAttributes_602857, base: "/",
    url: url_GetSetEndpointAttributes_602858, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetPlatformApplicationAttributes_602923 = ref object of OpenApiRestCall_601389
proc url_PostSetPlatformApplicationAttributes_602925(protocol: Scheme;
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

proc validate_PostSetPlatformApplicationAttributes_602924(path: JsonNode;
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
  var valid_602926 = query.getOrDefault("Action")
  valid_602926 = validateParameter(valid_602926, JString, required = true, default = newJString(
      "SetPlatformApplicationAttributes"))
  if valid_602926 != nil:
    section.add "Action", valid_602926
  var valid_602927 = query.getOrDefault("Version")
  valid_602927 = validateParameter(valid_602927, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602927 != nil:
    section.add "Version", valid_602927
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602928 = header.getOrDefault("X-Amz-Signature")
  valid_602928 = validateParameter(valid_602928, JString, required = false,
                                 default = nil)
  if valid_602928 != nil:
    section.add "X-Amz-Signature", valid_602928
  var valid_602929 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602929 = validateParameter(valid_602929, JString, required = false,
                                 default = nil)
  if valid_602929 != nil:
    section.add "X-Amz-Content-Sha256", valid_602929
  var valid_602930 = header.getOrDefault("X-Amz-Date")
  valid_602930 = validateParameter(valid_602930, JString, required = false,
                                 default = nil)
  if valid_602930 != nil:
    section.add "X-Amz-Date", valid_602930
  var valid_602931 = header.getOrDefault("X-Amz-Credential")
  valid_602931 = validateParameter(valid_602931, JString, required = false,
                                 default = nil)
  if valid_602931 != nil:
    section.add "X-Amz-Credential", valid_602931
  var valid_602932 = header.getOrDefault("X-Amz-Security-Token")
  valid_602932 = validateParameter(valid_602932, JString, required = false,
                                 default = nil)
  if valid_602932 != nil:
    section.add "X-Amz-Security-Token", valid_602932
  var valid_602933 = header.getOrDefault("X-Amz-Algorithm")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Algorithm", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-SignedHeaders", valid_602934
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
  var valid_602935 = formData.getOrDefault("PlatformApplicationArn")
  valid_602935 = validateParameter(valid_602935, JString, required = true,
                                 default = nil)
  if valid_602935 != nil:
    section.add "PlatformApplicationArn", valid_602935
  var valid_602936 = formData.getOrDefault("Attributes.0.key")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "Attributes.0.key", valid_602936
  var valid_602937 = formData.getOrDefault("Attributes.2.value")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "Attributes.2.value", valid_602937
  var valid_602938 = formData.getOrDefault("Attributes.2.key")
  valid_602938 = validateParameter(valid_602938, JString, required = false,
                                 default = nil)
  if valid_602938 != nil:
    section.add "Attributes.2.key", valid_602938
  var valid_602939 = formData.getOrDefault("Attributes.0.value")
  valid_602939 = validateParameter(valid_602939, JString, required = false,
                                 default = nil)
  if valid_602939 != nil:
    section.add "Attributes.0.value", valid_602939
  var valid_602940 = formData.getOrDefault("Attributes.1.key")
  valid_602940 = validateParameter(valid_602940, JString, required = false,
                                 default = nil)
  if valid_602940 != nil:
    section.add "Attributes.1.key", valid_602940
  var valid_602941 = formData.getOrDefault("Attributes.1.value")
  valid_602941 = validateParameter(valid_602941, JString, required = false,
                                 default = nil)
  if valid_602941 != nil:
    section.add "Attributes.1.value", valid_602941
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602942: Call_PostSetPlatformApplicationAttributes_602923;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  let valid = call_602942.validator(path, query, header, formData, body)
  let scheme = call_602942.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602942.url(scheme.get, call_602942.host, call_602942.base,
                         call_602942.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602942, url, valid)

proc call*(call_602943: Call_PostSetPlatformApplicationAttributes_602923;
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
  var query_602944 = newJObject()
  var formData_602945 = newJObject()
  add(formData_602945, "PlatformApplicationArn",
      newJString(PlatformApplicationArn))
  add(formData_602945, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_602945, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_602945, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_602945, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_602945, "Attributes.1.key", newJString(Attributes1Key))
  add(query_602944, "Action", newJString(Action))
  add(query_602944, "Version", newJString(Version))
  add(formData_602945, "Attributes.1.value", newJString(Attributes1Value))
  result = call_602943.call(nil, query_602944, nil, formData_602945, nil)

var postSetPlatformApplicationAttributes* = Call_PostSetPlatformApplicationAttributes_602923(
    name: "postSetPlatformApplicationAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetPlatformApplicationAttributes",
    validator: validate_PostSetPlatformApplicationAttributes_602924, base: "/",
    url: url_PostSetPlatformApplicationAttributes_602925,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetPlatformApplicationAttributes_602901 = ref object of OpenApiRestCall_601389
proc url_GetSetPlatformApplicationAttributes_602903(protocol: Scheme; host: string;
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

proc validate_GetSetPlatformApplicationAttributes_602902(path: JsonNode;
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
  var valid_602904 = query.getOrDefault("Attributes.1.key")
  valid_602904 = validateParameter(valid_602904, JString, required = false,
                                 default = nil)
  if valid_602904 != nil:
    section.add "Attributes.1.key", valid_602904
  var valid_602905 = query.getOrDefault("Attributes.0.value")
  valid_602905 = validateParameter(valid_602905, JString, required = false,
                                 default = nil)
  if valid_602905 != nil:
    section.add "Attributes.0.value", valid_602905
  var valid_602906 = query.getOrDefault("Attributes.0.key")
  valid_602906 = validateParameter(valid_602906, JString, required = false,
                                 default = nil)
  if valid_602906 != nil:
    section.add "Attributes.0.key", valid_602906
  var valid_602907 = query.getOrDefault("Attributes.2.value")
  valid_602907 = validateParameter(valid_602907, JString, required = false,
                                 default = nil)
  if valid_602907 != nil:
    section.add "Attributes.2.value", valid_602907
  var valid_602908 = query.getOrDefault("Attributes.1.value")
  valid_602908 = validateParameter(valid_602908, JString, required = false,
                                 default = nil)
  if valid_602908 != nil:
    section.add "Attributes.1.value", valid_602908
  assert query != nil, "query argument is necessary due to required `PlatformApplicationArn` field"
  var valid_602909 = query.getOrDefault("PlatformApplicationArn")
  valid_602909 = validateParameter(valid_602909, JString, required = true,
                                 default = nil)
  if valid_602909 != nil:
    section.add "PlatformApplicationArn", valid_602909
  var valid_602910 = query.getOrDefault("Action")
  valid_602910 = validateParameter(valid_602910, JString, required = true, default = newJString(
      "SetPlatformApplicationAttributes"))
  if valid_602910 != nil:
    section.add "Action", valid_602910
  var valid_602911 = query.getOrDefault("Version")
  valid_602911 = validateParameter(valid_602911, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602911 != nil:
    section.add "Version", valid_602911
  var valid_602912 = query.getOrDefault("Attributes.2.key")
  valid_602912 = validateParameter(valid_602912, JString, required = false,
                                 default = nil)
  if valid_602912 != nil:
    section.add "Attributes.2.key", valid_602912
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602913 = header.getOrDefault("X-Amz-Signature")
  valid_602913 = validateParameter(valid_602913, JString, required = false,
                                 default = nil)
  if valid_602913 != nil:
    section.add "X-Amz-Signature", valid_602913
  var valid_602914 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602914 = validateParameter(valid_602914, JString, required = false,
                                 default = nil)
  if valid_602914 != nil:
    section.add "X-Amz-Content-Sha256", valid_602914
  var valid_602915 = header.getOrDefault("X-Amz-Date")
  valid_602915 = validateParameter(valid_602915, JString, required = false,
                                 default = nil)
  if valid_602915 != nil:
    section.add "X-Amz-Date", valid_602915
  var valid_602916 = header.getOrDefault("X-Amz-Credential")
  valid_602916 = validateParameter(valid_602916, JString, required = false,
                                 default = nil)
  if valid_602916 != nil:
    section.add "X-Amz-Credential", valid_602916
  var valid_602917 = header.getOrDefault("X-Amz-Security-Token")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Security-Token", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-Algorithm")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Algorithm", valid_602918
  var valid_602919 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602919 = validateParameter(valid_602919, JString, required = false,
                                 default = nil)
  if valid_602919 != nil:
    section.add "X-Amz-SignedHeaders", valid_602919
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602920: Call_GetSetPlatformApplicationAttributes_602901;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Sets the attributes of the platform application object for the supported push notification services, such as APNS and FCM. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/SNSMobilePush.html">Using Amazon SNS Mobile Push Notifications</a>. For information on configuring attributes for message delivery status, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html">Using Amazon SNS Application Attributes for Message Delivery Status</a>. 
  ## 
  let valid = call_602920.validator(path, query, header, formData, body)
  let scheme = call_602920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602920.url(scheme.get, call_602920.host, call_602920.base,
                         call_602920.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602920, url, valid)

proc call*(call_602921: Call_GetSetPlatformApplicationAttributes_602901;
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
  var query_602922 = newJObject()
  add(query_602922, "Attributes.1.key", newJString(Attributes1Key))
  add(query_602922, "Attributes.0.value", newJString(Attributes0Value))
  add(query_602922, "Attributes.0.key", newJString(Attributes0Key))
  add(query_602922, "Attributes.2.value", newJString(Attributes2Value))
  add(query_602922, "Attributes.1.value", newJString(Attributes1Value))
  add(query_602922, "PlatformApplicationArn", newJString(PlatformApplicationArn))
  add(query_602922, "Action", newJString(Action))
  add(query_602922, "Version", newJString(Version))
  add(query_602922, "Attributes.2.key", newJString(Attributes2Key))
  result = call_602921.call(nil, query_602922, nil, nil, nil)

var getSetPlatformApplicationAttributes* = Call_GetSetPlatformApplicationAttributes_602901(
    name: "getSetPlatformApplicationAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetPlatformApplicationAttributes",
    validator: validate_GetSetPlatformApplicationAttributes_602902, base: "/",
    url: url_GetSetPlatformApplicationAttributes_602903,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSMSAttributes_602967 = ref object of OpenApiRestCall_601389
proc url_PostSetSMSAttributes_602969(protocol: Scheme; host: string; base: string;
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

proc validate_PostSetSMSAttributes_602968(path: JsonNode; query: JsonNode;
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
  var valid_602970 = query.getOrDefault("Action")
  valid_602970 = validateParameter(valid_602970, JString, required = true,
                                 default = newJString("SetSMSAttributes"))
  if valid_602970 != nil:
    section.add "Action", valid_602970
  var valid_602971 = query.getOrDefault("Version")
  valid_602971 = validateParameter(valid_602971, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602971 != nil:
    section.add "Version", valid_602971
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602972 = header.getOrDefault("X-Amz-Signature")
  valid_602972 = validateParameter(valid_602972, JString, required = false,
                                 default = nil)
  if valid_602972 != nil:
    section.add "X-Amz-Signature", valid_602972
  var valid_602973 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602973 = validateParameter(valid_602973, JString, required = false,
                                 default = nil)
  if valid_602973 != nil:
    section.add "X-Amz-Content-Sha256", valid_602973
  var valid_602974 = header.getOrDefault("X-Amz-Date")
  valid_602974 = validateParameter(valid_602974, JString, required = false,
                                 default = nil)
  if valid_602974 != nil:
    section.add "X-Amz-Date", valid_602974
  var valid_602975 = header.getOrDefault("X-Amz-Credential")
  valid_602975 = validateParameter(valid_602975, JString, required = false,
                                 default = nil)
  if valid_602975 != nil:
    section.add "X-Amz-Credential", valid_602975
  var valid_602976 = header.getOrDefault("X-Amz-Security-Token")
  valid_602976 = validateParameter(valid_602976, JString, required = false,
                                 default = nil)
  if valid_602976 != nil:
    section.add "X-Amz-Security-Token", valid_602976
  var valid_602977 = header.getOrDefault("X-Amz-Algorithm")
  valid_602977 = validateParameter(valid_602977, JString, required = false,
                                 default = nil)
  if valid_602977 != nil:
    section.add "X-Amz-Algorithm", valid_602977
  var valid_602978 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602978 = validateParameter(valid_602978, JString, required = false,
                                 default = nil)
  if valid_602978 != nil:
    section.add "X-Amz-SignedHeaders", valid_602978
  result.add "header", section
  ## parameters in `formData` object:
  ##   attributes.1.key: JString
  ##   attributes.1.value: JString
  ##   attributes.2.key: JString
  ##   attributes.0.value: JString
  ##   attributes.0.key: JString
  ##   attributes.2.value: JString
  section = newJObject()
  var valid_602979 = formData.getOrDefault("attributes.1.key")
  valid_602979 = validateParameter(valid_602979, JString, required = false,
                                 default = nil)
  if valid_602979 != nil:
    section.add "attributes.1.key", valid_602979
  var valid_602980 = formData.getOrDefault("attributes.1.value")
  valid_602980 = validateParameter(valid_602980, JString, required = false,
                                 default = nil)
  if valid_602980 != nil:
    section.add "attributes.1.value", valid_602980
  var valid_602981 = formData.getOrDefault("attributes.2.key")
  valid_602981 = validateParameter(valid_602981, JString, required = false,
                                 default = nil)
  if valid_602981 != nil:
    section.add "attributes.2.key", valid_602981
  var valid_602982 = formData.getOrDefault("attributes.0.value")
  valid_602982 = validateParameter(valid_602982, JString, required = false,
                                 default = nil)
  if valid_602982 != nil:
    section.add "attributes.0.value", valid_602982
  var valid_602983 = formData.getOrDefault("attributes.0.key")
  valid_602983 = validateParameter(valid_602983, JString, required = false,
                                 default = nil)
  if valid_602983 != nil:
    section.add "attributes.0.key", valid_602983
  var valid_602984 = formData.getOrDefault("attributes.2.value")
  valid_602984 = validateParameter(valid_602984, JString, required = false,
                                 default = nil)
  if valid_602984 != nil:
    section.add "attributes.2.value", valid_602984
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602985: Call_PostSetSMSAttributes_602967; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_602985.validator(path, query, header, formData, body)
  let scheme = call_602985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602985.url(scheme.get, call_602985.host, call_602985.base,
                         call_602985.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602985, url, valid)

proc call*(call_602986: Call_PostSetSMSAttributes_602967;
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
  var query_602987 = newJObject()
  var formData_602988 = newJObject()
  add(formData_602988, "attributes.1.key", newJString(attributes1Key))
  add(formData_602988, "attributes.1.value", newJString(attributes1Value))
  add(formData_602988, "attributes.2.key", newJString(attributes2Key))
  add(formData_602988, "attributes.0.value", newJString(attributes0Value))
  add(query_602987, "Action", newJString(Action))
  add(query_602987, "Version", newJString(Version))
  add(formData_602988, "attributes.0.key", newJString(attributes0Key))
  add(formData_602988, "attributes.2.value", newJString(attributes2Value))
  result = call_602986.call(nil, query_602987, nil, formData_602988, nil)

var postSetSMSAttributes* = Call_PostSetSMSAttributes_602967(
    name: "postSetSMSAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetSMSAttributes",
    validator: validate_PostSetSMSAttributes_602968, base: "/",
    url: url_PostSetSMSAttributes_602969, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSMSAttributes_602946 = ref object of OpenApiRestCall_601389
proc url_GetSetSMSAttributes_602948(protocol: Scheme; host: string; base: string;
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

proc validate_GetSetSMSAttributes_602947(path: JsonNode; query: JsonNode;
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
  var valid_602949 = query.getOrDefault("attributes.2.key")
  valid_602949 = validateParameter(valid_602949, JString, required = false,
                                 default = nil)
  if valid_602949 != nil:
    section.add "attributes.2.key", valid_602949
  var valid_602950 = query.getOrDefault("attributes.0.key")
  valid_602950 = validateParameter(valid_602950, JString, required = false,
                                 default = nil)
  if valid_602950 != nil:
    section.add "attributes.0.key", valid_602950
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602951 = query.getOrDefault("Action")
  valid_602951 = validateParameter(valid_602951, JString, required = true,
                                 default = newJString("SetSMSAttributes"))
  if valid_602951 != nil:
    section.add "Action", valid_602951
  var valid_602952 = query.getOrDefault("attributes.1.key")
  valid_602952 = validateParameter(valid_602952, JString, required = false,
                                 default = nil)
  if valid_602952 != nil:
    section.add "attributes.1.key", valid_602952
  var valid_602953 = query.getOrDefault("attributes.0.value")
  valid_602953 = validateParameter(valid_602953, JString, required = false,
                                 default = nil)
  if valid_602953 != nil:
    section.add "attributes.0.value", valid_602953
  var valid_602954 = query.getOrDefault("Version")
  valid_602954 = validateParameter(valid_602954, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602954 != nil:
    section.add "Version", valid_602954
  var valid_602955 = query.getOrDefault("attributes.1.value")
  valid_602955 = validateParameter(valid_602955, JString, required = false,
                                 default = nil)
  if valid_602955 != nil:
    section.add "attributes.1.value", valid_602955
  var valid_602956 = query.getOrDefault("attributes.2.value")
  valid_602956 = validateParameter(valid_602956, JString, required = false,
                                 default = nil)
  if valid_602956 != nil:
    section.add "attributes.2.value", valid_602956
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602957 = header.getOrDefault("X-Amz-Signature")
  valid_602957 = validateParameter(valid_602957, JString, required = false,
                                 default = nil)
  if valid_602957 != nil:
    section.add "X-Amz-Signature", valid_602957
  var valid_602958 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602958 = validateParameter(valid_602958, JString, required = false,
                                 default = nil)
  if valid_602958 != nil:
    section.add "X-Amz-Content-Sha256", valid_602958
  var valid_602959 = header.getOrDefault("X-Amz-Date")
  valid_602959 = validateParameter(valid_602959, JString, required = false,
                                 default = nil)
  if valid_602959 != nil:
    section.add "X-Amz-Date", valid_602959
  var valid_602960 = header.getOrDefault("X-Amz-Credential")
  valid_602960 = validateParameter(valid_602960, JString, required = false,
                                 default = nil)
  if valid_602960 != nil:
    section.add "X-Amz-Credential", valid_602960
  var valid_602961 = header.getOrDefault("X-Amz-Security-Token")
  valid_602961 = validateParameter(valid_602961, JString, required = false,
                                 default = nil)
  if valid_602961 != nil:
    section.add "X-Amz-Security-Token", valid_602961
  var valid_602962 = header.getOrDefault("X-Amz-Algorithm")
  valid_602962 = validateParameter(valid_602962, JString, required = false,
                                 default = nil)
  if valid_602962 != nil:
    section.add "X-Amz-Algorithm", valid_602962
  var valid_602963 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602963 = validateParameter(valid_602963, JString, required = false,
                                 default = nil)
  if valid_602963 != nil:
    section.add "X-Amz-SignedHeaders", valid_602963
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602964: Call_GetSetSMSAttributes_602946; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use this request to set the default settings for sending SMS messages and receiving daily SMS usage reports.</p> <p>You can override some of these settings for a single message when you use the <code>Publish</code> action with the <code>MessageAttributes.entry.N</code> parameter. For more information, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html">Sending an SMS Message</a> in the <i>Amazon SNS Developer Guide</i>.</p>
  ## 
  let valid = call_602964.validator(path, query, header, formData, body)
  let scheme = call_602964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602964.url(scheme.get, call_602964.host, call_602964.base,
                         call_602964.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602964, url, valid)

proc call*(call_602965: Call_GetSetSMSAttributes_602946;
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
  var query_602966 = newJObject()
  add(query_602966, "attributes.2.key", newJString(attributes2Key))
  add(query_602966, "attributes.0.key", newJString(attributes0Key))
  add(query_602966, "Action", newJString(Action))
  add(query_602966, "attributes.1.key", newJString(attributes1Key))
  add(query_602966, "attributes.0.value", newJString(attributes0Value))
  add(query_602966, "Version", newJString(Version))
  add(query_602966, "attributes.1.value", newJString(attributes1Value))
  add(query_602966, "attributes.2.value", newJString(attributes2Value))
  result = call_602965.call(nil, query_602966, nil, nil, nil)

var getSetSMSAttributes* = Call_GetSetSMSAttributes_602946(
    name: "getSetSMSAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetSMSAttributes",
    validator: validate_GetSetSMSAttributes_602947, base: "/",
    url: url_GetSetSMSAttributes_602948, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetSubscriptionAttributes_603007 = ref object of OpenApiRestCall_601389
proc url_PostSetSubscriptionAttributes_603009(protocol: Scheme; host: string;
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

proc validate_PostSetSubscriptionAttributes_603008(path: JsonNode; query: JsonNode;
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
  var valid_603010 = query.getOrDefault("Action")
  valid_603010 = validateParameter(valid_603010, JString, required = true, default = newJString(
      "SetSubscriptionAttributes"))
  if valid_603010 != nil:
    section.add "Action", valid_603010
  var valid_603011 = query.getOrDefault("Version")
  valid_603011 = validateParameter(valid_603011, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603011 != nil:
    section.add "Version", valid_603011
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603012 = header.getOrDefault("X-Amz-Signature")
  valid_603012 = validateParameter(valid_603012, JString, required = false,
                                 default = nil)
  if valid_603012 != nil:
    section.add "X-Amz-Signature", valid_603012
  var valid_603013 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603013 = validateParameter(valid_603013, JString, required = false,
                                 default = nil)
  if valid_603013 != nil:
    section.add "X-Amz-Content-Sha256", valid_603013
  var valid_603014 = header.getOrDefault("X-Amz-Date")
  valid_603014 = validateParameter(valid_603014, JString, required = false,
                                 default = nil)
  if valid_603014 != nil:
    section.add "X-Amz-Date", valid_603014
  var valid_603015 = header.getOrDefault("X-Amz-Credential")
  valid_603015 = validateParameter(valid_603015, JString, required = false,
                                 default = nil)
  if valid_603015 != nil:
    section.add "X-Amz-Credential", valid_603015
  var valid_603016 = header.getOrDefault("X-Amz-Security-Token")
  valid_603016 = validateParameter(valid_603016, JString, required = false,
                                 default = nil)
  if valid_603016 != nil:
    section.add "X-Amz-Security-Token", valid_603016
  var valid_603017 = header.getOrDefault("X-Amz-Algorithm")
  valid_603017 = validateParameter(valid_603017, JString, required = false,
                                 default = nil)
  if valid_603017 != nil:
    section.add "X-Amz-Algorithm", valid_603017
  var valid_603018 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603018 = validateParameter(valid_603018, JString, required = false,
                                 default = nil)
  if valid_603018 != nil:
    section.add "X-Amz-SignedHeaders", valid_603018
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
  var valid_603019 = formData.getOrDefault("AttributeName")
  valid_603019 = validateParameter(valid_603019, JString, required = true,
                                 default = nil)
  if valid_603019 != nil:
    section.add "AttributeName", valid_603019
  var valid_603020 = formData.getOrDefault("SubscriptionArn")
  valid_603020 = validateParameter(valid_603020, JString, required = true,
                                 default = nil)
  if valid_603020 != nil:
    section.add "SubscriptionArn", valid_603020
  var valid_603021 = formData.getOrDefault("AttributeValue")
  valid_603021 = validateParameter(valid_603021, JString, required = false,
                                 default = nil)
  if valid_603021 != nil:
    section.add "AttributeValue", valid_603021
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603022: Call_PostSetSubscriptionAttributes_603007; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ## 
  let valid = call_603022.validator(path, query, header, formData, body)
  let scheme = call_603022.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603022.url(scheme.get, call_603022.host, call_603022.base,
                         call_603022.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603022, url, valid)

proc call*(call_603023: Call_PostSetSubscriptionAttributes_603007;
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
  var query_603024 = newJObject()
  var formData_603025 = newJObject()
  add(formData_603025, "AttributeName", newJString(AttributeName))
  add(formData_603025, "SubscriptionArn", newJString(SubscriptionArn))
  add(formData_603025, "AttributeValue", newJString(AttributeValue))
  add(query_603024, "Action", newJString(Action))
  add(query_603024, "Version", newJString(Version))
  result = call_603023.call(nil, query_603024, nil, formData_603025, nil)

var postSetSubscriptionAttributes* = Call_PostSetSubscriptionAttributes_603007(
    name: "postSetSubscriptionAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetSubscriptionAttributes",
    validator: validate_PostSetSubscriptionAttributes_603008, base: "/",
    url: url_PostSetSubscriptionAttributes_603009,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetSubscriptionAttributes_602989 = ref object of OpenApiRestCall_601389
proc url_GetSetSubscriptionAttributes_602991(protocol: Scheme; host: string;
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

proc validate_GetSetSubscriptionAttributes_602990(path: JsonNode; query: JsonNode;
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
  var valid_602992 = query.getOrDefault("SubscriptionArn")
  valid_602992 = validateParameter(valid_602992, JString, required = true,
                                 default = nil)
  if valid_602992 != nil:
    section.add "SubscriptionArn", valid_602992
  var valid_602993 = query.getOrDefault("AttributeValue")
  valid_602993 = validateParameter(valid_602993, JString, required = false,
                                 default = nil)
  if valid_602993 != nil:
    section.add "AttributeValue", valid_602993
  var valid_602994 = query.getOrDefault("Action")
  valid_602994 = validateParameter(valid_602994, JString, required = true, default = newJString(
      "SetSubscriptionAttributes"))
  if valid_602994 != nil:
    section.add "Action", valid_602994
  var valid_602995 = query.getOrDefault("AttributeName")
  valid_602995 = validateParameter(valid_602995, JString, required = true,
                                 default = nil)
  if valid_602995 != nil:
    section.add "AttributeName", valid_602995
  var valid_602996 = query.getOrDefault("Version")
  valid_602996 = validateParameter(valid_602996, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_602996 != nil:
    section.add "Version", valid_602996
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602997 = header.getOrDefault("X-Amz-Signature")
  valid_602997 = validateParameter(valid_602997, JString, required = false,
                                 default = nil)
  if valid_602997 != nil:
    section.add "X-Amz-Signature", valid_602997
  var valid_602998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602998 = validateParameter(valid_602998, JString, required = false,
                                 default = nil)
  if valid_602998 != nil:
    section.add "X-Amz-Content-Sha256", valid_602998
  var valid_602999 = header.getOrDefault("X-Amz-Date")
  valid_602999 = validateParameter(valid_602999, JString, required = false,
                                 default = nil)
  if valid_602999 != nil:
    section.add "X-Amz-Date", valid_602999
  var valid_603000 = header.getOrDefault("X-Amz-Credential")
  valid_603000 = validateParameter(valid_603000, JString, required = false,
                                 default = nil)
  if valid_603000 != nil:
    section.add "X-Amz-Credential", valid_603000
  var valid_603001 = header.getOrDefault("X-Amz-Security-Token")
  valid_603001 = validateParameter(valid_603001, JString, required = false,
                                 default = nil)
  if valid_603001 != nil:
    section.add "X-Amz-Security-Token", valid_603001
  var valid_603002 = header.getOrDefault("X-Amz-Algorithm")
  valid_603002 = validateParameter(valid_603002, JString, required = false,
                                 default = nil)
  if valid_603002 != nil:
    section.add "X-Amz-Algorithm", valid_603002
  var valid_603003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603003 = validateParameter(valid_603003, JString, required = false,
                                 default = nil)
  if valid_603003 != nil:
    section.add "X-Amz-SignedHeaders", valid_603003
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603004: Call_GetSetSubscriptionAttributes_602989; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a subscription owner to set an attribute of the subscription to a new value.
  ## 
  let valid = call_603004.validator(path, query, header, formData, body)
  let scheme = call_603004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603004.url(scheme.get, call_603004.host, call_603004.base,
                         call_603004.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603004, url, valid)

proc call*(call_603005: Call_GetSetSubscriptionAttributes_602989;
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
  var query_603006 = newJObject()
  add(query_603006, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_603006, "AttributeValue", newJString(AttributeValue))
  add(query_603006, "Action", newJString(Action))
  add(query_603006, "AttributeName", newJString(AttributeName))
  add(query_603006, "Version", newJString(Version))
  result = call_603005.call(nil, query_603006, nil, nil, nil)

var getSetSubscriptionAttributes* = Call_GetSetSubscriptionAttributes_602989(
    name: "getSetSubscriptionAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetSubscriptionAttributes",
    validator: validate_GetSetSubscriptionAttributes_602990, base: "/",
    url: url_GetSetSubscriptionAttributes_602991,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSetTopicAttributes_603044 = ref object of OpenApiRestCall_601389
proc url_PostSetTopicAttributes_603046(protocol: Scheme; host: string; base: string;
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

proc validate_PostSetTopicAttributes_603045(path: JsonNode; query: JsonNode;
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
  var valid_603047 = query.getOrDefault("Action")
  valid_603047 = validateParameter(valid_603047, JString, required = true,
                                 default = newJString("SetTopicAttributes"))
  if valid_603047 != nil:
    section.add "Action", valid_603047
  var valid_603048 = query.getOrDefault("Version")
  valid_603048 = validateParameter(valid_603048, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603048 != nil:
    section.add "Version", valid_603048
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603049 = header.getOrDefault("X-Amz-Signature")
  valid_603049 = validateParameter(valid_603049, JString, required = false,
                                 default = nil)
  if valid_603049 != nil:
    section.add "X-Amz-Signature", valid_603049
  var valid_603050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603050 = validateParameter(valid_603050, JString, required = false,
                                 default = nil)
  if valid_603050 != nil:
    section.add "X-Amz-Content-Sha256", valid_603050
  var valid_603051 = header.getOrDefault("X-Amz-Date")
  valid_603051 = validateParameter(valid_603051, JString, required = false,
                                 default = nil)
  if valid_603051 != nil:
    section.add "X-Amz-Date", valid_603051
  var valid_603052 = header.getOrDefault("X-Amz-Credential")
  valid_603052 = validateParameter(valid_603052, JString, required = false,
                                 default = nil)
  if valid_603052 != nil:
    section.add "X-Amz-Credential", valid_603052
  var valid_603053 = header.getOrDefault("X-Amz-Security-Token")
  valid_603053 = validateParameter(valid_603053, JString, required = false,
                                 default = nil)
  if valid_603053 != nil:
    section.add "X-Amz-Security-Token", valid_603053
  var valid_603054 = header.getOrDefault("X-Amz-Algorithm")
  valid_603054 = validateParameter(valid_603054, JString, required = false,
                                 default = nil)
  if valid_603054 != nil:
    section.add "X-Amz-Algorithm", valid_603054
  var valid_603055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603055 = validateParameter(valid_603055, JString, required = false,
                                 default = nil)
  if valid_603055 != nil:
    section.add "X-Amz-SignedHeaders", valid_603055
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
  var valid_603056 = formData.getOrDefault("AttributeName")
  valid_603056 = validateParameter(valid_603056, JString, required = true,
                                 default = nil)
  if valid_603056 != nil:
    section.add "AttributeName", valid_603056
  var valid_603057 = formData.getOrDefault("TopicArn")
  valid_603057 = validateParameter(valid_603057, JString, required = true,
                                 default = nil)
  if valid_603057 != nil:
    section.add "TopicArn", valid_603057
  var valid_603058 = formData.getOrDefault("AttributeValue")
  valid_603058 = validateParameter(valid_603058, JString, required = false,
                                 default = nil)
  if valid_603058 != nil:
    section.add "AttributeValue", valid_603058
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603059: Call_PostSetTopicAttributes_603044; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  let valid = call_603059.validator(path, query, header, formData, body)
  let scheme = call_603059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603059.url(scheme.get, call_603059.host, call_603059.base,
                         call_603059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603059, url, valid)

proc call*(call_603060: Call_PostSetTopicAttributes_603044; AttributeName: string;
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
  var query_603061 = newJObject()
  var formData_603062 = newJObject()
  add(formData_603062, "AttributeName", newJString(AttributeName))
  add(formData_603062, "TopicArn", newJString(TopicArn))
  add(formData_603062, "AttributeValue", newJString(AttributeValue))
  add(query_603061, "Action", newJString(Action))
  add(query_603061, "Version", newJString(Version))
  result = call_603060.call(nil, query_603061, nil, formData_603062, nil)

var postSetTopicAttributes* = Call_PostSetTopicAttributes_603044(
    name: "postSetTopicAttributes", meth: HttpMethod.HttpPost,
    host: "sns.amazonaws.com", route: "/#Action=SetTopicAttributes",
    validator: validate_PostSetTopicAttributes_603045, base: "/",
    url: url_PostSetTopicAttributes_603046, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSetTopicAttributes_603026 = ref object of OpenApiRestCall_601389
proc url_GetSetTopicAttributes_603028(protocol: Scheme; host: string; base: string;
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

proc validate_GetSetTopicAttributes_603027(path: JsonNode; query: JsonNode;
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
  var valid_603029 = query.getOrDefault("AttributeValue")
  valid_603029 = validateParameter(valid_603029, JString, required = false,
                                 default = nil)
  if valid_603029 != nil:
    section.add "AttributeValue", valid_603029
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603030 = query.getOrDefault("Action")
  valid_603030 = validateParameter(valid_603030, JString, required = true,
                                 default = newJString("SetTopicAttributes"))
  if valid_603030 != nil:
    section.add "Action", valid_603030
  var valid_603031 = query.getOrDefault("AttributeName")
  valid_603031 = validateParameter(valid_603031, JString, required = true,
                                 default = nil)
  if valid_603031 != nil:
    section.add "AttributeName", valid_603031
  var valid_603032 = query.getOrDefault("Version")
  valid_603032 = validateParameter(valid_603032, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603032 != nil:
    section.add "Version", valid_603032
  var valid_603033 = query.getOrDefault("TopicArn")
  valid_603033 = validateParameter(valid_603033, JString, required = true,
                                 default = nil)
  if valid_603033 != nil:
    section.add "TopicArn", valid_603033
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603034 = header.getOrDefault("X-Amz-Signature")
  valid_603034 = validateParameter(valid_603034, JString, required = false,
                                 default = nil)
  if valid_603034 != nil:
    section.add "X-Amz-Signature", valid_603034
  var valid_603035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603035 = validateParameter(valid_603035, JString, required = false,
                                 default = nil)
  if valid_603035 != nil:
    section.add "X-Amz-Content-Sha256", valid_603035
  var valid_603036 = header.getOrDefault("X-Amz-Date")
  valid_603036 = validateParameter(valid_603036, JString, required = false,
                                 default = nil)
  if valid_603036 != nil:
    section.add "X-Amz-Date", valid_603036
  var valid_603037 = header.getOrDefault("X-Amz-Credential")
  valid_603037 = validateParameter(valid_603037, JString, required = false,
                                 default = nil)
  if valid_603037 != nil:
    section.add "X-Amz-Credential", valid_603037
  var valid_603038 = header.getOrDefault("X-Amz-Security-Token")
  valid_603038 = validateParameter(valid_603038, JString, required = false,
                                 default = nil)
  if valid_603038 != nil:
    section.add "X-Amz-Security-Token", valid_603038
  var valid_603039 = header.getOrDefault("X-Amz-Algorithm")
  valid_603039 = validateParameter(valid_603039, JString, required = false,
                                 default = nil)
  if valid_603039 != nil:
    section.add "X-Amz-Algorithm", valid_603039
  var valid_603040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603040 = validateParameter(valid_603040, JString, required = false,
                                 default = nil)
  if valid_603040 != nil:
    section.add "X-Amz-SignedHeaders", valid_603040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603041: Call_GetSetTopicAttributes_603026; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows a topic owner to set an attribute of the topic to a new value.
  ## 
  let valid = call_603041.validator(path, query, header, formData, body)
  let scheme = call_603041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603041.url(scheme.get, call_603041.host, call_603041.base,
                         call_603041.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603041, url, valid)

proc call*(call_603042: Call_GetSetTopicAttributes_603026; AttributeName: string;
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
  var query_603043 = newJObject()
  add(query_603043, "AttributeValue", newJString(AttributeValue))
  add(query_603043, "Action", newJString(Action))
  add(query_603043, "AttributeName", newJString(AttributeName))
  add(query_603043, "Version", newJString(Version))
  add(query_603043, "TopicArn", newJString(TopicArn))
  result = call_603042.call(nil, query_603043, nil, nil, nil)

var getSetTopicAttributes* = Call_GetSetTopicAttributes_603026(
    name: "getSetTopicAttributes", meth: HttpMethod.HttpGet,
    host: "sns.amazonaws.com", route: "/#Action=SetTopicAttributes",
    validator: validate_GetSetTopicAttributes_603027, base: "/",
    url: url_GetSetTopicAttributes_603028, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSubscribe_603088 = ref object of OpenApiRestCall_601389
proc url_PostSubscribe_603090(protocol: Scheme; host: string; base: string;
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

proc validate_PostSubscribe_603089(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603091 = query.getOrDefault("Action")
  valid_603091 = validateParameter(valid_603091, JString, required = true,
                                 default = newJString("Subscribe"))
  if valid_603091 != nil:
    section.add "Action", valid_603091
  var valid_603092 = query.getOrDefault("Version")
  valid_603092 = validateParameter(valid_603092, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603092 != nil:
    section.add "Version", valid_603092
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603093 = header.getOrDefault("X-Amz-Signature")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Signature", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Content-Sha256", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Date")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Date", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-Credential")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-Credential", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Security-Token")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Security-Token", valid_603097
  var valid_603098 = header.getOrDefault("X-Amz-Algorithm")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "X-Amz-Algorithm", valid_603098
  var valid_603099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-SignedHeaders", valid_603099
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
  var valid_603100 = formData.getOrDefault("Endpoint")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "Endpoint", valid_603100
  var valid_603101 = formData.getOrDefault("Attributes.0.key")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "Attributes.0.key", valid_603101
  var valid_603102 = formData.getOrDefault("Attributes.2.value")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "Attributes.2.value", valid_603102
  var valid_603103 = formData.getOrDefault("Attributes.2.key")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "Attributes.2.key", valid_603103
  assert formData != nil,
        "formData argument is necessary due to required `Protocol` field"
  var valid_603104 = formData.getOrDefault("Protocol")
  valid_603104 = validateParameter(valid_603104, JString, required = true,
                                 default = nil)
  if valid_603104 != nil:
    section.add "Protocol", valid_603104
  var valid_603105 = formData.getOrDefault("Attributes.0.value")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "Attributes.0.value", valid_603105
  var valid_603106 = formData.getOrDefault("Attributes.1.key")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "Attributes.1.key", valid_603106
  var valid_603107 = formData.getOrDefault("TopicArn")
  valid_603107 = validateParameter(valid_603107, JString, required = true,
                                 default = nil)
  if valid_603107 != nil:
    section.add "TopicArn", valid_603107
  var valid_603108 = formData.getOrDefault("ReturnSubscriptionArn")
  valid_603108 = validateParameter(valid_603108, JBool, required = false, default = nil)
  if valid_603108 != nil:
    section.add "ReturnSubscriptionArn", valid_603108
  var valid_603109 = formData.getOrDefault("Attributes.1.value")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "Attributes.1.value", valid_603109
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603110: Call_PostSubscribe_603088; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_603110.validator(path, query, header, formData, body)
  let scheme = call_603110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603110.url(scheme.get, call_603110.host, call_603110.base,
                         call_603110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603110, url, valid)

proc call*(call_603111: Call_PostSubscribe_603088; Protocol: string;
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
  var query_603112 = newJObject()
  var formData_603113 = newJObject()
  add(formData_603113, "Endpoint", newJString(Endpoint))
  add(formData_603113, "Attributes.0.key", newJString(Attributes0Key))
  add(formData_603113, "Attributes.2.value", newJString(Attributes2Value))
  add(formData_603113, "Attributes.2.key", newJString(Attributes2Key))
  add(formData_603113, "Protocol", newJString(Protocol))
  add(formData_603113, "Attributes.0.value", newJString(Attributes0Value))
  add(formData_603113, "Attributes.1.key", newJString(Attributes1Key))
  add(formData_603113, "TopicArn", newJString(TopicArn))
  add(formData_603113, "ReturnSubscriptionArn", newJBool(ReturnSubscriptionArn))
  add(query_603112, "Action", newJString(Action))
  add(query_603112, "Version", newJString(Version))
  add(formData_603113, "Attributes.1.value", newJString(Attributes1Value))
  result = call_603111.call(nil, query_603112, nil, formData_603113, nil)

var postSubscribe* = Call_PostSubscribe_603088(name: "postSubscribe",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=Subscribe", validator: validate_PostSubscribe_603089,
    base: "/", url: url_PostSubscribe_603090, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSubscribe_603063 = ref object of OpenApiRestCall_601389
proc url_GetSubscribe_603065(protocol: Scheme; host: string; base: string;
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

proc validate_GetSubscribe_603064(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603066 = query.getOrDefault("Attributes.1.key")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "Attributes.1.key", valid_603066
  var valid_603067 = query.getOrDefault("Attributes.0.value")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "Attributes.0.value", valid_603067
  var valid_603068 = query.getOrDefault("Endpoint")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "Endpoint", valid_603068
  var valid_603069 = query.getOrDefault("Attributes.0.key")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "Attributes.0.key", valid_603069
  var valid_603070 = query.getOrDefault("Attributes.2.value")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "Attributes.2.value", valid_603070
  var valid_603071 = query.getOrDefault("Attributes.1.value")
  valid_603071 = validateParameter(valid_603071, JString, required = false,
                                 default = nil)
  if valid_603071 != nil:
    section.add "Attributes.1.value", valid_603071
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603072 = query.getOrDefault("Action")
  valid_603072 = validateParameter(valid_603072, JString, required = true,
                                 default = newJString("Subscribe"))
  if valid_603072 != nil:
    section.add "Action", valid_603072
  var valid_603073 = query.getOrDefault("Protocol")
  valid_603073 = validateParameter(valid_603073, JString, required = true,
                                 default = nil)
  if valid_603073 != nil:
    section.add "Protocol", valid_603073
  var valid_603074 = query.getOrDefault("ReturnSubscriptionArn")
  valid_603074 = validateParameter(valid_603074, JBool, required = false, default = nil)
  if valid_603074 != nil:
    section.add "ReturnSubscriptionArn", valid_603074
  var valid_603075 = query.getOrDefault("Version")
  valid_603075 = validateParameter(valid_603075, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603075 != nil:
    section.add "Version", valid_603075
  var valid_603076 = query.getOrDefault("Attributes.2.key")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "Attributes.2.key", valid_603076
  var valid_603077 = query.getOrDefault("TopicArn")
  valid_603077 = validateParameter(valid_603077, JString, required = true,
                                 default = nil)
  if valid_603077 != nil:
    section.add "TopicArn", valid_603077
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603078 = header.getOrDefault("X-Amz-Signature")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Signature", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Content-Sha256", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Date")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Date", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-Credential")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-Credential", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Security-Token")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Security-Token", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-Algorithm")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Algorithm", valid_603083
  var valid_603084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-SignedHeaders", valid_603084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603085: Call_GetSubscribe_603063; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Prepares to subscribe an endpoint by sending the endpoint a confirmation message. To actually create a subscription, the endpoint owner must call the <code>ConfirmSubscription</code> action with the token from the confirmation message. Confirmation tokens are valid for three days.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_603085.validator(path, query, header, formData, body)
  let scheme = call_603085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603085.url(scheme.get, call_603085.host, call_603085.base,
                         call_603085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603085, url, valid)

proc call*(call_603086: Call_GetSubscribe_603063; Protocol: string; TopicArn: string;
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
  var query_603087 = newJObject()
  add(query_603087, "Attributes.1.key", newJString(Attributes1Key))
  add(query_603087, "Attributes.0.value", newJString(Attributes0Value))
  add(query_603087, "Endpoint", newJString(Endpoint))
  add(query_603087, "Attributes.0.key", newJString(Attributes0Key))
  add(query_603087, "Attributes.2.value", newJString(Attributes2Value))
  add(query_603087, "Attributes.1.value", newJString(Attributes1Value))
  add(query_603087, "Action", newJString(Action))
  add(query_603087, "Protocol", newJString(Protocol))
  add(query_603087, "ReturnSubscriptionArn", newJBool(ReturnSubscriptionArn))
  add(query_603087, "Version", newJString(Version))
  add(query_603087, "Attributes.2.key", newJString(Attributes2Key))
  add(query_603087, "TopicArn", newJString(TopicArn))
  result = call_603086.call(nil, query_603087, nil, nil, nil)

var getSubscribe* = Call_GetSubscribe_603063(name: "getSubscribe",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=Subscribe", validator: validate_GetSubscribe_603064, base: "/",
    url: url_GetSubscribe_603065, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTagResource_603131 = ref object of OpenApiRestCall_601389
proc url_PostTagResource_603133(protocol: Scheme; host: string; base: string;
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

proc validate_PostTagResource_603132(path: JsonNode; query: JsonNode;
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
  var valid_603134 = query.getOrDefault("Action")
  valid_603134 = validateParameter(valid_603134, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_603134 != nil:
    section.add "Action", valid_603134
  var valid_603135 = query.getOrDefault("Version")
  valid_603135 = validateParameter(valid_603135, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603135 != nil:
    section.add "Version", valid_603135
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603136 = header.getOrDefault("X-Amz-Signature")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Signature", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Content-Sha256", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Date")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Date", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Credential")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Credential", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Security-Token")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Security-Token", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-Algorithm")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-Algorithm", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-SignedHeaders", valid_603142
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic to which to add tags.
  ##   Tags: JArray (required)
  ##       : The tags to be added to the specified topic. A tag consists of a required key and an optional value.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_603143 = formData.getOrDefault("ResourceArn")
  valid_603143 = validateParameter(valid_603143, JString, required = true,
                                 default = nil)
  if valid_603143 != nil:
    section.add "ResourceArn", valid_603143
  var valid_603144 = formData.getOrDefault("Tags")
  valid_603144 = validateParameter(valid_603144, JArray, required = true, default = nil)
  if valid_603144 != nil:
    section.add "Tags", valid_603144
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603145: Call_PostTagResource_603131; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account, per AWS region. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul>
  ## 
  let valid = call_603145.validator(path, query, header, formData, body)
  let scheme = call_603145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603145.url(scheme.get, call_603145.host, call_603145.base,
                         call_603145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603145, url, valid)

proc call*(call_603146: Call_PostTagResource_603131; ResourceArn: string;
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
  var query_603147 = newJObject()
  var formData_603148 = newJObject()
  add(formData_603148, "ResourceArn", newJString(ResourceArn))
  add(query_603147, "Action", newJString(Action))
  if Tags != nil:
    formData_603148.add "Tags", Tags
  add(query_603147, "Version", newJString(Version))
  result = call_603146.call(nil, query_603147, nil, formData_603148, nil)

var postTagResource* = Call_PostTagResource_603131(name: "postTagResource",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_PostTagResource_603132,
    base: "/", url: url_PostTagResource_603133, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagResource_603114 = ref object of OpenApiRestCall_601389
proc url_GetTagResource_603116(protocol: Scheme; host: string; base: string;
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

proc validate_GetTagResource_603115(path: JsonNode; query: JsonNode;
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
  var valid_603117 = query.getOrDefault("Tags")
  valid_603117 = validateParameter(valid_603117, JArray, required = true, default = nil)
  if valid_603117 != nil:
    section.add "Tags", valid_603117
  var valid_603118 = query.getOrDefault("ResourceArn")
  valid_603118 = validateParameter(valid_603118, JString, required = true,
                                 default = nil)
  if valid_603118 != nil:
    section.add "ResourceArn", valid_603118
  var valid_603119 = query.getOrDefault("Action")
  valid_603119 = validateParameter(valid_603119, JString, required = true,
                                 default = newJString("TagResource"))
  if valid_603119 != nil:
    section.add "Action", valid_603119
  var valid_603120 = query.getOrDefault("Version")
  valid_603120 = validateParameter(valid_603120, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603120 != nil:
    section.add "Version", valid_603120
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603121 = header.getOrDefault("X-Amz-Signature")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Signature", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Content-Sha256", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Date")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Date", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Credential")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Credential", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Security-Token")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Security-Token", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-Algorithm")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-Algorithm", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-SignedHeaders", valid_603127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603128: Call_GetTagResource_603114; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add tags to the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.</p> <p>When you use topic tags, keep the following guidelines in mind:</p> <ul> <li> <p>Adding more than 50 tags to a topic isn't recommended.</p> </li> <li> <p>Tags don't have any semantic meaning. Amazon SNS interprets tags as character strings.</p> </li> <li> <p>Tags are case-sensitive.</p> </li> <li> <p>A new tag with a key identical to that of an existing tag overwrites the existing tag.</p> </li> <li> <p>Tagging actions are limited to 10 TPS per AWS account, per AWS region. If your application requires a higher throughput, file a <a href="https://console.aws.amazon.com/support/home#/case/create?issueType=technical">technical support request</a>.</p> </li> </ul>
  ## 
  let valid = call_603128.validator(path, query, header, formData, body)
  let scheme = call_603128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603128.url(scheme.get, call_603128.host, call_603128.base,
                         call_603128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603128, url, valid)

proc call*(call_603129: Call_GetTagResource_603114; Tags: JsonNode;
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
  var query_603130 = newJObject()
  if Tags != nil:
    query_603130.add "Tags", Tags
  add(query_603130, "ResourceArn", newJString(ResourceArn))
  add(query_603130, "Action", newJString(Action))
  add(query_603130, "Version", newJString(Version))
  result = call_603129.call(nil, query_603130, nil, nil, nil)

var getTagResource* = Call_GetTagResource_603114(name: "getTagResource",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=TagResource", validator: validate_GetTagResource_603115,
    base: "/", url: url_GetTagResource_603116, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUnsubscribe_603165 = ref object of OpenApiRestCall_601389
proc url_PostUnsubscribe_603167(protocol: Scheme; host: string; base: string;
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

proc validate_PostUnsubscribe_603166(path: JsonNode; query: JsonNode;
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
  var valid_603168 = query.getOrDefault("Action")
  valid_603168 = validateParameter(valid_603168, JString, required = true,
                                 default = newJString("Unsubscribe"))
  if valid_603168 != nil:
    section.add "Action", valid_603168
  var valid_603169 = query.getOrDefault("Version")
  valid_603169 = validateParameter(valid_603169, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603169 != nil:
    section.add "Version", valid_603169
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603170 = header.getOrDefault("X-Amz-Signature")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Signature", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-Content-Sha256", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Date")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Date", valid_603172
  var valid_603173 = header.getOrDefault("X-Amz-Credential")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "X-Amz-Credential", valid_603173
  var valid_603174 = header.getOrDefault("X-Amz-Security-Token")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-Security-Token", valid_603174
  var valid_603175 = header.getOrDefault("X-Amz-Algorithm")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "X-Amz-Algorithm", valid_603175
  var valid_603176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "X-Amz-SignedHeaders", valid_603176
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionArn: JString (required)
  ##                  : The ARN of the subscription to be deleted.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionArn` field"
  var valid_603177 = formData.getOrDefault("SubscriptionArn")
  valid_603177 = validateParameter(valid_603177, JString, required = true,
                                 default = nil)
  if valid_603177 != nil:
    section.add "SubscriptionArn", valid_603177
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603178: Call_PostUnsubscribe_603165; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_603178.validator(path, query, header, formData, body)
  let scheme = call_603178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603178.url(scheme.get, call_603178.host, call_603178.base,
                         call_603178.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603178, url, valid)

proc call*(call_603179: Call_PostUnsubscribe_603165; SubscriptionArn: string;
          Action: string = "Unsubscribe"; Version: string = "2010-03-31"): Recallable =
  ## postUnsubscribe
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to be deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603180 = newJObject()
  var formData_603181 = newJObject()
  add(formData_603181, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_603180, "Action", newJString(Action))
  add(query_603180, "Version", newJString(Version))
  result = call_603179.call(nil, query_603180, nil, formData_603181, nil)

var postUnsubscribe* = Call_PostUnsubscribe_603165(name: "postUnsubscribe",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=Unsubscribe", validator: validate_PostUnsubscribe_603166,
    base: "/", url: url_PostUnsubscribe_603167, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUnsubscribe_603149 = ref object of OpenApiRestCall_601389
proc url_GetUnsubscribe_603151(protocol: Scheme; host: string; base: string;
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

proc validate_GetUnsubscribe_603150(path: JsonNode; query: JsonNode;
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
  var valid_603152 = query.getOrDefault("SubscriptionArn")
  valid_603152 = validateParameter(valid_603152, JString, required = true,
                                 default = nil)
  if valid_603152 != nil:
    section.add "SubscriptionArn", valid_603152
  var valid_603153 = query.getOrDefault("Action")
  valid_603153 = validateParameter(valid_603153, JString, required = true,
                                 default = newJString("Unsubscribe"))
  if valid_603153 != nil:
    section.add "Action", valid_603153
  var valid_603154 = query.getOrDefault("Version")
  valid_603154 = validateParameter(valid_603154, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603154 != nil:
    section.add "Version", valid_603154
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603155 = header.getOrDefault("X-Amz-Signature")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Signature", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-Content-Sha256", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Date")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Date", valid_603157
  var valid_603158 = header.getOrDefault("X-Amz-Credential")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "X-Amz-Credential", valid_603158
  var valid_603159 = header.getOrDefault("X-Amz-Security-Token")
  valid_603159 = validateParameter(valid_603159, JString, required = false,
                                 default = nil)
  if valid_603159 != nil:
    section.add "X-Amz-Security-Token", valid_603159
  var valid_603160 = header.getOrDefault("X-Amz-Algorithm")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = nil)
  if valid_603160 != nil:
    section.add "X-Amz-Algorithm", valid_603160
  var valid_603161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603161 = validateParameter(valid_603161, JString, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "X-Amz-SignedHeaders", valid_603161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603162: Call_GetUnsubscribe_603149; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ## 
  let valid = call_603162.validator(path, query, header, formData, body)
  let scheme = call_603162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603162.url(scheme.get, call_603162.host, call_603162.base,
                         call_603162.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603162, url, valid)

proc call*(call_603163: Call_GetUnsubscribe_603149; SubscriptionArn: string;
          Action: string = "Unsubscribe"; Version: string = "2010-03-31"): Recallable =
  ## getUnsubscribe
  ## <p>Deletes a subscription. If the subscription requires authentication for deletion, only the owner of the subscription or the topic's owner can unsubscribe, and an AWS signature is required. If the <code>Unsubscribe</code> call does not require authentication and the requester is not the subscription owner, a final cancellation message is delivered to the endpoint, so that the endpoint owner can easily resubscribe to the topic if the <code>Unsubscribe</code> request was unintended.</p> <p>This action is throttled at 100 transactions per second (TPS).</p>
  ##   SubscriptionArn: string (required)
  ##                  : The ARN of the subscription to be deleted.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603164 = newJObject()
  add(query_603164, "SubscriptionArn", newJString(SubscriptionArn))
  add(query_603164, "Action", newJString(Action))
  add(query_603164, "Version", newJString(Version))
  result = call_603163.call(nil, query_603164, nil, nil, nil)

var getUnsubscribe* = Call_GetUnsubscribe_603149(name: "getUnsubscribe",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=Unsubscribe", validator: validate_GetUnsubscribe_603150,
    base: "/", url: url_GetUnsubscribe_603151, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUntagResource_603199 = ref object of OpenApiRestCall_601389
proc url_PostUntagResource_603201(protocol: Scheme; host: string; base: string;
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

proc validate_PostUntagResource_603200(path: JsonNode; query: JsonNode;
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
  var valid_603202 = query.getOrDefault("Action")
  valid_603202 = validateParameter(valid_603202, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_603202 != nil:
    section.add "Action", valid_603202
  var valid_603203 = query.getOrDefault("Version")
  valid_603203 = validateParameter(valid_603203, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603203 != nil:
    section.add "Version", valid_603203
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603204 = header.getOrDefault("X-Amz-Signature")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "X-Amz-Signature", valid_603204
  var valid_603205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-Content-Sha256", valid_603205
  var valid_603206 = header.getOrDefault("X-Amz-Date")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-Date", valid_603206
  var valid_603207 = header.getOrDefault("X-Amz-Credential")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "X-Amz-Credential", valid_603207
  var valid_603208 = header.getOrDefault("X-Amz-Security-Token")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "X-Amz-Security-Token", valid_603208
  var valid_603209 = header.getOrDefault("X-Amz-Algorithm")
  valid_603209 = validateParameter(valid_603209, JString, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "X-Amz-Algorithm", valid_603209
  var valid_603210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-SignedHeaders", valid_603210
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##          : The list of tag keys to remove from the specified topic.
  ##   ResourceArn: JString (required)
  ##              : The ARN of the topic from which to remove tags.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_603211 = formData.getOrDefault("TagKeys")
  valid_603211 = validateParameter(valid_603211, JArray, required = true, default = nil)
  if valid_603211 != nil:
    section.add "TagKeys", valid_603211
  var valid_603212 = formData.getOrDefault("ResourceArn")
  valid_603212 = validateParameter(valid_603212, JString, required = true,
                                 default = nil)
  if valid_603212 != nil:
    section.add "ResourceArn", valid_603212
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603213: Call_PostUntagResource_603199; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  let valid = call_603213.validator(path, query, header, formData, body)
  let scheme = call_603213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603213.url(scheme.get, call_603213.host, call_603213.base,
                         call_603213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603213, url, valid)

proc call*(call_603214: Call_PostUntagResource_603199; TagKeys: JsonNode;
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
  var query_603215 = newJObject()
  var formData_603216 = newJObject()
  if TagKeys != nil:
    formData_603216.add "TagKeys", TagKeys
  add(formData_603216, "ResourceArn", newJString(ResourceArn))
  add(query_603215, "Action", newJString(Action))
  add(query_603215, "Version", newJString(Version))
  result = call_603214.call(nil, query_603215, nil, formData_603216, nil)

var postUntagResource* = Call_PostUntagResource_603199(name: "postUntagResource",
    meth: HttpMethod.HttpPost, host: "sns.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_PostUntagResource_603200,
    base: "/", url: url_PostUntagResource_603201,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUntagResource_603182 = ref object of OpenApiRestCall_601389
proc url_GetUntagResource_603184(protocol: Scheme; host: string; base: string;
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

proc validate_GetUntagResource_603183(path: JsonNode; query: JsonNode;
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
  var valid_603185 = query.getOrDefault("TagKeys")
  valid_603185 = validateParameter(valid_603185, JArray, required = true, default = nil)
  if valid_603185 != nil:
    section.add "TagKeys", valid_603185
  var valid_603186 = query.getOrDefault("ResourceArn")
  valid_603186 = validateParameter(valid_603186, JString, required = true,
                                 default = nil)
  if valid_603186 != nil:
    section.add "ResourceArn", valid_603186
  var valid_603187 = query.getOrDefault("Action")
  valid_603187 = validateParameter(valid_603187, JString, required = true,
                                 default = newJString("UntagResource"))
  if valid_603187 != nil:
    section.add "Action", valid_603187
  var valid_603188 = query.getOrDefault("Version")
  valid_603188 = validateParameter(valid_603188, JString, required = true,
                                 default = newJString("2010-03-31"))
  if valid_603188 != nil:
    section.add "Version", valid_603188
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_603189 = header.getOrDefault("X-Amz-Signature")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-Signature", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-Content-Sha256", valid_603190
  var valid_603191 = header.getOrDefault("X-Amz-Date")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "X-Amz-Date", valid_603191
  var valid_603192 = header.getOrDefault("X-Amz-Credential")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-Credential", valid_603192
  var valid_603193 = header.getOrDefault("X-Amz-Security-Token")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "X-Amz-Security-Token", valid_603193
  var valid_603194 = header.getOrDefault("X-Amz-Algorithm")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "X-Amz-Algorithm", valid_603194
  var valid_603195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-SignedHeaders", valid_603195
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603196: Call_GetUntagResource_603182; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from the specified Amazon SNS topic. For an overview, see <a href="https://docs.aws.amazon.com/sns/latest/dg/sns-tags.html">Amazon SNS Tags</a> in the <i>Amazon SNS Developer Guide</i>.
  ## 
  let valid = call_603196.validator(path, query, header, formData, body)
  let scheme = call_603196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603196.url(scheme.get, call_603196.host, call_603196.base,
                         call_603196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603196, url, valid)

proc call*(call_603197: Call_GetUntagResource_603182; TagKeys: JsonNode;
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
  var query_603198 = newJObject()
  if TagKeys != nil:
    query_603198.add "TagKeys", TagKeys
  add(query_603198, "ResourceArn", newJString(ResourceArn))
  add(query_603198, "Action", newJString(Action))
  add(query_603198, "Version", newJString(Version))
  result = call_603197.call(nil, query_603198, nil, nil, nil)

var getUntagResource* = Call_GetUntagResource_603182(name: "getUntagResource",
    meth: HttpMethod.HttpGet, host: "sns.amazonaws.com",
    route: "/#Action=UntagResource", validator: validate_GetUntagResource_603183,
    base: "/", url: url_GetUntagResource_603184,
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
