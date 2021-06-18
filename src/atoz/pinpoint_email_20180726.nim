
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Pinpoint Email Service
## version: 2018-07-26
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon Pinpoint Email Service</fullname> <p>Welcome to the <i>Amazon Pinpoint Email API Reference</i>. This guide provides information about the Amazon Pinpoint Email API (version 1.0), including supported operations, data types, parameters, and schemas.</p> <p> <a href="https://aws.amazon.com/pinpoint">Amazon Pinpoint</a> is an AWS service that you can use to engage with your customers across multiple messaging channels. You can use Amazon Pinpoint to send email, SMS text messages, voice messages, and push notifications. The Amazon Pinpoint Email API provides programmatic access to options that are unique to the email channel and supplement the options provided by the Amazon Pinpoint API.</p> <p>If you're new to Amazon Pinpoint, you might find it helpful to also review the <a href="https://docs.aws.amazon.com/pinpoint/latest/developerguide/welcome.html">Amazon Pinpoint Developer Guide</a>. The <i>Amazon Pinpoint Developer Guide</i> provides tutorials, code samples, and procedures that demonstrate how to use Amazon Pinpoint features programmatically and how to integrate Amazon Pinpoint functionality into mobile apps and other types of applications. The guide also provides information about key topics such as Amazon Pinpoint integration with other AWS services and the limits that apply to using the service.</p> <p>The Amazon Pinpoint Email API is available in several AWS Regions and it provides an endpoint for each of these Regions. For a list of all the Regions and endpoints where the API is currently available, see <a href="https://docs.aws.amazon.com/general/latest/gr/rande.html#pinpoint_region">AWS Service Endpoints</a> in the <i>Amazon Web Services General Reference</i>. To learn more about AWS Regions, see <a href="https://docs.aws.amazon.com/general/latest/gr/rande-manage.html">Managing AWS Regions</a> in the <i>Amazon Web Services General Reference</i>.</p> <p>In each Region, AWS maintains multiple Availability Zones. These Availability Zones are physically isolated from each other, but are united by private, low-latency, high-throughput, and highly redundant network connections. These Availability Zones enable us to provide very high levels of availability and redundancy, while also minimizing latency. To learn more about the number of Availability Zones that are available in each Region, see <a href="http://aws.amazon.com/about-aws/global-infrastructure/">AWS Global Infrastructure</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/email/
type
  Scheme* {.pure.} = enum
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

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "email.ap-northeast-1.amazonaws.com", "ap-southeast-1": "email.ap-southeast-1.amazonaws.com",
                               "us-west-2": "email.us-west-2.amazonaws.com",
                               "eu-west-2": "email.eu-west-2.amazonaws.com", "ap-northeast-3": "email.ap-northeast-3.amazonaws.com", "eu-central-1": "email.eu-central-1.amazonaws.com",
                               "us-east-2": "email.us-east-2.amazonaws.com",
                               "us-east-1": "email.us-east-1.amazonaws.com", "cn-northwest-1": "email.cn-northwest-1.amazonaws.com.cn",
                               "ap-south-1": "email.ap-south-1.amazonaws.com",
                               "eu-north-1": "email.eu-north-1.amazonaws.com", "ap-northeast-2": "email.ap-northeast-2.amazonaws.com",
                               "us-west-1": "email.us-west-1.amazonaws.com", "us-gov-east-1": "email.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "email.eu-west-3.amazonaws.com", "cn-north-1": "email.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "email.sa-east-1.amazonaws.com",
                               "eu-west-1": "email.eu-west-1.amazonaws.com", "us-gov-west-1": "email.us-gov-west-1.amazonaws.com", "ap-southeast-2": "email.ap-southeast-2.amazonaws.com", "ca-central-1": "email.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "email.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "email.ap-southeast-1.amazonaws.com",
      "us-west-2": "email.us-west-2.amazonaws.com",
      "eu-west-2": "email.eu-west-2.amazonaws.com",
      "ap-northeast-3": "email.ap-northeast-3.amazonaws.com",
      "eu-central-1": "email.eu-central-1.amazonaws.com",
      "us-east-2": "email.us-east-2.amazonaws.com",
      "us-east-1": "email.us-east-1.amazonaws.com",
      "cn-northwest-1": "email.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "email.ap-south-1.amazonaws.com",
      "eu-north-1": "email.eu-north-1.amazonaws.com",
      "ap-northeast-2": "email.ap-northeast-2.amazonaws.com",
      "us-west-1": "email.us-west-1.amazonaws.com",
      "us-gov-east-1": "email.us-gov-east-1.amazonaws.com",
      "eu-west-3": "email.eu-west-3.amazonaws.com",
      "cn-north-1": "email.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "email.sa-east-1.amazonaws.com",
      "eu-west-1": "email.eu-west-1.amazonaws.com",
      "us-gov-west-1": "email.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "email.ap-southeast-2.amazonaws.com",
      "ca-central-1": "email.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "pinpoint-email"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateConfigurationSet_402656477 = ref object of OpenApiRestCall_402656044
proc url_CreateConfigurationSet_402656479(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConfigurationSet_402656478(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Create a configuration set. <i>Configuration sets</i> are groups of rules that you can apply to the emails you send using Amazon Pinpoint. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656480 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656480 = validateParameter(valid_402656480, JString,
                                      required = false, default = nil)
  if valid_402656480 != nil:
    section.add "X-Amz-Security-Token", valid_402656480
  var valid_402656481 = header.getOrDefault("X-Amz-Signature")
  valid_402656481 = validateParameter(valid_402656481, JString,
                                      required = false, default = nil)
  if valid_402656481 != nil:
    section.add "X-Amz-Signature", valid_402656481
  var valid_402656482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656482 = validateParameter(valid_402656482, JString,
                                      required = false, default = nil)
  if valid_402656482 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656482
  var valid_402656483 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656483 = validateParameter(valid_402656483, JString,
                                      required = false, default = nil)
  if valid_402656483 != nil:
    section.add "X-Amz-Algorithm", valid_402656483
  var valid_402656484 = header.getOrDefault("X-Amz-Date")
  valid_402656484 = validateParameter(valid_402656484, JString,
                                      required = false, default = nil)
  if valid_402656484 != nil:
    section.add "X-Amz-Date", valid_402656484
  var valid_402656485 = header.getOrDefault("X-Amz-Credential")
  valid_402656485 = validateParameter(valid_402656485, JString,
                                      required = false, default = nil)
  if valid_402656485 != nil:
    section.add "X-Amz-Credential", valid_402656485
  var valid_402656486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656486 = validateParameter(valid_402656486, JString,
                                      required = false, default = nil)
  if valid_402656486 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656488: Call_CreateConfigurationSet_402656477;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a configuration set. <i>Configuration sets</i> are groups of rules that you can apply to the emails you send using Amazon Pinpoint. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email. 
                                                                                         ## 
  let valid = call_402656488.validator(path, query, header, formData, body, _)
  let scheme = call_402656488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656488.makeUrl(scheme.get, call_402656488.host, call_402656488.base,
                                   call_402656488.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656488, uri, valid, _)

proc call*(call_402656489: Call_CreateConfigurationSet_402656477; body: JsonNode): Recallable =
  ## createConfigurationSet
  ## Create a configuration set. <i>Configuration sets</i> are groups of rules that you can apply to the emails you send using Amazon Pinpoint. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email. 
  ##   
                                                                                                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402656490 = newJObject()
  if body != nil:
    body_402656490 = body
  result = call_402656489.call(nil, nil, nil, nil, body_402656490)

var createConfigurationSet* = Call_CreateConfigurationSet_402656477(
    name: "createConfigurationSet", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets",
    validator: validate_CreateConfigurationSet_402656478, base: "/",
    makeUrl: url_CreateConfigurationSet_402656479,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationSets_402656294 = ref object of OpenApiRestCall_402656044
proc url_ListConfigurationSets_402656296(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConfigurationSets_402656295(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>List all of the configuration sets associated with your Amazon Pinpoint account in the current region.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JInt
                                  ##           : The number of results to show in a single call to <code>ListConfigurationSets</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   
                                                                                                                                                                                                                                                                                                                                       ## NextToken: JString
                                                                                                                                                                                                                                                                                                                                       ##            
                                                                                                                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                                                                                                                       ## A 
                                                                                                                                                                                                                                                                                                                                       ## token 
                                                                                                                                                                                                                                                                                                                                       ## returned 
                                                                                                                                                                                                                                                                                                                                       ## from 
                                                                                                                                                                                                                                                                                                                                       ## a 
                                                                                                                                                                                                                                                                                                                                       ## previous 
                                                                                                                                                                                                                                                                                                                                       ## call 
                                                                                                                                                                                                                                                                                                                                       ## to 
                                                                                                                                                                                                                                                                                                                                       ## <code>ListConfigurationSets</code> 
                                                                                                                                                                                                                                                                                                                                       ## to 
                                                                                                                                                                                                                                                                                                                                       ## indicate 
                                                                                                                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                                                                                                                       ## position 
                                                                                                                                                                                                                                                                                                                                       ## in 
                                                                                                                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                                                                                                                       ## list 
                                                                                                                                                                                                                                                                                                                                       ## of 
                                                                                                                                                                                                                                                                                                                                       ## configuration 
                                                                                                                                                                                                                                                                                                                                       ## sets.
  section = newJObject()
  var valid_402656375 = query.getOrDefault("PageSize")
  valid_402656375 = validateParameter(valid_402656375, JInt, required = false,
                                      default = nil)
  if valid_402656375 != nil:
    section.add "PageSize", valid_402656375
  var valid_402656376 = query.getOrDefault("NextToken")
  valid_402656376 = validateParameter(valid_402656376, JString,
                                      required = false, default = nil)
  if valid_402656376 != nil:
    section.add "NextToken", valid_402656376
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656377 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656377 = validateParameter(valid_402656377, JString,
                                      required = false, default = nil)
  if valid_402656377 != nil:
    section.add "X-Amz-Security-Token", valid_402656377
  var valid_402656378 = header.getOrDefault("X-Amz-Signature")
  valid_402656378 = validateParameter(valid_402656378, JString,
                                      required = false, default = nil)
  if valid_402656378 != nil:
    section.add "X-Amz-Signature", valid_402656378
  var valid_402656379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656379 = validateParameter(valid_402656379, JString,
                                      required = false, default = nil)
  if valid_402656379 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656379
  var valid_402656380 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656380 = validateParameter(valid_402656380, JString,
                                      required = false, default = nil)
  if valid_402656380 != nil:
    section.add "X-Amz-Algorithm", valid_402656380
  var valid_402656381 = header.getOrDefault("X-Amz-Date")
  valid_402656381 = validateParameter(valid_402656381, JString,
                                      required = false, default = nil)
  if valid_402656381 != nil:
    section.add "X-Amz-Date", valid_402656381
  var valid_402656382 = header.getOrDefault("X-Amz-Credential")
  valid_402656382 = validateParameter(valid_402656382, JString,
                                      required = false, default = nil)
  if valid_402656382 != nil:
    section.add "X-Amz-Credential", valid_402656382
  var valid_402656383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656383 = validateParameter(valid_402656383, JString,
                                      required = false, default = nil)
  if valid_402656383 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656397: Call_ListConfigurationSets_402656294;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>List all of the configuration sets associated with your Amazon Pinpoint account in the current region.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
                                                                                         ## 
  let valid = call_402656397.validator(path, query, header, formData, body, _)
  let scheme = call_402656397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656397.makeUrl(scheme.get, call_402656397.host, call_402656397.base,
                                   call_402656397.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656397, uri, valid, _)

proc call*(call_402656446: Call_ListConfigurationSets_402656294;
           PageSize: int = 0; NextToken: string = ""): Recallable =
  ## listConfigurationSets
  ## <p>List all of the configuration sets associated with your Amazon Pinpoint account in the current region.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## PageSize: int
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ##           
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## number 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## results 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## show 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## single 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## call 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## <code>ListConfigurationSets</code>. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## If 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## number 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## results 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## larger 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## than 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## number 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## specified 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## this 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## parameter, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## then 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## response 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## includes 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## <code>NextToken</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## element, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## which 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## can 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## use 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## obtain 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## additional 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## results.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## A 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## token 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## returned 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## from 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## previous 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## call 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## <code>ListConfigurationSets</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## indicate 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## position 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## list 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## sets.
  var query_402656447 = newJObject()
  add(query_402656447, "PageSize", newJInt(PageSize))
  add(query_402656447, "NextToken", newJString(NextToken))
  result = call_402656446.call(nil, query_402656447, nil, nil, nil)

var listConfigurationSets* = Call_ListConfigurationSets_402656294(
    name: "listConfigurationSets", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets",
    validator: validate_ListConfigurationSets_402656295, base: "/",
    makeUrl: url_ListConfigurationSets_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfigurationSetEventDestination_402656516 = ref object of OpenApiRestCall_402656044
proc url_CreateConfigurationSetEventDestination_402656518(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
         "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/configuration-sets/"),
                 (kind: VariableSegment, value: "ConfigurationSetName"),
                 (kind: ConstantSegment, value: "/event-destinations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateConfigurationSetEventDestination_402656517(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Create an event destination. In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p> <p>A single configuration set can include more than one event destination.</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
                                 ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_402656519 = path.getOrDefault("ConfigurationSetName")
  valid_402656519 = validateParameter(valid_402656519, JString, required = true,
                                      default = nil)
  if valid_402656519 != nil:
    section.add "ConfigurationSetName", valid_402656519
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656520 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656520 = validateParameter(valid_402656520, JString,
                                      required = false, default = nil)
  if valid_402656520 != nil:
    section.add "X-Amz-Security-Token", valid_402656520
  var valid_402656521 = header.getOrDefault("X-Amz-Signature")
  valid_402656521 = validateParameter(valid_402656521, JString,
                                      required = false, default = nil)
  if valid_402656521 != nil:
    section.add "X-Amz-Signature", valid_402656521
  var valid_402656522 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656522 = validateParameter(valid_402656522, JString,
                                      required = false, default = nil)
  if valid_402656522 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Algorithm", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Date")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Date", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Credential")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Credential", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656526
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656528: Call_CreateConfigurationSetEventDestination_402656516;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Create an event destination. In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p> <p>A single configuration set can include more than one event destination.</p>
                                                                                         ## 
  let valid = call_402656528.validator(path, query, header, formData, body, _)
  let scheme = call_402656528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656528.makeUrl(scheme.get, call_402656528.host, call_402656528.base,
                                   call_402656528.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656528, uri, valid, _)

proc call*(call_402656529: Call_CreateConfigurationSetEventDestination_402656516;
           ConfigurationSetName: string; body: JsonNode): Recallable =
  ## createConfigurationSetEventDestination
  ## <p>Create an event destination. In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p> <p>A single configuration set can include more than one event destination.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## ConfigurationSetName: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ##                       
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## <p>The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## set.</p> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## <p>In 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## Pinpoint, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## <i>configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## sets</i> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## groups 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## rules 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## can 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## apply 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## emails 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## send. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## You 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## apply 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## an 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## email 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## by 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## including 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## reference 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## headers 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## email. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## When 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## apply 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## an 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## email, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## all 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## rules 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## applied 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## email.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var path_402656530 = newJObject()
  var body_402656531 = newJObject()
  add(path_402656530, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_402656531 = body
  result = call_402656529.call(path_402656530, nil, nil, nil, body_402656531)

var createConfigurationSetEventDestination* = Call_CreateConfigurationSetEventDestination_402656516(
    name: "createConfigurationSetEventDestination", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/event-destinations",
    validator: validate_CreateConfigurationSetEventDestination_402656517,
    base: "/", makeUrl: url_CreateConfigurationSetEventDestination_402656518,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigurationSetEventDestinations_402656491 = ref object of OpenApiRestCall_402656044
proc url_GetConfigurationSetEventDestinations_402656493(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
         "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/configuration-sets/"),
                 (kind: VariableSegment, value: "ConfigurationSetName"),
                 (kind: ConstantSegment, value: "/event-destinations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetConfigurationSetEventDestinations_402656492(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Retrieve a list of event destinations that are associated with a configuration set.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
                                 ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_402656505 = path.getOrDefault("ConfigurationSetName")
  valid_402656505 = validateParameter(valid_402656505, JString, required = true,
                                      default = nil)
  if valid_402656505 != nil:
    section.add "ConfigurationSetName", valid_402656505
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656506 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656506 = validateParameter(valid_402656506, JString,
                                      required = false, default = nil)
  if valid_402656506 != nil:
    section.add "X-Amz-Security-Token", valid_402656506
  var valid_402656507 = header.getOrDefault("X-Amz-Signature")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-Signature", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Algorithm", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Date")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Date", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Credential")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Credential", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656513: Call_GetConfigurationSetEventDestinations_402656491;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieve a list of event destinations that are associated with a configuration set.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
                                                                                         ## 
  let valid = call_402656513.validator(path, query, header, formData, body, _)
  let scheme = call_402656513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656513.makeUrl(scheme.get, call_402656513.host, call_402656513.base,
                                   call_402656513.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656513, uri, valid, _)

proc call*(call_402656514: Call_GetConfigurationSetEventDestinations_402656491;
           ConfigurationSetName: string): Recallable =
  ## getConfigurationSetEventDestinations
  ## <p>Retrieve a list of event destinations that are associated with a configuration set.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## ConfigurationSetName: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ##                       
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## <p>The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## set.</p> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## <p>In 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## Pinpoint, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## <i>configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## sets</i> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## groups 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## rules 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## can 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## apply 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## emails 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## send. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## You 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## apply 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## an 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## email 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## by 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## including 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## reference 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## headers 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## email. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## When 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## apply 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## an 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## email, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## all 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## rules 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## applied 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## email.</p>
  var path_402656515 = newJObject()
  add(path_402656515, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_402656514.call(path_402656515, nil, nil, nil, nil)

var getConfigurationSetEventDestinations* = Call_GetConfigurationSetEventDestinations_402656491(
    name: "getConfigurationSetEventDestinations", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/event-destinations",
    validator: validate_GetConfigurationSetEventDestinations_402656492,
    base: "/", makeUrl: url_GetConfigurationSetEventDestinations_402656493,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDedicatedIpPool_402656547 = ref object of OpenApiRestCall_402656044
proc url_CreateDedicatedIpPool_402656549(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDedicatedIpPool_402656548(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Create a new pool of dedicated IP addresses. A pool can include one or more dedicated IP addresses that are associated with your Amazon Pinpoint account. You can associate a pool with a configuration set. When you send an email that uses that configuration set, Amazon Pinpoint sends it using only the IP addresses in the associated pool.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656550 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656550 = validateParameter(valid_402656550, JString,
                                      required = false, default = nil)
  if valid_402656550 != nil:
    section.add "X-Amz-Security-Token", valid_402656550
  var valid_402656551 = header.getOrDefault("X-Amz-Signature")
  valid_402656551 = validateParameter(valid_402656551, JString,
                                      required = false, default = nil)
  if valid_402656551 != nil:
    section.add "X-Amz-Signature", valid_402656551
  var valid_402656552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656552 = validateParameter(valid_402656552, JString,
                                      required = false, default = nil)
  if valid_402656552 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Algorithm", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Date")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Date", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-Credential")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-Credential", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656556
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656558: Call_CreateDedicatedIpPool_402656547;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new pool of dedicated IP addresses. A pool can include one or more dedicated IP addresses that are associated with your Amazon Pinpoint account. You can associate a pool with a configuration set. When you send an email that uses that configuration set, Amazon Pinpoint sends it using only the IP addresses in the associated pool.
                                                                                         ## 
  let valid = call_402656558.validator(path, query, header, formData, body, _)
  let scheme = call_402656558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656558.makeUrl(scheme.get, call_402656558.host, call_402656558.base,
                                   call_402656558.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656558, uri, valid, _)

proc call*(call_402656559: Call_CreateDedicatedIpPool_402656547; body: JsonNode): Recallable =
  ## createDedicatedIpPool
  ## Create a new pool of dedicated IP addresses. A pool can include one or more dedicated IP addresses that are associated with your Amazon Pinpoint account. You can associate a pool with a configuration set. When you send an email that uses that configuration set, Amazon Pinpoint sends it using only the IP addresses in the associated pool.
  ##   
                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402656560 = newJObject()
  if body != nil:
    body_402656560 = body
  result = call_402656559.call(nil, nil, nil, nil, body_402656560)

var createDedicatedIpPool* = Call_CreateDedicatedIpPool_402656547(
    name: "createDedicatedIpPool", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v1/email/dedicated-ip-pools",
    validator: validate_CreateDedicatedIpPool_402656548, base: "/",
    makeUrl: url_CreateDedicatedIpPool_402656549,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDedicatedIpPools_402656532 = ref object of OpenApiRestCall_402656044
proc url_ListDedicatedIpPools_402656534(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDedicatedIpPools_402656533(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List all of the dedicated IP pools that exist in your Amazon Pinpoint account in the current AWS Region.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JInt
                                  ##           : The number of results to show in a single call to <code>ListDedicatedIpPools</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   
                                                                                                                                                                                                                                                                                                                                      ## NextToken: JString
                                                                                                                                                                                                                                                                                                                                      ##            
                                                                                                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                                                                                                      ## A 
                                                                                                                                                                                                                                                                                                                                      ## token 
                                                                                                                                                                                                                                                                                                                                      ## returned 
                                                                                                                                                                                                                                                                                                                                      ## from 
                                                                                                                                                                                                                                                                                                                                      ## a 
                                                                                                                                                                                                                                                                                                                                      ## previous 
                                                                                                                                                                                                                                                                                                                                      ## call 
                                                                                                                                                                                                                                                                                                                                      ## to 
                                                                                                                                                                                                                                                                                                                                      ## <code>ListDedicatedIpPools</code> 
                                                                                                                                                                                                                                                                                                                                      ## to 
                                                                                                                                                                                                                                                                                                                                      ## indicate 
                                                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                                                      ## position 
                                                                                                                                                                                                                                                                                                                                      ## in 
                                                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                                                      ## list 
                                                                                                                                                                                                                                                                                                                                      ## of 
                                                                                                                                                                                                                                                                                                                                      ## dedicated 
                                                                                                                                                                                                                                                                                                                                      ## IP 
                                                                                                                                                                                                                                                                                                                                      ## pools.
  section = newJObject()
  var valid_402656535 = query.getOrDefault("PageSize")
  valid_402656535 = validateParameter(valid_402656535, JInt, required = false,
                                      default = nil)
  if valid_402656535 != nil:
    section.add "PageSize", valid_402656535
  var valid_402656536 = query.getOrDefault("NextToken")
  valid_402656536 = validateParameter(valid_402656536, JString,
                                      required = false, default = nil)
  if valid_402656536 != nil:
    section.add "NextToken", valid_402656536
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656537 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656537 = validateParameter(valid_402656537, JString,
                                      required = false, default = nil)
  if valid_402656537 != nil:
    section.add "X-Amz-Security-Token", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Signature")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Signature", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Algorithm", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Date")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Date", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Credential")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Credential", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656543
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656544: Call_ListDedicatedIpPools_402656532;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List all of the dedicated IP pools that exist in your Amazon Pinpoint account in the current AWS Region.
                                                                                         ## 
  let valid = call_402656544.validator(path, query, header, formData, body, _)
  let scheme = call_402656544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656544.makeUrl(scheme.get, call_402656544.host, call_402656544.base,
                                   call_402656544.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656544, uri, valid, _)

proc call*(call_402656545: Call_ListDedicatedIpPools_402656532;
           PageSize: int = 0; NextToken: string = ""): Recallable =
  ## listDedicatedIpPools
  ## List all of the dedicated IP pools that exist in your Amazon Pinpoint account in the current AWS Region.
  ##   
                                                                                                             ## PageSize: int
                                                                                                             ##           
                                                                                                             ## : 
                                                                                                             ## The 
                                                                                                             ## number 
                                                                                                             ## of 
                                                                                                             ## results 
                                                                                                             ## to 
                                                                                                             ## show 
                                                                                                             ## in 
                                                                                                             ## a 
                                                                                                             ## single 
                                                                                                             ## call 
                                                                                                             ## to 
                                                                                                             ## <code>ListDedicatedIpPools</code>. 
                                                                                                             ## If 
                                                                                                             ## the 
                                                                                                             ## number 
                                                                                                             ## of 
                                                                                                             ## results 
                                                                                                             ## is 
                                                                                                             ## larger 
                                                                                                             ## than 
                                                                                                             ## the 
                                                                                                             ## number 
                                                                                                             ## you 
                                                                                                             ## specified 
                                                                                                             ## in 
                                                                                                             ## this 
                                                                                                             ## parameter, 
                                                                                                             ## then 
                                                                                                             ## the 
                                                                                                             ## response 
                                                                                                             ## includes 
                                                                                                             ## a 
                                                                                                             ## <code>NextToken</code> 
                                                                                                             ## element, 
                                                                                                             ## which 
                                                                                                             ## you 
                                                                                                             ## can 
                                                                                                             ## use 
                                                                                                             ## to 
                                                                                                             ## obtain 
                                                                                                             ## additional 
                                                                                                             ## results.
  ##   
                                                                                                                        ## NextToken: string
                                                                                                                        ##            
                                                                                                                        ## : 
                                                                                                                        ## A 
                                                                                                                        ## token 
                                                                                                                        ## returned 
                                                                                                                        ## from 
                                                                                                                        ## a 
                                                                                                                        ## previous 
                                                                                                                        ## call 
                                                                                                                        ## to 
                                                                                                                        ## <code>ListDedicatedIpPools</code> 
                                                                                                                        ## to 
                                                                                                                        ## indicate 
                                                                                                                        ## the 
                                                                                                                        ## position 
                                                                                                                        ## in 
                                                                                                                        ## the 
                                                                                                                        ## list 
                                                                                                                        ## of 
                                                                                                                        ## dedicated 
                                                                                                                        ## IP 
                                                                                                                        ## pools.
  var query_402656546 = newJObject()
  add(query_402656546, "PageSize", newJInt(PageSize))
  add(query_402656546, "NextToken", newJString(NextToken))
  result = call_402656545.call(nil, query_402656546, nil, nil, nil)

var listDedicatedIpPools* = Call_ListDedicatedIpPools_402656532(
    name: "listDedicatedIpPools", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/dedicated-ip-pools",
    validator: validate_ListDedicatedIpPools_402656533, base: "/",
    makeUrl: url_ListDedicatedIpPools_402656534,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeliverabilityTestReport_402656561 = ref object of OpenApiRestCall_402656044
proc url_CreateDeliverabilityTestReport_402656563(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDeliverabilityTestReport_402656562(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Create a new predictive inbox placement test. Predictive inbox placement tests can help you predict how your messages will be handled by various email providers around the world. When you perform a predictive inbox placement test, you provide a sample message that contains the content that you plan to send to your customers. Amazon Pinpoint then sends that message to special email addresses spread across several major email providers. After about 24 hours, the test is complete, and you can use the <code>GetDeliverabilityTestReport</code> operation to view the results of the test.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656564 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "X-Amz-Security-Token", valid_402656564
  var valid_402656565 = header.getOrDefault("X-Amz-Signature")
  valid_402656565 = validateParameter(valid_402656565, JString,
                                      required = false, default = nil)
  if valid_402656565 != nil:
    section.add "X-Amz-Signature", valid_402656565
  var valid_402656566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656566 = validateParameter(valid_402656566, JString,
                                      required = false, default = nil)
  if valid_402656566 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656566
  var valid_402656567 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656567 = validateParameter(valid_402656567, JString,
                                      required = false, default = nil)
  if valid_402656567 != nil:
    section.add "X-Amz-Algorithm", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Date")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Date", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Credential")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Credential", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656570
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656572: Call_CreateDeliverabilityTestReport_402656561;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new predictive inbox placement test. Predictive inbox placement tests can help you predict how your messages will be handled by various email providers around the world. When you perform a predictive inbox placement test, you provide a sample message that contains the content that you plan to send to your customers. Amazon Pinpoint then sends that message to special email addresses spread across several major email providers. After about 24 hours, the test is complete, and you can use the <code>GetDeliverabilityTestReport</code> operation to view the results of the test.
                                                                                         ## 
  let valid = call_402656572.validator(path, query, header, formData, body, _)
  let scheme = call_402656572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656572.makeUrl(scheme.get, call_402656572.host, call_402656572.base,
                                   call_402656572.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656572, uri, valid, _)

proc call*(call_402656573: Call_CreateDeliverabilityTestReport_402656561;
           body: JsonNode): Recallable =
  ## createDeliverabilityTestReport
  ## Create a new predictive inbox placement test. Predictive inbox placement tests can help you predict how your messages will be handled by various email providers around the world. When you perform a predictive inbox placement test, you provide a sample message that contains the content that you plan to send to your customers. Amazon Pinpoint then sends that message to special email addresses spread across several major email providers. After about 24 hours, the test is complete, and you can use the <code>GetDeliverabilityTestReport</code> operation to view the results of the test.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402656574 = newJObject()
  if body != nil:
    body_402656574 = body
  result = call_402656573.call(nil, nil, nil, nil, body_402656574)

var createDeliverabilityTestReport* = Call_CreateDeliverabilityTestReport_402656561(
    name: "createDeliverabilityTestReport", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com",
    route: "/v1/email/deliverability-dashboard/test",
    validator: validate_CreateDeliverabilityTestReport_402656562, base: "/",
    makeUrl: url_CreateDeliverabilityTestReport_402656563,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEmailIdentity_402656590 = ref object of OpenApiRestCall_402656044
proc url_CreateEmailIdentity_402656592(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateEmailIdentity_402656591(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Verifies an email identity for use with Amazon Pinpoint. In Amazon Pinpoint, an identity is an email address or domain that you use when you send email. Before you can use an identity to send email with Amazon Pinpoint, you first have to verify it. By verifying an address, you demonstrate that you're the owner of the address, and that you've given Amazon Pinpoint permission to send email from the address.</p> <p>When you verify an email address, Amazon Pinpoint sends an email to the address. Your email address is verified as soon as you follow the link in the verification email. </p> <p>When you verify a domain, this operation provides a set of DKIM tokens, which you can convert into CNAME tokens. You add these CNAME tokens to the DNS configuration for your domain. Your domain is verified when Amazon Pinpoint detects these records in the DNS configuration for your domain. It usually takes around 72 hours to complete the domain verification process.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656593 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656593 = validateParameter(valid_402656593, JString,
                                      required = false, default = nil)
  if valid_402656593 != nil:
    section.add "X-Amz-Security-Token", valid_402656593
  var valid_402656594 = header.getOrDefault("X-Amz-Signature")
  valid_402656594 = validateParameter(valid_402656594, JString,
                                      required = false, default = nil)
  if valid_402656594 != nil:
    section.add "X-Amz-Signature", valid_402656594
  var valid_402656595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656595 = validateParameter(valid_402656595, JString,
                                      required = false, default = nil)
  if valid_402656595 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656595
  var valid_402656596 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656596 = validateParameter(valid_402656596, JString,
                                      required = false, default = nil)
  if valid_402656596 != nil:
    section.add "X-Amz-Algorithm", valid_402656596
  var valid_402656597 = header.getOrDefault("X-Amz-Date")
  valid_402656597 = validateParameter(valid_402656597, JString,
                                      required = false, default = nil)
  if valid_402656597 != nil:
    section.add "X-Amz-Date", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-Credential")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Credential", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656601: Call_CreateEmailIdentity_402656590;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Verifies an email identity for use with Amazon Pinpoint. In Amazon Pinpoint, an identity is an email address or domain that you use when you send email. Before you can use an identity to send email with Amazon Pinpoint, you first have to verify it. By verifying an address, you demonstrate that you're the owner of the address, and that you've given Amazon Pinpoint permission to send email from the address.</p> <p>When you verify an email address, Amazon Pinpoint sends an email to the address. Your email address is verified as soon as you follow the link in the verification email. </p> <p>When you verify a domain, this operation provides a set of DKIM tokens, which you can convert into CNAME tokens. You add these CNAME tokens to the DNS configuration for your domain. Your domain is verified when Amazon Pinpoint detects these records in the DNS configuration for your domain. It usually takes around 72 hours to complete the domain verification process.</p>
                                                                                         ## 
  let valid = call_402656601.validator(path, query, header, formData, body, _)
  let scheme = call_402656601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656601.makeUrl(scheme.get, call_402656601.host, call_402656601.base,
                                   call_402656601.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656601, uri, valid, _)

proc call*(call_402656602: Call_CreateEmailIdentity_402656590; body: JsonNode): Recallable =
  ## createEmailIdentity
  ## <p>Verifies an email identity for use with Amazon Pinpoint. In Amazon Pinpoint, an identity is an email address or domain that you use when you send email. Before you can use an identity to send email with Amazon Pinpoint, you first have to verify it. By verifying an address, you demonstrate that you're the owner of the address, and that you've given Amazon Pinpoint permission to send email from the address.</p> <p>When you verify an email address, Amazon Pinpoint sends an email to the address. Your email address is verified as soon as you follow the link in the verification email. </p> <p>When you verify a domain, this operation provides a set of DKIM tokens, which you can convert into CNAME tokens. You add these CNAME tokens to the DNS configuration for your domain. Your domain is verified when Amazon Pinpoint detects these records in the DNS configuration for your domain. It usually takes around 72 hours to complete the domain verification process.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402656603 = newJObject()
  if body != nil:
    body_402656603 = body
  result = call_402656602.call(nil, nil, nil, nil, body_402656603)

var createEmailIdentity* = Call_CreateEmailIdentity_402656590(
    name: "createEmailIdentity", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v1/email/identities",
    validator: validate_CreateEmailIdentity_402656591, base: "/",
    makeUrl: url_CreateEmailIdentity_402656592,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEmailIdentities_402656575 = ref object of OpenApiRestCall_402656044
proc url_ListEmailIdentities_402656577(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEmailIdentities_402656576(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of all of the email identities that are associated with your Amazon Pinpoint account. An identity can be either an email address or a domain. This operation returns identities that are verified as well as those that aren't.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JInt
                                  ##           : <p>The number of results to show in a single call to <code>ListEmailIdentities</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.</p> <p>The value you specify has to be at least 0, and can be no more than 1000.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                             ## NextToken: JString
                                                                                                                                                                                                                                                                                                                                                                                                                             ##            
                                                                                                                                                                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                             ## A 
                                                                                                                                                                                                                                                                                                                                                                                                                             ## token 
                                                                                                                                                                                                                                                                                                                                                                                                                             ## returned 
                                                                                                                                                                                                                                                                                                                                                                                                                             ## from 
                                                                                                                                                                                                                                                                                                                                                                                                                             ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                             ## previous 
                                                                                                                                                                                                                                                                                                                                                                                                                             ## call 
                                                                                                                                                                                                                                                                                                                                                                                                                             ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                             ## <code>ListEmailIdentities</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                             ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                             ## indicate 
                                                                                                                                                                                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                             ## position 
                                                                                                                                                                                                                                                                                                                                                                                                                             ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                             ## list 
                                                                                                                                                                                                                                                                                                                                                                                                                             ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                             ## identities.
  section = newJObject()
  var valid_402656578 = query.getOrDefault("PageSize")
  valid_402656578 = validateParameter(valid_402656578, JInt, required = false,
                                      default = nil)
  if valid_402656578 != nil:
    section.add "PageSize", valid_402656578
  var valid_402656579 = query.getOrDefault("NextToken")
  valid_402656579 = validateParameter(valid_402656579, JString,
                                      required = false, default = nil)
  if valid_402656579 != nil:
    section.add "NextToken", valid_402656579
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656580 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656580 = validateParameter(valid_402656580, JString,
                                      required = false, default = nil)
  if valid_402656580 != nil:
    section.add "X-Amz-Security-Token", valid_402656580
  var valid_402656581 = header.getOrDefault("X-Amz-Signature")
  valid_402656581 = validateParameter(valid_402656581, JString,
                                      required = false, default = nil)
  if valid_402656581 != nil:
    section.add "X-Amz-Signature", valid_402656581
  var valid_402656582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656582 = validateParameter(valid_402656582, JString,
                                      required = false, default = nil)
  if valid_402656582 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Algorithm", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-Date")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Date", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Credential")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Credential", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656586
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656587: Call_ListEmailIdentities_402656575;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of all of the email identities that are associated with your Amazon Pinpoint account. An identity can be either an email address or a domain. This operation returns identities that are verified as well as those that aren't.
                                                                                         ## 
  let valid = call_402656587.validator(path, query, header, formData, body, _)
  let scheme = call_402656587.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656587.makeUrl(scheme.get, call_402656587.host, call_402656587.base,
                                   call_402656587.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656587, uri, valid, _)

proc call*(call_402656588: Call_ListEmailIdentities_402656575;
           PageSize: int = 0; NextToken: string = ""): Recallable =
  ## listEmailIdentities
  ## Returns a list of all of the email identities that are associated with your Amazon Pinpoint account. An identity can be either an email address or a domain. This operation returns identities that are verified as well as those that aren't.
  ##   
                                                                                                                                                                                                                                                   ## PageSize: int
                                                                                                                                                                                                                                                   ##           
                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                   ## <p>The 
                                                                                                                                                                                                                                                   ## number 
                                                                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                                                                   ## results 
                                                                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                                                                   ## show 
                                                                                                                                                                                                                                                   ## in 
                                                                                                                                                                                                                                                   ## a 
                                                                                                                                                                                                                                                   ## single 
                                                                                                                                                                                                                                                   ## call 
                                                                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                                                                   ## <code>ListEmailIdentities</code>. 
                                                                                                                                                                                                                                                   ## If 
                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                   ## number 
                                                                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                                                                   ## results 
                                                                                                                                                                                                                                                   ## is 
                                                                                                                                                                                                                                                   ## larger 
                                                                                                                                                                                                                                                   ## than 
                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                   ## number 
                                                                                                                                                                                                                                                   ## you 
                                                                                                                                                                                                                                                   ## specified 
                                                                                                                                                                                                                                                   ## in 
                                                                                                                                                                                                                                                   ## this 
                                                                                                                                                                                                                                                   ## parameter, 
                                                                                                                                                                                                                                                   ## then 
                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                   ## response 
                                                                                                                                                                                                                                                   ## includes 
                                                                                                                                                                                                                                                   ## a 
                                                                                                                                                                                                                                                   ## <code>NextToken</code> 
                                                                                                                                                                                                                                                   ## element, 
                                                                                                                                                                                                                                                   ## which 
                                                                                                                                                                                                                                                   ## you 
                                                                                                                                                                                                                                                   ## can 
                                                                                                                                                                                                                                                   ## use 
                                                                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                                                                   ## obtain 
                                                                                                                                                                                                                                                   ## additional 
                                                                                                                                                                                                                                                   ## results.</p> 
                                                                                                                                                                                                                                                   ## <p>The 
                                                                                                                                                                                                                                                   ## value 
                                                                                                                                                                                                                                                   ## you 
                                                                                                                                                                                                                                                   ## specify 
                                                                                                                                                                                                                                                   ## has 
                                                                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                                                                   ## be 
                                                                                                                                                                                                                                                   ## at 
                                                                                                                                                                                                                                                   ## least 
                                                                                                                                                                                                                                                   ## 0, 
                                                                                                                                                                                                                                                   ## and 
                                                                                                                                                                                                                                                   ## can 
                                                                                                                                                                                                                                                   ## be 
                                                                                                                                                                                                                                                   ## no 
                                                                                                                                                                                                                                                   ## more 
                                                                                                                                                                                                                                                   ## than 
                                                                                                                                                                                                                                                   ## 1000.</p>
  ##   
                                                                                                                                                                                                                                                               ## NextToken: string
                                                                                                                                                                                                                                                               ##            
                                                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                                                               ## A 
                                                                                                                                                                                                                                                               ## token 
                                                                                                                                                                                                                                                               ## returned 
                                                                                                                                                                                                                                                               ## from 
                                                                                                                                                                                                                                                               ## a 
                                                                                                                                                                                                                                                               ## previous 
                                                                                                                                                                                                                                                               ## call 
                                                                                                                                                                                                                                                               ## to 
                                                                                                                                                                                                                                                               ## <code>ListEmailIdentities</code> 
                                                                                                                                                                                                                                                               ## to 
                                                                                                                                                                                                                                                               ## indicate 
                                                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                                                               ## position 
                                                                                                                                                                                                                                                               ## in 
                                                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                                                               ## list 
                                                                                                                                                                                                                                                               ## of 
                                                                                                                                                                                                                                                               ## identities.
  var query_402656589 = newJObject()
  add(query_402656589, "PageSize", newJInt(PageSize))
  add(query_402656589, "NextToken", newJString(NextToken))
  result = call_402656588.call(nil, query_402656589, nil, nil, nil)

var listEmailIdentities* = Call_ListEmailIdentities_402656575(
    name: "listEmailIdentities", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/identities",
    validator: validate_ListEmailIdentities_402656576, base: "/",
    makeUrl: url_ListEmailIdentities_402656577,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigurationSet_402656604 = ref object of OpenApiRestCall_402656044
proc url_GetConfigurationSet_402656606(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
         "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/configuration-sets/"),
                 (kind: VariableSegment, value: "ConfigurationSetName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetConfigurationSet_402656605(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Get information about an existing configuration set, including the dedicated IP pool that it's associated with, whether or not it's enabled for sending email, and more.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
                                 ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_402656607 = path.getOrDefault("ConfigurationSetName")
  valid_402656607 = validateParameter(valid_402656607, JString, required = true,
                                      default = nil)
  if valid_402656607 != nil:
    section.add "ConfigurationSetName", valid_402656607
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656608 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656608 = validateParameter(valid_402656608, JString,
                                      required = false, default = nil)
  if valid_402656608 != nil:
    section.add "X-Amz-Security-Token", valid_402656608
  var valid_402656609 = header.getOrDefault("X-Amz-Signature")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "X-Amz-Signature", valid_402656609
  var valid_402656610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656610 = validateParameter(valid_402656610, JString,
                                      required = false, default = nil)
  if valid_402656610 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656610
  var valid_402656611 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656611 = validateParameter(valid_402656611, JString,
                                      required = false, default = nil)
  if valid_402656611 != nil:
    section.add "X-Amz-Algorithm", valid_402656611
  var valid_402656612 = header.getOrDefault("X-Amz-Date")
  valid_402656612 = validateParameter(valid_402656612, JString,
                                      required = false, default = nil)
  if valid_402656612 != nil:
    section.add "X-Amz-Date", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Credential")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Credential", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656615: Call_GetConfigurationSet_402656604;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Get information about an existing configuration set, including the dedicated IP pool that it's associated with, whether or not it's enabled for sending email, and more.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
                                                                                         ## 
  let valid = call_402656615.validator(path, query, header, formData, body, _)
  let scheme = call_402656615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656615.makeUrl(scheme.get, call_402656615.host, call_402656615.base,
                                   call_402656615.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656615, uri, valid, _)

proc call*(call_402656616: Call_GetConfigurationSet_402656604;
           ConfigurationSetName: string): Recallable =
  ## getConfigurationSet
  ## <p>Get information about an existing configuration set, including the dedicated IP pool that it's associated with, whether or not it's enabled for sending email, and more.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## ConfigurationSetName: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ##                       
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## <p>The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## set.</p> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## <p>In 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## Pinpoint, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## <i>configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## sets</i> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## groups 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## rules 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## can 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## apply 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## emails 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## send. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## You 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## apply 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## an 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## email 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## by 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## including 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## reference 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## headers 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## email. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## When 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## apply 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## an 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## email, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## all 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## rules 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## applied 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## email.</p>
  var path_402656617 = newJObject()
  add(path_402656617, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_402656616.call(path_402656617, nil, nil, nil, nil)

var getConfigurationSet* = Call_GetConfigurationSet_402656604(
    name: "getConfigurationSet", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v1/email/configuration-sets/{ConfigurationSetName}",
    validator: validate_GetConfigurationSet_402656605, base: "/",
    makeUrl: url_GetConfigurationSet_402656606,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationSet_402656618 = ref object of OpenApiRestCall_402656044
proc url_DeleteConfigurationSet_402656620(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
         "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/configuration-sets/"),
                 (kind: VariableSegment, value: "ConfigurationSetName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteConfigurationSet_402656619(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Delete an existing configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
                                 ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_402656621 = path.getOrDefault("ConfigurationSetName")
  valid_402656621 = validateParameter(valid_402656621, JString, required = true,
                                      default = nil)
  if valid_402656621 != nil:
    section.add "ConfigurationSetName", valid_402656621
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656622 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656622 = validateParameter(valid_402656622, JString,
                                      required = false, default = nil)
  if valid_402656622 != nil:
    section.add "X-Amz-Security-Token", valid_402656622
  var valid_402656623 = header.getOrDefault("X-Amz-Signature")
  valid_402656623 = validateParameter(valid_402656623, JString,
                                      required = false, default = nil)
  if valid_402656623 != nil:
    section.add "X-Amz-Signature", valid_402656623
  var valid_402656624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656624 = validateParameter(valid_402656624, JString,
                                      required = false, default = nil)
  if valid_402656624 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656624
  var valid_402656625 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656625 = validateParameter(valid_402656625, JString,
                                      required = false, default = nil)
  if valid_402656625 != nil:
    section.add "X-Amz-Algorithm", valid_402656625
  var valid_402656626 = header.getOrDefault("X-Amz-Date")
  valid_402656626 = validateParameter(valid_402656626, JString,
                                      required = false, default = nil)
  if valid_402656626 != nil:
    section.add "X-Amz-Date", valid_402656626
  var valid_402656627 = header.getOrDefault("X-Amz-Credential")
  valid_402656627 = validateParameter(valid_402656627, JString,
                                      required = false, default = nil)
  if valid_402656627 != nil:
    section.add "X-Amz-Credential", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656629: Call_DeleteConfigurationSet_402656618;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Delete an existing configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
                                                                                         ## 
  let valid = call_402656629.validator(path, query, header, formData, body, _)
  let scheme = call_402656629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656629.makeUrl(scheme.get, call_402656629.host, call_402656629.base,
                                   call_402656629.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656629, uri, valid, _)

proc call*(call_402656630: Call_DeleteConfigurationSet_402656618;
           ConfigurationSetName: string): Recallable =
  ## deleteConfigurationSet
  ## <p>Delete an existing configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                   ## ConfigurationSetName: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                   ##                       
                                                                                                                                                                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## <p>The 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## set.</p> 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## <p>In 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## Pinpoint, 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## <i>configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## sets</i> 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## groups 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## rules 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## can 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## apply 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## emails 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## send. 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## You 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## apply 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## an 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## email 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## by 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## including 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## reference 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## headers 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## email. 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## When 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## apply 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## an 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## email, 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## all 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## rules 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## applied 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                   ## email.</p>
  var path_402656631 = newJObject()
  add(path_402656631, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_402656630.call(path_402656631, nil, nil, nil, nil)

var deleteConfigurationSet* = Call_DeleteConfigurationSet_402656618(
    name: "deleteConfigurationSet", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com",
    route: "/v1/email/configuration-sets/{ConfigurationSetName}",
    validator: validate_DeleteConfigurationSet_402656619, base: "/",
    makeUrl: url_DeleteConfigurationSet_402656620,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfigurationSetEventDestination_402656632 = ref object of OpenApiRestCall_402656044
proc url_UpdateConfigurationSetEventDestination_402656634(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
         "`ConfigurationSetName` is a required path parameter"
  assert "EventDestinationName" in path,
         "`EventDestinationName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/configuration-sets/"),
                 (kind: VariableSegment, value: "ConfigurationSetName"),
                 (kind: ConstantSegment, value: "/event-destinations/"),
                 (kind: VariableSegment, value: "EventDestinationName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateConfigurationSetEventDestination_402656633(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Update the configuration of an event destination for a configuration set.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EventDestinationName: JString (required)
                                 ##                       : <p>The name of an event destination.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## ConfigurationSetName: JString (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ##                       
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## <p>The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## set.</p> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## <p>In 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## Pinpoint, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## <i>configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## sets</i> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## groups 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## rules 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## can 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## apply 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## emails 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## send. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## You 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## apply 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## an 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## email 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## by 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## including 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## reference 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## headers 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## email. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## When 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## apply 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## an 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## email, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## all 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## rules 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## applied 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `EventDestinationName` field"
  var valid_402656635 = path.getOrDefault("EventDestinationName")
  valid_402656635 = validateParameter(valid_402656635, JString, required = true,
                                      default = nil)
  if valid_402656635 != nil:
    section.add "EventDestinationName", valid_402656635
  var valid_402656636 = path.getOrDefault("ConfigurationSetName")
  valid_402656636 = validateParameter(valid_402656636, JString, required = true,
                                      default = nil)
  if valid_402656636 != nil:
    section.add "ConfigurationSetName", valid_402656636
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656637 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656637 = validateParameter(valid_402656637, JString,
                                      required = false, default = nil)
  if valid_402656637 != nil:
    section.add "X-Amz-Security-Token", valid_402656637
  var valid_402656638 = header.getOrDefault("X-Amz-Signature")
  valid_402656638 = validateParameter(valid_402656638, JString,
                                      required = false, default = nil)
  if valid_402656638 != nil:
    section.add "X-Amz-Signature", valid_402656638
  var valid_402656639 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656639 = validateParameter(valid_402656639, JString,
                                      required = false, default = nil)
  if valid_402656639 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656639
  var valid_402656640 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656640 = validateParameter(valid_402656640, JString,
                                      required = false, default = nil)
  if valid_402656640 != nil:
    section.add "X-Amz-Algorithm", valid_402656640
  var valid_402656641 = header.getOrDefault("X-Amz-Date")
  valid_402656641 = validateParameter(valid_402656641, JString,
                                      required = false, default = nil)
  if valid_402656641 != nil:
    section.add "X-Amz-Date", valid_402656641
  var valid_402656642 = header.getOrDefault("X-Amz-Credential")
  valid_402656642 = validateParameter(valid_402656642, JString,
                                      required = false, default = nil)
  if valid_402656642 != nil:
    section.add "X-Amz-Credential", valid_402656642
  var valid_402656643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656645: Call_UpdateConfigurationSetEventDestination_402656632;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Update the configuration of an event destination for a configuration set.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
                                                                                         ## 
  let valid = call_402656645.validator(path, query, header, formData, body, _)
  let scheme = call_402656645.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656645.makeUrl(scheme.get, call_402656645.host, call_402656645.base,
                                   call_402656645.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656645, uri, valid, _)

proc call*(call_402656646: Call_UpdateConfigurationSetEventDestination_402656632;
           EventDestinationName: string; ConfigurationSetName: string;
           body: JsonNode): Recallable =
  ## updateConfigurationSetEventDestination
  ## <p>Update the configuration of an event destination for a configuration set.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## EventDestinationName: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ##                       
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## <p>The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## an 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## event 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## destination.</p> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## <p>In 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## Pinpoint, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## <i>events</i> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## include 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## message 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## sends, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## deliveries, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## opens, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## clicks, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## bounces, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## complaints. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## <i>Event 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## destinations</i> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## places 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## can 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## send 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## information 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## about 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## these 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## events 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## to. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## For 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## example, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## can 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## send 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## event 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## data 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## SNS 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## receive 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## notifications 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## when 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## receive 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## bounces 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## or 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## complaints, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## or 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## can 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## use 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## Kinesis 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## Data 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## Firehose 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## stream 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## data 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## S3 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## for 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## long-term 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## storage.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## ConfigurationSetName: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ##                       
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## <p>The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## set.</p> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## <p>In 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## Pinpoint, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## <i>configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## sets</i> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## groups 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## rules 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## can 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## apply 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## emails 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## send. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## You 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## apply 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## an 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## email 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## by 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## including 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## reference 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## headers 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## email. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## When 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## apply 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## an 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## email, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## all 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## rules 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## applied 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## email.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## body: JObject (required)
  var path_402656647 = newJObject()
  var body_402656648 = newJObject()
  add(path_402656647, "EventDestinationName", newJString(EventDestinationName))
  add(path_402656647, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_402656648 = body
  result = call_402656646.call(path_402656647, nil, nil, nil, body_402656648)

var updateConfigurationSetEventDestination* = Call_UpdateConfigurationSetEventDestination_402656632(
    name: "updateConfigurationSetEventDestination", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/event-destinations/{EventDestinationName}",
    validator: validate_UpdateConfigurationSetEventDestination_402656633,
    base: "/", makeUrl: url_UpdateConfigurationSetEventDestination_402656634,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationSetEventDestination_402656649 = ref object of OpenApiRestCall_402656044
proc url_DeleteConfigurationSetEventDestination_402656651(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
         "`ConfigurationSetName` is a required path parameter"
  assert "EventDestinationName" in path,
         "`EventDestinationName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/configuration-sets/"),
                 (kind: VariableSegment, value: "ConfigurationSetName"),
                 (kind: ConstantSegment, value: "/event-destinations/"),
                 (kind: VariableSegment, value: "EventDestinationName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteConfigurationSetEventDestination_402656650(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Delete an event destination.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EventDestinationName: JString (required)
                                 ##                       : <p>The name of an event destination.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## ConfigurationSetName: JString (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ##                       
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## <p>The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## set.</p> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## <p>In 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## Pinpoint, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## <i>configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## sets</i> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## groups 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## rules 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## can 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## apply 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## emails 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## send. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## You 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## apply 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## an 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## email 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## by 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## including 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## reference 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## headers 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## email. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## When 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## apply 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## an 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## email, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## all 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## rules 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## applied 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `EventDestinationName` field"
  var valid_402656652 = path.getOrDefault("EventDestinationName")
  valid_402656652 = validateParameter(valid_402656652, JString, required = true,
                                      default = nil)
  if valid_402656652 != nil:
    section.add "EventDestinationName", valid_402656652
  var valid_402656653 = path.getOrDefault("ConfigurationSetName")
  valid_402656653 = validateParameter(valid_402656653, JString, required = true,
                                      default = nil)
  if valid_402656653 != nil:
    section.add "ConfigurationSetName", valid_402656653
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656654 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656654 = validateParameter(valid_402656654, JString,
                                      required = false, default = nil)
  if valid_402656654 != nil:
    section.add "X-Amz-Security-Token", valid_402656654
  var valid_402656655 = header.getOrDefault("X-Amz-Signature")
  valid_402656655 = validateParameter(valid_402656655, JString,
                                      required = false, default = nil)
  if valid_402656655 != nil:
    section.add "X-Amz-Signature", valid_402656655
  var valid_402656656 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656656 = validateParameter(valid_402656656, JString,
                                      required = false, default = nil)
  if valid_402656656 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656656
  var valid_402656657 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656657 = validateParameter(valid_402656657, JString,
                                      required = false, default = nil)
  if valid_402656657 != nil:
    section.add "X-Amz-Algorithm", valid_402656657
  var valid_402656658 = header.getOrDefault("X-Amz-Date")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-Date", valid_402656658
  var valid_402656659 = header.getOrDefault("X-Amz-Credential")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-Credential", valid_402656659
  var valid_402656660 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656660
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656661: Call_DeleteConfigurationSetEventDestination_402656649;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Delete an event destination.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
                                                                                         ## 
  let valid = call_402656661.validator(path, query, header, formData, body, _)
  let scheme = call_402656661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656661.makeUrl(scheme.get, call_402656661.host, call_402656661.base,
                                   call_402656661.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656661, uri, valid, _)

proc call*(call_402656662: Call_DeleteConfigurationSetEventDestination_402656649;
           EventDestinationName: string; ConfigurationSetName: string): Recallable =
  ## deleteConfigurationSetEventDestination
  ## <p>Delete an event destination.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## EventDestinationName: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ##                       
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## <p>The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## an 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## event 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## destination.</p> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## <p>In 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## Pinpoint, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## <i>events</i> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## include 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## message 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## sends, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## deliveries, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## opens, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## clicks, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## bounces, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## complaints. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## <i>Event 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## destinations</i> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## places 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## can 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## send 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## information 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## about 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## these 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## events 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## to. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## For 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## example, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## can 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## send 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## event 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## data 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## SNS 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## receive 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## notifications 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## when 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## receive 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## bounces 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## or 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## complaints, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## or 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## can 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## use 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## Kinesis 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## Data 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## Firehose 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## stream 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## data 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## S3 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## for 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## long-term 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## storage.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## ConfigurationSetName: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ##                       
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## <p>The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## set.</p> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## <p>In 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## Pinpoint, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## <i>configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## sets</i> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## groups 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## rules 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## can 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## apply 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## emails 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## send. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## You 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## apply 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## an 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## email 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## by 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## including 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## reference 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## headers 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## email. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## When 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## apply 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## an 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## email, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## all 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## rules 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## configuration 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## applied 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## email.</p>
  var path_402656663 = newJObject()
  add(path_402656663, "EventDestinationName", newJString(EventDestinationName))
  add(path_402656663, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_402656662.call(path_402656663, nil, nil, nil, nil)

var deleteConfigurationSetEventDestination* = Call_DeleteConfigurationSetEventDestination_402656649(
    name: "deleteConfigurationSetEventDestination", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/event-destinations/{EventDestinationName}",
    validator: validate_DeleteConfigurationSetEventDestination_402656650,
    base: "/", makeUrl: url_DeleteConfigurationSetEventDestination_402656651,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDedicatedIpPool_402656664 = ref object of OpenApiRestCall_402656044
proc url_DeleteDedicatedIpPool_402656666(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "PoolName" in path, "`PoolName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/dedicated-ip-pools/"),
                 (kind: VariableSegment, value: "PoolName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDedicatedIpPool_402656665(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Delete a dedicated IP pool.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   PoolName: JString (required)
                                 ##           : The name of a dedicated IP pool.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `PoolName` field"
  var valid_402656667 = path.getOrDefault("PoolName")
  valid_402656667 = validateParameter(valid_402656667, JString, required = true,
                                      default = nil)
  if valid_402656667 != nil:
    section.add "PoolName", valid_402656667
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656668 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656668 = validateParameter(valid_402656668, JString,
                                      required = false, default = nil)
  if valid_402656668 != nil:
    section.add "X-Amz-Security-Token", valid_402656668
  var valid_402656669 = header.getOrDefault("X-Amz-Signature")
  valid_402656669 = validateParameter(valid_402656669, JString,
                                      required = false, default = nil)
  if valid_402656669 != nil:
    section.add "X-Amz-Signature", valid_402656669
  var valid_402656670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656670 = validateParameter(valid_402656670, JString,
                                      required = false, default = nil)
  if valid_402656670 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656670
  var valid_402656671 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656671 = validateParameter(valid_402656671, JString,
                                      required = false, default = nil)
  if valid_402656671 != nil:
    section.add "X-Amz-Algorithm", valid_402656671
  var valid_402656672 = header.getOrDefault("X-Amz-Date")
  valid_402656672 = validateParameter(valid_402656672, JString,
                                      required = false, default = nil)
  if valid_402656672 != nil:
    section.add "X-Amz-Date", valid_402656672
  var valid_402656673 = header.getOrDefault("X-Amz-Credential")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-Credential", valid_402656673
  var valid_402656674 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656674
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656675: Call_DeleteDedicatedIpPool_402656664;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete a dedicated IP pool.
                                                                                         ## 
  let valid = call_402656675.validator(path, query, header, formData, body, _)
  let scheme = call_402656675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656675.makeUrl(scheme.get, call_402656675.host, call_402656675.base,
                                   call_402656675.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656675, uri, valid, _)

proc call*(call_402656676: Call_DeleteDedicatedIpPool_402656664;
           PoolName: string): Recallable =
  ## deleteDedicatedIpPool
  ## Delete a dedicated IP pool.
  ##   PoolName: string (required)
                                ##           : The name of a dedicated IP pool.
  var path_402656677 = newJObject()
  add(path_402656677, "PoolName", newJString(PoolName))
  result = call_402656676.call(path_402656677, nil, nil, nil, nil)

var deleteDedicatedIpPool* = Call_DeleteDedicatedIpPool_402656664(
    name: "deleteDedicatedIpPool", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com",
    route: "/v1/email/dedicated-ip-pools/{PoolName}",
    validator: validate_DeleteDedicatedIpPool_402656665, base: "/",
    makeUrl: url_DeleteDedicatedIpPool_402656666,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEmailIdentity_402656678 = ref object of OpenApiRestCall_402656044
proc url_GetEmailIdentity_402656680(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "EmailIdentity" in path, "`EmailIdentity` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/identities/"),
                 (kind: VariableSegment, value: "EmailIdentity")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetEmailIdentity_402656679(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Provides information about a specific identity associated with your Amazon Pinpoint account, including the identity's verification status, its DKIM authentication status, and its custom Mail-From settings.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EmailIdentity: JString (required)
                                 ##                : The email identity that you want to retrieve details for.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `EmailIdentity` field"
  var valid_402656681 = path.getOrDefault("EmailIdentity")
  valid_402656681 = validateParameter(valid_402656681, JString, required = true,
                                      default = nil)
  if valid_402656681 != nil:
    section.add "EmailIdentity", valid_402656681
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656682 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656682 = validateParameter(valid_402656682, JString,
                                      required = false, default = nil)
  if valid_402656682 != nil:
    section.add "X-Amz-Security-Token", valid_402656682
  var valid_402656683 = header.getOrDefault("X-Amz-Signature")
  valid_402656683 = validateParameter(valid_402656683, JString,
                                      required = false, default = nil)
  if valid_402656683 != nil:
    section.add "X-Amz-Signature", valid_402656683
  var valid_402656684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656684 = validateParameter(valid_402656684, JString,
                                      required = false, default = nil)
  if valid_402656684 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656684
  var valid_402656685 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656685 = validateParameter(valid_402656685, JString,
                                      required = false, default = nil)
  if valid_402656685 != nil:
    section.add "X-Amz-Algorithm", valid_402656685
  var valid_402656686 = header.getOrDefault("X-Amz-Date")
  valid_402656686 = validateParameter(valid_402656686, JString,
                                      required = false, default = nil)
  if valid_402656686 != nil:
    section.add "X-Amz-Date", valid_402656686
  var valid_402656687 = header.getOrDefault("X-Amz-Credential")
  valid_402656687 = validateParameter(valid_402656687, JString,
                                      required = false, default = nil)
  if valid_402656687 != nil:
    section.add "X-Amz-Credential", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656688
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656689: Call_GetEmailIdentity_402656678;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides information about a specific identity associated with your Amazon Pinpoint account, including the identity's verification status, its DKIM authentication status, and its custom Mail-From settings.
                                                                                         ## 
  let valid = call_402656689.validator(path, query, header, formData, body, _)
  let scheme = call_402656689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656689.makeUrl(scheme.get, call_402656689.host, call_402656689.base,
                                   call_402656689.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656689, uri, valid, _)

proc call*(call_402656690: Call_GetEmailIdentity_402656678;
           EmailIdentity: string): Recallable =
  ## getEmailIdentity
  ## Provides information about a specific identity associated with your Amazon Pinpoint account, including the identity's verification status, its DKIM authentication status, and its custom Mail-From settings.
  ##   
                                                                                                                                                                                                                  ## EmailIdentity: string (required)
                                                                                                                                                                                                                  ##                
                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                  ## The 
                                                                                                                                                                                                                  ## email 
                                                                                                                                                                                                                  ## identity 
                                                                                                                                                                                                                  ## that 
                                                                                                                                                                                                                  ## you 
                                                                                                                                                                                                                  ## want 
                                                                                                                                                                                                                  ## to 
                                                                                                                                                                                                                  ## retrieve 
                                                                                                                                                                                                                  ## details 
                                                                                                                                                                                                                  ## for.
  var path_402656691 = newJObject()
  add(path_402656691, "EmailIdentity", newJString(EmailIdentity))
  result = call_402656690.call(path_402656691, nil, nil, nil, nil)

var getEmailIdentity* = Call_GetEmailIdentity_402656678(
    name: "getEmailIdentity", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/identities/{EmailIdentity}",
    validator: validate_GetEmailIdentity_402656679, base: "/",
    makeUrl: url_GetEmailIdentity_402656680,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEmailIdentity_402656692 = ref object of OpenApiRestCall_402656044
proc url_DeleteEmailIdentity_402656694(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "EmailIdentity" in path, "`EmailIdentity` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/identities/"),
                 (kind: VariableSegment, value: "EmailIdentity")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteEmailIdentity_402656693(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an email identity that you previously verified for use with Amazon Pinpoint. An identity can be either an email address or a domain name.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EmailIdentity: JString (required)
                                 ##                : The identity (that is, the email address or domain) that you want to delete from your Amazon Pinpoint account.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `EmailIdentity` field"
  var valid_402656695 = path.getOrDefault("EmailIdentity")
  valid_402656695 = validateParameter(valid_402656695, JString, required = true,
                                      default = nil)
  if valid_402656695 != nil:
    section.add "EmailIdentity", valid_402656695
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656696 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656696 = validateParameter(valid_402656696, JString,
                                      required = false, default = nil)
  if valid_402656696 != nil:
    section.add "X-Amz-Security-Token", valid_402656696
  var valid_402656697 = header.getOrDefault("X-Amz-Signature")
  valid_402656697 = validateParameter(valid_402656697, JString,
                                      required = false, default = nil)
  if valid_402656697 != nil:
    section.add "X-Amz-Signature", valid_402656697
  var valid_402656698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656698 = validateParameter(valid_402656698, JString,
                                      required = false, default = nil)
  if valid_402656698 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656698
  var valid_402656699 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656699 = validateParameter(valid_402656699, JString,
                                      required = false, default = nil)
  if valid_402656699 != nil:
    section.add "X-Amz-Algorithm", valid_402656699
  var valid_402656700 = header.getOrDefault("X-Amz-Date")
  valid_402656700 = validateParameter(valid_402656700, JString,
                                      required = false, default = nil)
  if valid_402656700 != nil:
    section.add "X-Amz-Date", valid_402656700
  var valid_402656701 = header.getOrDefault("X-Amz-Credential")
  valid_402656701 = validateParameter(valid_402656701, JString,
                                      required = false, default = nil)
  if valid_402656701 != nil:
    section.add "X-Amz-Credential", valid_402656701
  var valid_402656702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656702 = validateParameter(valid_402656702, JString,
                                      required = false, default = nil)
  if valid_402656702 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656703: Call_DeleteEmailIdentity_402656692;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an email identity that you previously verified for use with Amazon Pinpoint. An identity can be either an email address or a domain name.
                                                                                         ## 
  let valid = call_402656703.validator(path, query, header, formData, body, _)
  let scheme = call_402656703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656703.makeUrl(scheme.get, call_402656703.host, call_402656703.base,
                                   call_402656703.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656703, uri, valid, _)

proc call*(call_402656704: Call_DeleteEmailIdentity_402656692;
           EmailIdentity: string): Recallable =
  ## deleteEmailIdentity
  ## Deletes an email identity that you previously verified for use with Amazon Pinpoint. An identity can be either an email address or a domain name.
  ##   
                                                                                                                                                      ## EmailIdentity: string (required)
                                                                                                                                                      ##                
                                                                                                                                                      ## : 
                                                                                                                                                      ## The 
                                                                                                                                                      ## identity 
                                                                                                                                                      ## (that 
                                                                                                                                                      ## is, 
                                                                                                                                                      ## the 
                                                                                                                                                      ## email 
                                                                                                                                                      ## address 
                                                                                                                                                      ## or 
                                                                                                                                                      ## domain) 
                                                                                                                                                      ## that 
                                                                                                                                                      ## you 
                                                                                                                                                      ## want 
                                                                                                                                                      ## to 
                                                                                                                                                      ## delete 
                                                                                                                                                      ## from 
                                                                                                                                                      ## your 
                                                                                                                                                      ## Amazon 
                                                                                                                                                      ## Pinpoint 
                                                                                                                                                      ## account.
  var path_402656705 = newJObject()
  add(path_402656705, "EmailIdentity", newJString(EmailIdentity))
  result = call_402656704.call(path_402656705, nil, nil, nil, nil)

var deleteEmailIdentity* = Call_DeleteEmailIdentity_402656692(
    name: "deleteEmailIdentity", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com", route: "/v1/email/identities/{EmailIdentity}",
    validator: validate_DeleteEmailIdentity_402656693, base: "/",
    makeUrl: url_DeleteEmailIdentity_402656694,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccount_402656706 = ref object of OpenApiRestCall_402656044
proc url_GetAccount_402656708(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAccount_402656707(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Obtain information about the email-sending status and capabilities of your Amazon Pinpoint account in the current AWS Region.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656709 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "X-Amz-Security-Token", valid_402656709
  var valid_402656710 = header.getOrDefault("X-Amz-Signature")
  valid_402656710 = validateParameter(valid_402656710, JString,
                                      required = false, default = nil)
  if valid_402656710 != nil:
    section.add "X-Amz-Signature", valid_402656710
  var valid_402656711 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656711 = validateParameter(valid_402656711, JString,
                                      required = false, default = nil)
  if valid_402656711 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656711
  var valid_402656712 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656712 = validateParameter(valid_402656712, JString,
                                      required = false, default = nil)
  if valid_402656712 != nil:
    section.add "X-Amz-Algorithm", valid_402656712
  var valid_402656713 = header.getOrDefault("X-Amz-Date")
  valid_402656713 = validateParameter(valid_402656713, JString,
                                      required = false, default = nil)
  if valid_402656713 != nil:
    section.add "X-Amz-Date", valid_402656713
  var valid_402656714 = header.getOrDefault("X-Amz-Credential")
  valid_402656714 = validateParameter(valid_402656714, JString,
                                      required = false, default = nil)
  if valid_402656714 != nil:
    section.add "X-Amz-Credential", valid_402656714
  var valid_402656715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656715 = validateParameter(valid_402656715, JString,
                                      required = false, default = nil)
  if valid_402656715 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656715
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656716: Call_GetAccount_402656706; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Obtain information about the email-sending status and capabilities of your Amazon Pinpoint account in the current AWS Region.
                                                                                         ## 
  let valid = call_402656716.validator(path, query, header, formData, body, _)
  let scheme = call_402656716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656716.makeUrl(scheme.get, call_402656716.host, call_402656716.base,
                                   call_402656716.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656716, uri, valid, _)

proc call*(call_402656717: Call_GetAccount_402656706): Recallable =
  ## getAccount
  ## Obtain information about the email-sending status and capabilities of your Amazon Pinpoint account in the current AWS Region.
  result = call_402656717.call(nil, nil, nil, nil, nil)

var getAccount* = Call_GetAccount_402656706(name: "getAccount",
    meth: HttpMethod.HttpGet, host: "email.amazonaws.com",
    route: "/v1/email/account", validator: validate_GetAccount_402656707,
    base: "/", makeUrl: url_GetAccount_402656708,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBlacklistReports_402656718 = ref object of OpenApiRestCall_402656044
proc url_GetBlacklistReports_402656720(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBlacklistReports_402656719(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieve a list of the blacklists that your dedicated IP addresses appear on.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   BlacklistItemNames: JArray (required)
                                  ##                     : A list of IP addresses that you want to retrieve blacklist information about. You can only specify the dedicated IP addresses that you use to send email using Amazon Pinpoint or Amazon SES.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `BlacklistItemNames` field"
  var valid_402656721 = query.getOrDefault("BlacklistItemNames")
  valid_402656721 = validateParameter(valid_402656721, JArray, required = true,
                                      default = nil)
  if valid_402656721 != nil:
    section.add "BlacklistItemNames", valid_402656721
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656722 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-Security-Token", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-Signature")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-Signature", valid_402656723
  var valid_402656724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656724
  var valid_402656725 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656725 = validateParameter(valid_402656725, JString,
                                      required = false, default = nil)
  if valid_402656725 != nil:
    section.add "X-Amz-Algorithm", valid_402656725
  var valid_402656726 = header.getOrDefault("X-Amz-Date")
  valid_402656726 = validateParameter(valid_402656726, JString,
                                      required = false, default = nil)
  if valid_402656726 != nil:
    section.add "X-Amz-Date", valid_402656726
  var valid_402656727 = header.getOrDefault("X-Amz-Credential")
  valid_402656727 = validateParameter(valid_402656727, JString,
                                      required = false, default = nil)
  if valid_402656727 != nil:
    section.add "X-Amz-Credential", valid_402656727
  var valid_402656728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656728 = validateParameter(valid_402656728, JString,
                                      required = false, default = nil)
  if valid_402656728 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656728
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656729: Call_GetBlacklistReports_402656718;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve a list of the blacklists that your dedicated IP addresses appear on.
                                                                                         ## 
  let valid = call_402656729.validator(path, query, header, formData, body, _)
  let scheme = call_402656729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656729.makeUrl(scheme.get, call_402656729.host, call_402656729.base,
                                   call_402656729.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656729, uri, valid, _)

proc call*(call_402656730: Call_GetBlacklistReports_402656718;
           BlacklistItemNames: JsonNode): Recallable =
  ## getBlacklistReports
  ## Retrieve a list of the blacklists that your dedicated IP addresses appear on.
  ##   
                                                                                  ## BlacklistItemNames: JArray (required)
                                                                                  ##                     
                                                                                  ## : 
                                                                                  ## A 
                                                                                  ## list 
                                                                                  ## of 
                                                                                  ## IP 
                                                                                  ## addresses 
                                                                                  ## that 
                                                                                  ## you 
                                                                                  ## want 
                                                                                  ## to 
                                                                                  ## retrieve 
                                                                                  ## blacklist 
                                                                                  ## information 
                                                                                  ## about. 
                                                                                  ## You 
                                                                                  ## can 
                                                                                  ## only 
                                                                                  ## specify 
                                                                                  ## the 
                                                                                  ## dedicated 
                                                                                  ## IP 
                                                                                  ## addresses 
                                                                                  ## that 
                                                                                  ## you 
                                                                                  ## use 
                                                                                  ## to 
                                                                                  ## send 
                                                                                  ## email 
                                                                                  ## using 
                                                                                  ## Amazon 
                                                                                  ## Pinpoint 
                                                                                  ## or 
                                                                                  ## Amazon 
                                                                                  ## SES.
  var query_402656731 = newJObject()
  if BlacklistItemNames != nil:
    query_402656731.add "BlacklistItemNames", BlacklistItemNames
  result = call_402656730.call(nil, query_402656731, nil, nil, nil)

var getBlacklistReports* = Call_GetBlacklistReports_402656718(
    name: "getBlacklistReports", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard/blacklist-report#BlacklistItemNames",
    validator: validate_GetBlacklistReports_402656719, base: "/",
    makeUrl: url_GetBlacklistReports_402656720,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDedicatedIp_402656732 = ref object of OpenApiRestCall_402656044
proc url_GetDedicatedIp_402656734(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IP" in path, "`IP` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/dedicated-ips/"),
                 (kind: VariableSegment, value: "IP")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDedicatedIp_402656733(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Get information about a dedicated IP address, including the name of the dedicated IP pool that it's associated with, as well information about the automatic warm-up process for the address.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IP: JString (required)
                                 ##     : A dedicated IP address that is associated with your Amazon Pinpoint account.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `IP` field"
  var valid_402656735 = path.getOrDefault("IP")
  valid_402656735 = validateParameter(valid_402656735, JString, required = true,
                                      default = nil)
  if valid_402656735 != nil:
    section.add "IP", valid_402656735
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656736 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "X-Amz-Security-Token", valid_402656736
  var valid_402656737 = header.getOrDefault("X-Amz-Signature")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-Signature", valid_402656737
  var valid_402656738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656738 = validateParameter(valid_402656738, JString,
                                      required = false, default = nil)
  if valid_402656738 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656738
  var valid_402656739 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-Algorithm", valid_402656739
  var valid_402656740 = header.getOrDefault("X-Amz-Date")
  valid_402656740 = validateParameter(valid_402656740, JString,
                                      required = false, default = nil)
  if valid_402656740 != nil:
    section.add "X-Amz-Date", valid_402656740
  var valid_402656741 = header.getOrDefault("X-Amz-Credential")
  valid_402656741 = validateParameter(valid_402656741, JString,
                                      required = false, default = nil)
  if valid_402656741 != nil:
    section.add "X-Amz-Credential", valid_402656741
  var valid_402656742 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656742 = validateParameter(valid_402656742, JString,
                                      required = false, default = nil)
  if valid_402656742 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656742
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656743: Call_GetDedicatedIp_402656732; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get information about a dedicated IP address, including the name of the dedicated IP pool that it's associated with, as well information about the automatic warm-up process for the address.
                                                                                         ## 
  let valid = call_402656743.validator(path, query, header, formData, body, _)
  let scheme = call_402656743.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656743.makeUrl(scheme.get, call_402656743.host, call_402656743.base,
                                   call_402656743.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656743, uri, valid, _)

proc call*(call_402656744: Call_GetDedicatedIp_402656732; IP: string): Recallable =
  ## getDedicatedIp
  ## Get information about a dedicated IP address, including the name of the dedicated IP pool that it's associated with, as well information about the automatic warm-up process for the address.
  ##   
                                                                                                                                                                                                  ## IP: string (required)
                                                                                                                                                                                                  ##     
                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                  ## A 
                                                                                                                                                                                                  ## dedicated 
                                                                                                                                                                                                  ## IP 
                                                                                                                                                                                                  ## address 
                                                                                                                                                                                                  ## that 
                                                                                                                                                                                                  ## is 
                                                                                                                                                                                                  ## associated 
                                                                                                                                                                                                  ## with 
                                                                                                                                                                                                  ## your 
                                                                                                                                                                                                  ## Amazon 
                                                                                                                                                                                                  ## Pinpoint 
                                                                                                                                                                                                  ## account.
  var path_402656745 = newJObject()
  add(path_402656745, "IP", newJString(IP))
  result = call_402656744.call(path_402656745, nil, nil, nil, nil)

var getDedicatedIp* = Call_GetDedicatedIp_402656732(name: "getDedicatedIp",
    meth: HttpMethod.HttpGet, host: "email.amazonaws.com",
    route: "/v1/email/dedicated-ips/{IP}", validator: validate_GetDedicatedIp_402656733,
    base: "/", makeUrl: url_GetDedicatedIp_402656734,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDedicatedIps_402656746 = ref object of OpenApiRestCall_402656044
proc url_GetDedicatedIps_402656748(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDedicatedIps_402656747(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List the dedicated IP addresses that are associated with your Amazon Pinpoint account.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JInt
                                  ##           : The number of results to show in a single call to <code>GetDedicatedIpsRequest</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   
                                                                                                                                                                                                                                                                                                                                        ## PoolName: JString
                                                                                                                                                                                                                                                                                                                                        ##           
                                                                                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                                                                                        ## The 
                                                                                                                                                                                                                                                                                                                                        ## name 
                                                                                                                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                                                                                                                        ## a 
                                                                                                                                                                                                                                                                                                                                        ## dedicated 
                                                                                                                                                                                                                                                                                                                                        ## IP 
                                                                                                                                                                                                                                                                                                                                        ## pool.
  ##   
                                                                                                                                                                                                                                                                                                                                                ## NextToken: JString
                                                                                                                                                                                                                                                                                                                                                ##            
                                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                                ## A 
                                                                                                                                                                                                                                                                                                                                                ## token 
                                                                                                                                                                                                                                                                                                                                                ## returned 
                                                                                                                                                                                                                                                                                                                                                ## from 
                                                                                                                                                                                                                                                                                                                                                ## a 
                                                                                                                                                                                                                                                                                                                                                ## previous 
                                                                                                                                                                                                                                                                                                                                                ## call 
                                                                                                                                                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                                                                                                                                                ## <code>GetDedicatedIps</code> 
                                                                                                                                                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                                                                                                                                                ## indicate 
                                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                                ## position 
                                                                                                                                                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                                ## dedicated 
                                                                                                                                                                                                                                                                                                                                                ## IP 
                                                                                                                                                                                                                                                                                                                                                ## pool 
                                                                                                                                                                                                                                                                                                                                                ## in 
                                                                                                                                                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                                                                                                                                                ## list 
                                                                                                                                                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                                                                                                                                                ## IP 
                                                                                                                                                                                                                                                                                                                                                ## pools.
  section = newJObject()
  var valid_402656749 = query.getOrDefault("PageSize")
  valid_402656749 = validateParameter(valid_402656749, JInt, required = false,
                                      default = nil)
  if valid_402656749 != nil:
    section.add "PageSize", valid_402656749
  var valid_402656750 = query.getOrDefault("PoolName")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "PoolName", valid_402656750
  var valid_402656751 = query.getOrDefault("NextToken")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "NextToken", valid_402656751
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656752 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "X-Amz-Security-Token", valid_402656752
  var valid_402656753 = header.getOrDefault("X-Amz-Signature")
  valid_402656753 = validateParameter(valid_402656753, JString,
                                      required = false, default = nil)
  if valid_402656753 != nil:
    section.add "X-Amz-Signature", valid_402656753
  var valid_402656754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656754 = validateParameter(valid_402656754, JString,
                                      required = false, default = nil)
  if valid_402656754 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656754
  var valid_402656755 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656755 = validateParameter(valid_402656755, JString,
                                      required = false, default = nil)
  if valid_402656755 != nil:
    section.add "X-Amz-Algorithm", valid_402656755
  var valid_402656756 = header.getOrDefault("X-Amz-Date")
  valid_402656756 = validateParameter(valid_402656756, JString,
                                      required = false, default = nil)
  if valid_402656756 != nil:
    section.add "X-Amz-Date", valid_402656756
  var valid_402656757 = header.getOrDefault("X-Amz-Credential")
  valid_402656757 = validateParameter(valid_402656757, JString,
                                      required = false, default = nil)
  if valid_402656757 != nil:
    section.add "X-Amz-Credential", valid_402656757
  var valid_402656758 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656758 = validateParameter(valid_402656758, JString,
                                      required = false, default = nil)
  if valid_402656758 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656758
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656759: Call_GetDedicatedIps_402656746; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List the dedicated IP addresses that are associated with your Amazon Pinpoint account.
                                                                                         ## 
  let valid = call_402656759.validator(path, query, header, formData, body, _)
  let scheme = call_402656759.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656759.makeUrl(scheme.get, call_402656759.host, call_402656759.base,
                                   call_402656759.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656759, uri, valid, _)

proc call*(call_402656760: Call_GetDedicatedIps_402656746; PageSize: int = 0;
           PoolName: string = ""; NextToken: string = ""): Recallable =
  ## getDedicatedIps
  ## List the dedicated IP addresses that are associated with your Amazon Pinpoint account.
  ##   
                                                                                           ## PageSize: int
                                                                                           ##           
                                                                                           ## : 
                                                                                           ## The 
                                                                                           ## number 
                                                                                           ## of 
                                                                                           ## results 
                                                                                           ## to 
                                                                                           ## show 
                                                                                           ## in 
                                                                                           ## a 
                                                                                           ## single 
                                                                                           ## call 
                                                                                           ## to 
                                                                                           ## <code>GetDedicatedIpsRequest</code>. 
                                                                                           ## If 
                                                                                           ## the 
                                                                                           ## number 
                                                                                           ## of 
                                                                                           ## results 
                                                                                           ## is 
                                                                                           ## larger 
                                                                                           ## than 
                                                                                           ## the 
                                                                                           ## number 
                                                                                           ## you 
                                                                                           ## specified 
                                                                                           ## in 
                                                                                           ## this 
                                                                                           ## parameter, 
                                                                                           ## then 
                                                                                           ## the 
                                                                                           ## response 
                                                                                           ## includes 
                                                                                           ## a 
                                                                                           ## <code>NextToken</code> 
                                                                                           ## element, 
                                                                                           ## which 
                                                                                           ## you 
                                                                                           ## can 
                                                                                           ## use 
                                                                                           ## to 
                                                                                           ## obtain 
                                                                                           ## additional 
                                                                                           ## results.
  ##   
                                                                                                      ## PoolName: string
                                                                                                      ##           
                                                                                                      ## : 
                                                                                                      ## The 
                                                                                                      ## name 
                                                                                                      ## of 
                                                                                                      ## a 
                                                                                                      ## dedicated 
                                                                                                      ## IP 
                                                                                                      ## pool.
  ##   
                                                                                                              ## NextToken: string
                                                                                                              ##            
                                                                                                              ## : 
                                                                                                              ## A 
                                                                                                              ## token 
                                                                                                              ## returned 
                                                                                                              ## from 
                                                                                                              ## a 
                                                                                                              ## previous 
                                                                                                              ## call 
                                                                                                              ## to 
                                                                                                              ## <code>GetDedicatedIps</code> 
                                                                                                              ## to 
                                                                                                              ## indicate 
                                                                                                              ## the 
                                                                                                              ## position 
                                                                                                              ## of 
                                                                                                              ## the 
                                                                                                              ## dedicated 
                                                                                                              ## IP 
                                                                                                              ## pool 
                                                                                                              ## in 
                                                                                                              ## the 
                                                                                                              ## list 
                                                                                                              ## of 
                                                                                                              ## IP 
                                                                                                              ## pools.
  var query_402656761 = newJObject()
  add(query_402656761, "PageSize", newJInt(PageSize))
  add(query_402656761, "PoolName", newJString(PoolName))
  add(query_402656761, "NextToken", newJString(NextToken))
  result = call_402656760.call(nil, query_402656761, nil, nil, nil)

var getDedicatedIps* = Call_GetDedicatedIps_402656746(name: "getDedicatedIps",
    meth: HttpMethod.HttpGet, host: "email.amazonaws.com",
    route: "/v1/email/dedicated-ips", validator: validate_GetDedicatedIps_402656747,
    base: "/", makeUrl: url_GetDedicatedIps_402656748,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDeliverabilityDashboardOption_402656774 = ref object of OpenApiRestCall_402656044
proc url_PutDeliverabilityDashboardOption_402656776(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutDeliverabilityDashboardOption_402656775(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Enable or disable the Deliverability dashboard for your Amazon Pinpoint account. When you enable the Deliverability dashboard, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email using Amazon Pinpoint. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon Pinpoint. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/pinpoint/pricing/">Amazon Pinpoint Pricing</a>.</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656777 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656777 = validateParameter(valid_402656777, JString,
                                      required = false, default = nil)
  if valid_402656777 != nil:
    section.add "X-Amz-Security-Token", valid_402656777
  var valid_402656778 = header.getOrDefault("X-Amz-Signature")
  valid_402656778 = validateParameter(valid_402656778, JString,
                                      required = false, default = nil)
  if valid_402656778 != nil:
    section.add "X-Amz-Signature", valid_402656778
  var valid_402656779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656779 = validateParameter(valid_402656779, JString,
                                      required = false, default = nil)
  if valid_402656779 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656779
  var valid_402656780 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656780 = validateParameter(valid_402656780, JString,
                                      required = false, default = nil)
  if valid_402656780 != nil:
    section.add "X-Amz-Algorithm", valid_402656780
  var valid_402656781 = header.getOrDefault("X-Amz-Date")
  valid_402656781 = validateParameter(valid_402656781, JString,
                                      required = false, default = nil)
  if valid_402656781 != nil:
    section.add "X-Amz-Date", valid_402656781
  var valid_402656782 = header.getOrDefault("X-Amz-Credential")
  valid_402656782 = validateParameter(valid_402656782, JString,
                                      required = false, default = nil)
  if valid_402656782 != nil:
    section.add "X-Amz-Credential", valid_402656782
  var valid_402656783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656783 = validateParameter(valid_402656783, JString,
                                      required = false, default = nil)
  if valid_402656783 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656783
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656785: Call_PutDeliverabilityDashboardOption_402656774;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Enable or disable the Deliverability dashboard for your Amazon Pinpoint account. When you enable the Deliverability dashboard, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email using Amazon Pinpoint. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon Pinpoint. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/pinpoint/pricing/">Amazon Pinpoint Pricing</a>.</p>
                                                                                         ## 
  let valid = call_402656785.validator(path, query, header, formData, body, _)
  let scheme = call_402656785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656785.makeUrl(scheme.get, call_402656785.host, call_402656785.base,
                                   call_402656785.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656785, uri, valid, _)

proc call*(call_402656786: Call_PutDeliverabilityDashboardOption_402656774;
           body: JsonNode): Recallable =
  ## putDeliverabilityDashboardOption
  ## <p>Enable or disable the Deliverability dashboard for your Amazon Pinpoint account. When you enable the Deliverability dashboard, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email using Amazon Pinpoint. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon Pinpoint. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/pinpoint/pricing/">Amazon Pinpoint Pricing</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  var body_402656787 = newJObject()
  if body != nil:
    body_402656787 = body
  result = call_402656786.call(nil, nil, nil, nil, body_402656787)

var putDeliverabilityDashboardOption* = Call_PutDeliverabilityDashboardOption_402656774(
    name: "putDeliverabilityDashboardOption", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard",
    validator: validate_PutDeliverabilityDashboardOption_402656775, base: "/",
    makeUrl: url_PutDeliverabilityDashboardOption_402656776,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeliverabilityDashboardOptions_402656762 = ref object of OpenApiRestCall_402656044
proc url_GetDeliverabilityDashboardOptions_402656764(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeliverabilityDashboardOptions_402656763(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Retrieve information about the status of the Deliverability dashboard for your Amazon Pinpoint account. When the Deliverability dashboard is enabled, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email using Amazon Pinpoint. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon Pinpoint. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/pinpoint/pricing/">Amazon Pinpoint Pricing</a>.</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656765 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "X-Amz-Security-Token", valid_402656765
  var valid_402656766 = header.getOrDefault("X-Amz-Signature")
  valid_402656766 = validateParameter(valid_402656766, JString,
                                      required = false, default = nil)
  if valid_402656766 != nil:
    section.add "X-Amz-Signature", valid_402656766
  var valid_402656767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656767 = validateParameter(valid_402656767, JString,
                                      required = false, default = nil)
  if valid_402656767 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656767
  var valid_402656768 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656768 = validateParameter(valid_402656768, JString,
                                      required = false, default = nil)
  if valid_402656768 != nil:
    section.add "X-Amz-Algorithm", valid_402656768
  var valid_402656769 = header.getOrDefault("X-Amz-Date")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "X-Amz-Date", valid_402656769
  var valid_402656770 = header.getOrDefault("X-Amz-Credential")
  valid_402656770 = validateParameter(valid_402656770, JString,
                                      required = false, default = nil)
  if valid_402656770 != nil:
    section.add "X-Amz-Credential", valid_402656770
  var valid_402656771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656771 = validateParameter(valid_402656771, JString,
                                      required = false, default = nil)
  if valid_402656771 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656771
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656772: Call_GetDeliverabilityDashboardOptions_402656762;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieve information about the status of the Deliverability dashboard for your Amazon Pinpoint account. When the Deliverability dashboard is enabled, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email using Amazon Pinpoint. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon Pinpoint. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/pinpoint/pricing/">Amazon Pinpoint Pricing</a>.</p>
                                                                                         ## 
  let valid = call_402656772.validator(path, query, header, formData, body, _)
  let scheme = call_402656772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656772.makeUrl(scheme.get, call_402656772.host, call_402656772.base,
                                   call_402656772.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656772, uri, valid, _)

proc call*(call_402656773: Call_GetDeliverabilityDashboardOptions_402656762): Recallable =
  ## getDeliverabilityDashboardOptions
  ## <p>Retrieve information about the status of the Deliverability dashboard for your Amazon Pinpoint account. When the Deliverability dashboard is enabled, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email using Amazon Pinpoint. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon Pinpoint. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/pinpoint/pricing/">Amazon Pinpoint Pricing</a>.</p>
  result = call_402656773.call(nil, nil, nil, nil, nil)

var getDeliverabilityDashboardOptions* = Call_GetDeliverabilityDashboardOptions_402656762(
    name: "getDeliverabilityDashboardOptions", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard",
    validator: validate_GetDeliverabilityDashboardOptions_402656763, base: "/",
    makeUrl: url_GetDeliverabilityDashboardOptions_402656764,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeliverabilityTestReport_402656788 = ref object of OpenApiRestCall_402656044
proc url_GetDeliverabilityTestReport_402656790(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ReportId" in path, "`ReportId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/v1/email/deliverability-dashboard/test-reports/"),
                 (kind: VariableSegment, value: "ReportId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDeliverabilityTestReport_402656789(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieve the results of a predictive inbox placement test.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ReportId: JString (required)
                                 ##           : A unique string that identifies a Deliverability dashboard report.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `ReportId` field"
  var valid_402656791 = path.getOrDefault("ReportId")
  valid_402656791 = validateParameter(valid_402656791, JString, required = true,
                                      default = nil)
  if valid_402656791 != nil:
    section.add "ReportId", valid_402656791
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656792 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656792 = validateParameter(valid_402656792, JString,
                                      required = false, default = nil)
  if valid_402656792 != nil:
    section.add "X-Amz-Security-Token", valid_402656792
  var valid_402656793 = header.getOrDefault("X-Amz-Signature")
  valid_402656793 = validateParameter(valid_402656793, JString,
                                      required = false, default = nil)
  if valid_402656793 != nil:
    section.add "X-Amz-Signature", valid_402656793
  var valid_402656794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656794 = validateParameter(valid_402656794, JString,
                                      required = false, default = nil)
  if valid_402656794 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656794
  var valid_402656795 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656795 = validateParameter(valid_402656795, JString,
                                      required = false, default = nil)
  if valid_402656795 != nil:
    section.add "X-Amz-Algorithm", valid_402656795
  var valid_402656796 = header.getOrDefault("X-Amz-Date")
  valid_402656796 = validateParameter(valid_402656796, JString,
                                      required = false, default = nil)
  if valid_402656796 != nil:
    section.add "X-Amz-Date", valid_402656796
  var valid_402656797 = header.getOrDefault("X-Amz-Credential")
  valid_402656797 = validateParameter(valid_402656797, JString,
                                      required = false, default = nil)
  if valid_402656797 != nil:
    section.add "X-Amz-Credential", valid_402656797
  var valid_402656798 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656798 = validateParameter(valid_402656798, JString,
                                      required = false, default = nil)
  if valid_402656798 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656798
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656799: Call_GetDeliverabilityTestReport_402656788;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve the results of a predictive inbox placement test.
                                                                                         ## 
  let valid = call_402656799.validator(path, query, header, formData, body, _)
  let scheme = call_402656799.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656799.makeUrl(scheme.get, call_402656799.host, call_402656799.base,
                                   call_402656799.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656799, uri, valid, _)

proc call*(call_402656800: Call_GetDeliverabilityTestReport_402656788;
           ReportId: string): Recallable =
  ## getDeliverabilityTestReport
  ## Retrieve the results of a predictive inbox placement test.
  ##   ReportId: string (required)
                                                               ##           : A unique string that identifies a Deliverability dashboard report.
  var path_402656801 = newJObject()
  add(path_402656801, "ReportId", newJString(ReportId))
  result = call_402656800.call(path_402656801, nil, nil, nil, nil)

var getDeliverabilityTestReport* = Call_GetDeliverabilityTestReport_402656788(
    name: "getDeliverabilityTestReport", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v1/email/deliverability-dashboard/test-reports/{ReportId}",
    validator: validate_GetDeliverabilityTestReport_402656789, base: "/",
    makeUrl: url_GetDeliverabilityTestReport_402656790,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainDeliverabilityCampaign_402656802 = ref object of OpenApiRestCall_402656044
proc url_GetDomainDeliverabilityCampaign_402656804(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "CampaignId" in path, "`CampaignId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/v1/email/deliverability-dashboard/campaigns/"),
                 (kind: VariableSegment, value: "CampaignId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDomainDeliverabilityCampaign_402656803(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieve all the deliverability data for a specific campaign. This data is available for a campaign only if the campaign sent email by using a domain that the Deliverability dashboard is enabled for (<code>PutDeliverabilityDashboardOption</code> operation).
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   CampaignId: JString (required)
                                 ##             : The unique identifier for the campaign. Amazon Pinpoint automatically generates and assigns this identifier to a campaign. This value is not the same as the campaign identifier that Amazon Pinpoint assigns to campaigns that you create and manage by using the Amazon Pinpoint API or the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `CampaignId` field"
  var valid_402656805 = path.getOrDefault("CampaignId")
  valid_402656805 = validateParameter(valid_402656805, JString, required = true,
                                      default = nil)
  if valid_402656805 != nil:
    section.add "CampaignId", valid_402656805
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656806 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656806 = validateParameter(valid_402656806, JString,
                                      required = false, default = nil)
  if valid_402656806 != nil:
    section.add "X-Amz-Security-Token", valid_402656806
  var valid_402656807 = header.getOrDefault("X-Amz-Signature")
  valid_402656807 = validateParameter(valid_402656807, JString,
                                      required = false, default = nil)
  if valid_402656807 != nil:
    section.add "X-Amz-Signature", valid_402656807
  var valid_402656808 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656808 = validateParameter(valid_402656808, JString,
                                      required = false, default = nil)
  if valid_402656808 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656808
  var valid_402656809 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656809 = validateParameter(valid_402656809, JString,
                                      required = false, default = nil)
  if valid_402656809 != nil:
    section.add "X-Amz-Algorithm", valid_402656809
  var valid_402656810 = header.getOrDefault("X-Amz-Date")
  valid_402656810 = validateParameter(valid_402656810, JString,
                                      required = false, default = nil)
  if valid_402656810 != nil:
    section.add "X-Amz-Date", valid_402656810
  var valid_402656811 = header.getOrDefault("X-Amz-Credential")
  valid_402656811 = validateParameter(valid_402656811, JString,
                                      required = false, default = nil)
  if valid_402656811 != nil:
    section.add "X-Amz-Credential", valid_402656811
  var valid_402656812 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656812 = validateParameter(valid_402656812, JString,
                                      required = false, default = nil)
  if valid_402656812 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656812
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656813: Call_GetDomainDeliverabilityCampaign_402656802;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve all the deliverability data for a specific campaign. This data is available for a campaign only if the campaign sent email by using a domain that the Deliverability dashboard is enabled for (<code>PutDeliverabilityDashboardOption</code> operation).
                                                                                         ## 
  let valid = call_402656813.validator(path, query, header, formData, body, _)
  let scheme = call_402656813.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656813.makeUrl(scheme.get, call_402656813.host, call_402656813.base,
                                   call_402656813.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656813, uri, valid, _)

proc call*(call_402656814: Call_GetDomainDeliverabilityCampaign_402656802;
           CampaignId: string): Recallable =
  ## getDomainDeliverabilityCampaign
  ## Retrieve all the deliverability data for a specific campaign. This data is available for a campaign only if the campaign sent email by using a domain that the Deliverability dashboard is enabled for (<code>PutDeliverabilityDashboardOption</code> operation).
  ##   
                                                                                                                                                                                                                                                                      ## CampaignId: string (required)
                                                                                                                                                                                                                                                                      ##             
                                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                                      ## The 
                                                                                                                                                                                                                                                                      ## unique 
                                                                                                                                                                                                                                                                      ## identifier 
                                                                                                                                                                                                                                                                      ## for 
                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                      ## campaign. 
                                                                                                                                                                                                                                                                      ## Amazon 
                                                                                                                                                                                                                                                                      ## Pinpoint 
                                                                                                                                                                                                                                                                      ## automatically 
                                                                                                                                                                                                                                                                      ## generates 
                                                                                                                                                                                                                                                                      ## and 
                                                                                                                                                                                                                                                                      ## assigns 
                                                                                                                                                                                                                                                                      ## this 
                                                                                                                                                                                                                                                                      ## identifier 
                                                                                                                                                                                                                                                                      ## to 
                                                                                                                                                                                                                                                                      ## a 
                                                                                                                                                                                                                                                                      ## campaign. 
                                                                                                                                                                                                                                                                      ## This 
                                                                                                                                                                                                                                                                      ## value 
                                                                                                                                                                                                                                                                      ## is 
                                                                                                                                                                                                                                                                      ## not 
                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                      ## same 
                                                                                                                                                                                                                                                                      ## as 
                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                      ## campaign 
                                                                                                                                                                                                                                                                      ## identifier 
                                                                                                                                                                                                                                                                      ## that 
                                                                                                                                                                                                                                                                      ## Amazon 
                                                                                                                                                                                                                                                                      ## Pinpoint 
                                                                                                                                                                                                                                                                      ## assigns 
                                                                                                                                                                                                                                                                      ## to 
                                                                                                                                                                                                                                                                      ## campaigns 
                                                                                                                                                                                                                                                                      ## that 
                                                                                                                                                                                                                                                                      ## you 
                                                                                                                                                                                                                                                                      ## create 
                                                                                                                                                                                                                                                                      ## and 
                                                                                                                                                                                                                                                                      ## manage 
                                                                                                                                                                                                                                                                      ## by 
                                                                                                                                                                                                                                                                      ## using 
                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                      ## Amazon 
                                                                                                                                                                                                                                                                      ## Pinpoint 
                                                                                                                                                                                                                                                                      ## API 
                                                                                                                                                                                                                                                                      ## or 
                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                      ## Amazon 
                                                                                                                                                                                                                                                                      ## Pinpoint 
                                                                                                                                                                                                                                                                      ## console.
  var path_402656815 = newJObject()
  add(path_402656815, "CampaignId", newJString(CampaignId))
  result = call_402656814.call(path_402656815, nil, nil, nil, nil)

var getDomainDeliverabilityCampaign* = Call_GetDomainDeliverabilityCampaign_402656802(
    name: "getDomainDeliverabilityCampaign", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v1/email/deliverability-dashboard/campaigns/{CampaignId}",
    validator: validate_GetDomainDeliverabilityCampaign_402656803, base: "/",
    makeUrl: url_GetDomainDeliverabilityCampaign_402656804,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainStatisticsReport_402656816 = ref object of OpenApiRestCall_402656044
proc url_GetDomainStatisticsReport_402656818(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Domain" in path, "`Domain` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/deliverability-dashboard/statistics-report/"),
                 (kind: VariableSegment, value: "Domain"),
                 (kind: ConstantSegment, value: "#StartDate&EndDate")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDomainStatisticsReport_402656817(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieve inbox placement and engagement rates for the domains that you use to send email.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Domain: JString (required)
                                 ##         : The domain that you want to obtain deliverability metrics for.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `Domain` field"
  var valid_402656819 = path.getOrDefault("Domain")
  valid_402656819 = validateParameter(valid_402656819, JString, required = true,
                                      default = nil)
  if valid_402656819 != nil:
    section.add "Domain", valid_402656819
  result.add "path", section
  ## parameters in `query` object:
  ##   StartDate: JString (required)
                                  ##            : The first day (in Unix time) that you want to obtain domain deliverability metrics for.
  ##   
                                                                                                                                         ## EndDate: JString (required)
                                                                                                                                         ##          
                                                                                                                                         ## : 
                                                                                                                                         ## The 
                                                                                                                                         ## last 
                                                                                                                                         ## day 
                                                                                                                                         ## (in 
                                                                                                                                         ## Unix 
                                                                                                                                         ## time) 
                                                                                                                                         ## that 
                                                                                                                                         ## you 
                                                                                                                                         ## want 
                                                                                                                                         ## to 
                                                                                                                                         ## obtain 
                                                                                                                                         ## domain 
                                                                                                                                         ## deliverability 
                                                                                                                                         ## metrics 
                                                                                                                                         ## for. 
                                                                                                                                         ## The 
                                                                                                                                         ## <code>EndDate</code> 
                                                                                                                                         ## that 
                                                                                                                                         ## you 
                                                                                                                                         ## specify 
                                                                                                                                         ## has 
                                                                                                                                         ## to 
                                                                                                                                         ## be 
                                                                                                                                         ## less 
                                                                                                                                         ## than 
                                                                                                                                         ## or 
                                                                                                                                         ## equal 
                                                                                                                                         ## to 
                                                                                                                                         ## 30 
                                                                                                                                         ## days 
                                                                                                                                         ## after 
                                                                                                                                         ## the 
                                                                                                                                         ## <code>StartDate</code>.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `StartDate` field"
  var valid_402656820 = query.getOrDefault("StartDate")
  valid_402656820 = validateParameter(valid_402656820, JString, required = true,
                                      default = nil)
  if valid_402656820 != nil:
    section.add "StartDate", valid_402656820
  var valid_402656821 = query.getOrDefault("EndDate")
  valid_402656821 = validateParameter(valid_402656821, JString, required = true,
                                      default = nil)
  if valid_402656821 != nil:
    section.add "EndDate", valid_402656821
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656822 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656822 = validateParameter(valid_402656822, JString,
                                      required = false, default = nil)
  if valid_402656822 != nil:
    section.add "X-Amz-Security-Token", valid_402656822
  var valid_402656823 = header.getOrDefault("X-Amz-Signature")
  valid_402656823 = validateParameter(valid_402656823, JString,
                                      required = false, default = nil)
  if valid_402656823 != nil:
    section.add "X-Amz-Signature", valid_402656823
  var valid_402656824 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656824 = validateParameter(valid_402656824, JString,
                                      required = false, default = nil)
  if valid_402656824 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656824
  var valid_402656825 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656825 = validateParameter(valid_402656825, JString,
                                      required = false, default = nil)
  if valid_402656825 != nil:
    section.add "X-Amz-Algorithm", valid_402656825
  var valid_402656826 = header.getOrDefault("X-Amz-Date")
  valid_402656826 = validateParameter(valid_402656826, JString,
                                      required = false, default = nil)
  if valid_402656826 != nil:
    section.add "X-Amz-Date", valid_402656826
  var valid_402656827 = header.getOrDefault("X-Amz-Credential")
  valid_402656827 = validateParameter(valid_402656827, JString,
                                      required = false, default = nil)
  if valid_402656827 != nil:
    section.add "X-Amz-Credential", valid_402656827
  var valid_402656828 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656828 = validateParameter(valid_402656828, JString,
                                      required = false, default = nil)
  if valid_402656828 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656828
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656829: Call_GetDomainStatisticsReport_402656816;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve inbox placement and engagement rates for the domains that you use to send email.
                                                                                         ## 
  let valid = call_402656829.validator(path, query, header, formData, body, _)
  let scheme = call_402656829.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656829.makeUrl(scheme.get, call_402656829.host, call_402656829.base,
                                   call_402656829.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656829, uri, valid, _)

proc call*(call_402656830: Call_GetDomainStatisticsReport_402656816;
           StartDate: string; EndDate: string; Domain: string): Recallable =
  ## getDomainStatisticsReport
  ## Retrieve inbox placement and engagement rates for the domains that you use to send email.
  ##   
                                                                                              ## StartDate: string (required)
                                                                                              ##            
                                                                                              ## : 
                                                                                              ## The 
                                                                                              ## first 
                                                                                              ## day 
                                                                                              ## (in 
                                                                                              ## Unix 
                                                                                              ## time) 
                                                                                              ## that 
                                                                                              ## you 
                                                                                              ## want 
                                                                                              ## to 
                                                                                              ## obtain 
                                                                                              ## domain 
                                                                                              ## deliverability 
                                                                                              ## metrics 
                                                                                              ## for.
  ##   
                                                                                                     ## EndDate: string (required)
                                                                                                     ##          
                                                                                                     ## : 
                                                                                                     ## The 
                                                                                                     ## last 
                                                                                                     ## day 
                                                                                                     ## (in 
                                                                                                     ## Unix 
                                                                                                     ## time) 
                                                                                                     ## that 
                                                                                                     ## you 
                                                                                                     ## want 
                                                                                                     ## to 
                                                                                                     ## obtain 
                                                                                                     ## domain 
                                                                                                     ## deliverability 
                                                                                                     ## metrics 
                                                                                                     ## for. 
                                                                                                     ## The 
                                                                                                     ## <code>EndDate</code> 
                                                                                                     ## that 
                                                                                                     ## you 
                                                                                                     ## specify 
                                                                                                     ## has 
                                                                                                     ## to 
                                                                                                     ## be 
                                                                                                     ## less 
                                                                                                     ## than 
                                                                                                     ## or 
                                                                                                     ## equal 
                                                                                                     ## to 
                                                                                                     ## 30 
                                                                                                     ## days 
                                                                                                     ## after 
                                                                                                     ## the 
                                                                                                     ## <code>StartDate</code>.
  ##   
                                                                                                                               ## Domain: string (required)
                                                                                                                               ##         
                                                                                                                               ## : 
                                                                                                                               ## The 
                                                                                                                               ## domain 
                                                                                                                               ## that 
                                                                                                                               ## you 
                                                                                                                               ## want 
                                                                                                                               ## to 
                                                                                                                               ## obtain 
                                                                                                                               ## deliverability 
                                                                                                                               ## metrics 
                                                                                                                               ## for.
  var path_402656831 = newJObject()
  var query_402656832 = newJObject()
  add(query_402656832, "StartDate", newJString(StartDate))
  add(query_402656832, "EndDate", newJString(EndDate))
  add(path_402656831, "Domain", newJString(Domain))
  result = call_402656830.call(path_402656831, query_402656832, nil, nil, nil)

var getDomainStatisticsReport* = Call_GetDomainStatisticsReport_402656816(
    name: "getDomainStatisticsReport", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard/statistics-report/{Domain}#StartDate&EndDate",
    validator: validate_GetDomainStatisticsReport_402656817, base: "/",
    makeUrl: url_GetDomainStatisticsReport_402656818,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeliverabilityTestReports_402656833 = ref object of OpenApiRestCall_402656044
proc url_ListDeliverabilityTestReports_402656835(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDeliverabilityTestReports_402656834(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Show a list of the predictive inbox placement tests that you've performed, regardless of their statuses. For predictive inbox placement tests that are complete, you can use the <code>GetDeliverabilityTestReport</code> operation to view the results.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JInt
                                  ##           : <p>The number of results to show in a single call to <code>ListDeliverabilityTestReports</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.</p> <p>The value you specify has to be at least 0, and can be no more than 1000.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                       ## NextToken: JString
                                                                                                                                                                                                                                                                                                                                                                                                                                       ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                       ## A 
                                                                                                                                                                                                                                                                                                                                                                                                                                       ## token 
                                                                                                                                                                                                                                                                                                                                                                                                                                       ## returned 
                                                                                                                                                                                                                                                                                                                                                                                                                                       ## from 
                                                                                                                                                                                                                                                                                                                                                                                                                                       ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                       ## previous 
                                                                                                                                                                                                                                                                                                                                                                                                                                       ## call 
                                                                                                                                                                                                                                                                                                                                                                                                                                       ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                       ## <code>ListDeliverabilityTestReports</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                       ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                       ## indicate 
                                                                                                                                                                                                                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                       ## position 
                                                                                                                                                                                                                                                                                                                                                                                                                                       ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                       ## list 
                                                                                                                                                                                                                                                                                                                                                                                                                                       ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                       ## predictive 
                                                                                                                                                                                                                                                                                                                                                                                                                                       ## inbox 
                                                                                                                                                                                                                                                                                                                                                                                                                                       ## placement 
                                                                                                                                                                                                                                                                                                                                                                                                                                       ## tests.
  section = newJObject()
  var valid_402656836 = query.getOrDefault("PageSize")
  valid_402656836 = validateParameter(valid_402656836, JInt, required = false,
                                      default = nil)
  if valid_402656836 != nil:
    section.add "PageSize", valid_402656836
  var valid_402656837 = query.getOrDefault("NextToken")
  valid_402656837 = validateParameter(valid_402656837, JString,
                                      required = false, default = nil)
  if valid_402656837 != nil:
    section.add "NextToken", valid_402656837
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656838 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656838 = validateParameter(valid_402656838, JString,
                                      required = false, default = nil)
  if valid_402656838 != nil:
    section.add "X-Amz-Security-Token", valid_402656838
  var valid_402656839 = header.getOrDefault("X-Amz-Signature")
  valid_402656839 = validateParameter(valid_402656839, JString,
                                      required = false, default = nil)
  if valid_402656839 != nil:
    section.add "X-Amz-Signature", valid_402656839
  var valid_402656840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656840 = validateParameter(valid_402656840, JString,
                                      required = false, default = nil)
  if valid_402656840 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656840
  var valid_402656841 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656841 = validateParameter(valid_402656841, JString,
                                      required = false, default = nil)
  if valid_402656841 != nil:
    section.add "X-Amz-Algorithm", valid_402656841
  var valid_402656842 = header.getOrDefault("X-Amz-Date")
  valid_402656842 = validateParameter(valid_402656842, JString,
                                      required = false, default = nil)
  if valid_402656842 != nil:
    section.add "X-Amz-Date", valid_402656842
  var valid_402656843 = header.getOrDefault("X-Amz-Credential")
  valid_402656843 = validateParameter(valid_402656843, JString,
                                      required = false, default = nil)
  if valid_402656843 != nil:
    section.add "X-Amz-Credential", valid_402656843
  var valid_402656844 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656844 = validateParameter(valid_402656844, JString,
                                      required = false, default = nil)
  if valid_402656844 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656844
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656845: Call_ListDeliverabilityTestReports_402656833;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Show a list of the predictive inbox placement tests that you've performed, regardless of their statuses. For predictive inbox placement tests that are complete, you can use the <code>GetDeliverabilityTestReport</code> operation to view the results.
                                                                                         ## 
  let valid = call_402656845.validator(path, query, header, formData, body, _)
  let scheme = call_402656845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656845.makeUrl(scheme.get, call_402656845.host, call_402656845.base,
                                   call_402656845.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656845, uri, valid, _)

proc call*(call_402656846: Call_ListDeliverabilityTestReports_402656833;
           PageSize: int = 0; NextToken: string = ""): Recallable =
  ## listDeliverabilityTestReports
  ## Show a list of the predictive inbox placement tests that you've performed, regardless of their statuses. For predictive inbox placement tests that are complete, you can use the <code>GetDeliverabilityTestReport</code> operation to view the results.
  ##   
                                                                                                                                                                                                                                                             ## PageSize: int
                                                                                                                                                                                                                                                             ##           
                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                             ## <p>The 
                                                                                                                                                                                                                                                             ## number 
                                                                                                                                                                                                                                                             ## of 
                                                                                                                                                                                                                                                             ## results 
                                                                                                                                                                                                                                                             ## to 
                                                                                                                                                                                                                                                             ## show 
                                                                                                                                                                                                                                                             ## in 
                                                                                                                                                                                                                                                             ## a 
                                                                                                                                                                                                                                                             ## single 
                                                                                                                                                                                                                                                             ## call 
                                                                                                                                                                                                                                                             ## to 
                                                                                                                                                                                                                                                             ## <code>ListDeliverabilityTestReports</code>. 
                                                                                                                                                                                                                                                             ## If 
                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                             ## number 
                                                                                                                                                                                                                                                             ## of 
                                                                                                                                                                                                                                                             ## results 
                                                                                                                                                                                                                                                             ## is 
                                                                                                                                                                                                                                                             ## larger 
                                                                                                                                                                                                                                                             ## than 
                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                             ## number 
                                                                                                                                                                                                                                                             ## you 
                                                                                                                                                                                                                                                             ## specified 
                                                                                                                                                                                                                                                             ## in 
                                                                                                                                                                                                                                                             ## this 
                                                                                                                                                                                                                                                             ## parameter, 
                                                                                                                                                                                                                                                             ## then 
                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                             ## response 
                                                                                                                                                                                                                                                             ## includes 
                                                                                                                                                                                                                                                             ## a 
                                                                                                                                                                                                                                                             ## <code>NextToken</code> 
                                                                                                                                                                                                                                                             ## element, 
                                                                                                                                                                                                                                                             ## which 
                                                                                                                                                                                                                                                             ## you 
                                                                                                                                                                                                                                                             ## can 
                                                                                                                                                                                                                                                             ## use 
                                                                                                                                                                                                                                                             ## to 
                                                                                                                                                                                                                                                             ## obtain 
                                                                                                                                                                                                                                                             ## additional 
                                                                                                                                                                                                                                                             ## results.</p> 
                                                                                                                                                                                                                                                             ## <p>The 
                                                                                                                                                                                                                                                             ## value 
                                                                                                                                                                                                                                                             ## you 
                                                                                                                                                                                                                                                             ## specify 
                                                                                                                                                                                                                                                             ## has 
                                                                                                                                                                                                                                                             ## to 
                                                                                                                                                                                                                                                             ## be 
                                                                                                                                                                                                                                                             ## at 
                                                                                                                                                                                                                                                             ## least 
                                                                                                                                                                                                                                                             ## 0, 
                                                                                                                                                                                                                                                             ## and 
                                                                                                                                                                                                                                                             ## can 
                                                                                                                                                                                                                                                             ## be 
                                                                                                                                                                                                                                                             ## no 
                                                                                                                                                                                                                                                             ## more 
                                                                                                                                                                                                                                                             ## than 
                                                                                                                                                                                                                                                             ## 1000.</p>
  ##   
                                                                                                                                                                                                                                                                         ## NextToken: string
                                                                                                                                                                                                                                                                         ##            
                                                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                                                         ## A 
                                                                                                                                                                                                                                                                         ## token 
                                                                                                                                                                                                                                                                         ## returned 
                                                                                                                                                                                                                                                                         ## from 
                                                                                                                                                                                                                                                                         ## a 
                                                                                                                                                                                                                                                                         ## previous 
                                                                                                                                                                                                                                                                         ## call 
                                                                                                                                                                                                                                                                         ## to 
                                                                                                                                                                                                                                                                         ## <code>ListDeliverabilityTestReports</code> 
                                                                                                                                                                                                                                                                         ## to 
                                                                                                                                                                                                                                                                         ## indicate 
                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                         ## position 
                                                                                                                                                                                                                                                                         ## in 
                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                         ## list 
                                                                                                                                                                                                                                                                         ## of 
                                                                                                                                                                                                                                                                         ## predictive 
                                                                                                                                                                                                                                                                         ## inbox 
                                                                                                                                                                                                                                                                         ## placement 
                                                                                                                                                                                                                                                                         ## tests.
  var query_402656847 = newJObject()
  add(query_402656847, "PageSize", newJInt(PageSize))
  add(query_402656847, "NextToken", newJString(NextToken))
  result = call_402656846.call(nil, query_402656847, nil, nil, nil)

var listDeliverabilityTestReports* = Call_ListDeliverabilityTestReports_402656833(
    name: "listDeliverabilityTestReports", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v1/email/deliverability-dashboard/test-reports",
    validator: validate_ListDeliverabilityTestReports_402656834, base: "/",
    makeUrl: url_ListDeliverabilityTestReports_402656835,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomainDeliverabilityCampaigns_402656848 = ref object of OpenApiRestCall_402656044
proc url_ListDomainDeliverabilityCampaigns_402656850(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "SubscribedDomain" in path,
         "`SubscribedDomain` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/v1/email/deliverability-dashboard/domains/"),
                 (kind: VariableSegment, value: "SubscribedDomain"),
                 (kind: ConstantSegment, value: "/campaigns#StartDate&EndDate")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDomainDeliverabilityCampaigns_402656849(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieve deliverability data for all the campaigns that used a specific domain to send email during a specified time range. This data is available for a domain only if you enabled the Deliverability dashboard (<code>PutDeliverabilityDashboardOption</code> operation) for the domain.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   SubscribedDomain: JString (required)
                                 ##                   : The domain to obtain deliverability data for.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `SubscribedDomain` field"
  var valid_402656851 = path.getOrDefault("SubscribedDomain")
  valid_402656851 = validateParameter(valid_402656851, JString, required = true,
                                      default = nil)
  if valid_402656851 != nil:
    section.add "SubscribedDomain", valid_402656851
  result.add "path", section
  ## parameters in `query` object:
  ##   StartDate: JString (required)
                                  ##            : The first day, in Unix time format, that you want to obtain deliverability data for.
  ##   
                                                                                                                                      ## PageSize: JInt
                                                                                                                                      ##           
                                                                                                                                      ## : 
                                                                                                                                      ## The 
                                                                                                                                      ## maximum 
                                                                                                                                      ## number 
                                                                                                                                      ## of 
                                                                                                                                      ## results 
                                                                                                                                      ## to 
                                                                                                                                      ## include 
                                                                                                                                      ## in 
                                                                                                                                      ## response 
                                                                                                                                      ## to 
                                                                                                                                      ## a 
                                                                                                                                      ## single 
                                                                                                                                      ## call 
                                                                                                                                      ## to 
                                                                                                                                      ## the 
                                                                                                                                      ## <code>ListDomainDeliverabilityCampaigns</code> 
                                                                                                                                      ## operation. 
                                                                                                                                      ## If 
                                                                                                                                      ## the 
                                                                                                                                      ## number 
                                                                                                                                      ## of 
                                                                                                                                      ## results 
                                                                                                                                      ## is 
                                                                                                                                      ## larger 
                                                                                                                                      ## than 
                                                                                                                                      ## the 
                                                                                                                                      ## number 
                                                                                                                                      ## that 
                                                                                                                                      ## you 
                                                                                                                                      ## specify 
                                                                                                                                      ## in 
                                                                                                                                      ## this 
                                                                                                                                      ## parameter, 
                                                                                                                                      ## the 
                                                                                                                                      ## response 
                                                                                                                                      ## includes 
                                                                                                                                      ## a 
                                                                                                                                      ## <code>NextToken</code> 
                                                                                                                                      ## element, 
                                                                                                                                      ## which 
                                                                                                                                      ## you 
                                                                                                                                      ## can 
                                                                                                                                      ## use 
                                                                                                                                      ## to 
                                                                                                                                      ## obtain 
                                                                                                                                      ## additional 
                                                                                                                                      ## results.
  ##   
                                                                                                                                                 ## EndDate: JString (required)
                                                                                                                                                 ##          
                                                                                                                                                 ## : 
                                                                                                                                                 ## The 
                                                                                                                                                 ## last 
                                                                                                                                                 ## day, 
                                                                                                                                                 ## in 
                                                                                                                                                 ## Unix 
                                                                                                                                                 ## time 
                                                                                                                                                 ## format, 
                                                                                                                                                 ## that 
                                                                                                                                                 ## you 
                                                                                                                                                 ## want 
                                                                                                                                                 ## to 
                                                                                                                                                 ## obtain 
                                                                                                                                                 ## deliverability 
                                                                                                                                                 ## data 
                                                                                                                                                 ## for. 
                                                                                                                                                 ## This 
                                                                                                                                                 ## value 
                                                                                                                                                 ## has 
                                                                                                                                                 ## to 
                                                                                                                                                 ## be 
                                                                                                                                                 ## less 
                                                                                                                                                 ## than 
                                                                                                                                                 ## or 
                                                                                                                                                 ## equal 
                                                                                                                                                 ## to 
                                                                                                                                                 ## 30 
                                                                                                                                                 ## days 
                                                                                                                                                 ## after 
                                                                                                                                                 ## the 
                                                                                                                                                 ## value 
                                                                                                                                                 ## of 
                                                                                                                                                 ## the 
                                                                                                                                                 ## <code>StartDate</code> 
                                                                                                                                                 ## parameter.
  ##   
                                                                                                                                                              ## NextToken: JString
                                                                                                                                                              ##            
                                                                                                                                                              ## : 
                                                                                                                                                              ## A 
                                                                                                                                                              ## token 
                                                                                                                                                              ## that’s 
                                                                                                                                                              ## returned 
                                                                                                                                                              ## from 
                                                                                                                                                              ## a 
                                                                                                                                                              ## previous 
                                                                                                                                                              ## call 
                                                                                                                                                              ## to 
                                                                                                                                                              ## the 
                                                                                                                                                              ## <code>ListDomainDeliverabilityCampaigns</code> 
                                                                                                                                                              ## operation. 
                                                                                                                                                              ## This 
                                                                                                                                                              ## token 
                                                                                                                                                              ## indicates 
                                                                                                                                                              ## the 
                                                                                                                                                              ## position 
                                                                                                                                                              ## of 
                                                                                                                                                              ## a 
                                                                                                                                                              ## campaign 
                                                                                                                                                              ## in 
                                                                                                                                                              ## the 
                                                                                                                                                              ## list 
                                                                                                                                                              ## of 
                                                                                                                                                              ## campaigns.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `StartDate` field"
  var valid_402656852 = query.getOrDefault("StartDate")
  valid_402656852 = validateParameter(valid_402656852, JString, required = true,
                                      default = nil)
  if valid_402656852 != nil:
    section.add "StartDate", valid_402656852
  var valid_402656853 = query.getOrDefault("PageSize")
  valid_402656853 = validateParameter(valid_402656853, JInt, required = false,
                                      default = nil)
  if valid_402656853 != nil:
    section.add "PageSize", valid_402656853
  var valid_402656854 = query.getOrDefault("EndDate")
  valid_402656854 = validateParameter(valid_402656854, JString, required = true,
                                      default = nil)
  if valid_402656854 != nil:
    section.add "EndDate", valid_402656854
  var valid_402656855 = query.getOrDefault("NextToken")
  valid_402656855 = validateParameter(valid_402656855, JString,
                                      required = false, default = nil)
  if valid_402656855 != nil:
    section.add "NextToken", valid_402656855
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656856 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656856 = validateParameter(valid_402656856, JString,
                                      required = false, default = nil)
  if valid_402656856 != nil:
    section.add "X-Amz-Security-Token", valid_402656856
  var valid_402656857 = header.getOrDefault("X-Amz-Signature")
  valid_402656857 = validateParameter(valid_402656857, JString,
                                      required = false, default = nil)
  if valid_402656857 != nil:
    section.add "X-Amz-Signature", valid_402656857
  var valid_402656858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656858 = validateParameter(valid_402656858, JString,
                                      required = false, default = nil)
  if valid_402656858 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656858
  var valid_402656859 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656859 = validateParameter(valid_402656859, JString,
                                      required = false, default = nil)
  if valid_402656859 != nil:
    section.add "X-Amz-Algorithm", valid_402656859
  var valid_402656860 = header.getOrDefault("X-Amz-Date")
  valid_402656860 = validateParameter(valid_402656860, JString,
                                      required = false, default = nil)
  if valid_402656860 != nil:
    section.add "X-Amz-Date", valid_402656860
  var valid_402656861 = header.getOrDefault("X-Amz-Credential")
  valid_402656861 = validateParameter(valid_402656861, JString,
                                      required = false, default = nil)
  if valid_402656861 != nil:
    section.add "X-Amz-Credential", valid_402656861
  var valid_402656862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656862 = validateParameter(valid_402656862, JString,
                                      required = false, default = nil)
  if valid_402656862 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656863: Call_ListDomainDeliverabilityCampaigns_402656848;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve deliverability data for all the campaigns that used a specific domain to send email during a specified time range. This data is available for a domain only if you enabled the Deliverability dashboard (<code>PutDeliverabilityDashboardOption</code> operation) for the domain.
                                                                                         ## 
  let valid = call_402656863.validator(path, query, header, formData, body, _)
  let scheme = call_402656863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656863.makeUrl(scheme.get, call_402656863.host, call_402656863.base,
                                   call_402656863.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656863, uri, valid, _)

proc call*(call_402656864: Call_ListDomainDeliverabilityCampaigns_402656848;
           StartDate: string; EndDate: string; SubscribedDomain: string;
           PageSize: int = 0; NextToken: string = ""): Recallable =
  ## listDomainDeliverabilityCampaigns
  ## Retrieve deliverability data for all the campaigns that used a specific domain to send email during a specified time range. This data is available for a domain only if you enabled the Deliverability dashboard (<code>PutDeliverabilityDashboardOption</code> operation) for the domain.
  ##   
                                                                                                                                                                                                                                                                                               ## StartDate: string (required)
                                                                                                                                                                                                                                                                                               ##            
                                                                                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                                                                                               ## The 
                                                                                                                                                                                                                                                                                               ## first 
                                                                                                                                                                                                                                                                                               ## day, 
                                                                                                                                                                                                                                                                                               ## in 
                                                                                                                                                                                                                                                                                               ## Unix 
                                                                                                                                                                                                                                                                                               ## time 
                                                                                                                                                                                                                                                                                               ## format, 
                                                                                                                                                                                                                                                                                               ## that 
                                                                                                                                                                                                                                                                                               ## you 
                                                                                                                                                                                                                                                                                               ## want 
                                                                                                                                                                                                                                                                                               ## to 
                                                                                                                                                                                                                                                                                               ## obtain 
                                                                                                                                                                                                                                                                                               ## deliverability 
                                                                                                                                                                                                                                                                                               ## data 
                                                                                                                                                                                                                                                                                               ## for.
  ##   
                                                                                                                                                                                                                                                                                                      ## PageSize: int
                                                                                                                                                                                                                                                                                                      ##           
                                                                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                                                                      ## The 
                                                                                                                                                                                                                                                                                                      ## maximum 
                                                                                                                                                                                                                                                                                                      ## number 
                                                                                                                                                                                                                                                                                                      ## of 
                                                                                                                                                                                                                                                                                                      ## results 
                                                                                                                                                                                                                                                                                                      ## to 
                                                                                                                                                                                                                                                                                                      ## include 
                                                                                                                                                                                                                                                                                                      ## in 
                                                                                                                                                                                                                                                                                                      ## response 
                                                                                                                                                                                                                                                                                                      ## to 
                                                                                                                                                                                                                                                                                                      ## a 
                                                                                                                                                                                                                                                                                                      ## single 
                                                                                                                                                                                                                                                                                                      ## call 
                                                                                                                                                                                                                                                                                                      ## to 
                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                      ## <code>ListDomainDeliverabilityCampaigns</code> 
                                                                                                                                                                                                                                                                                                      ## operation. 
                                                                                                                                                                                                                                                                                                      ## If 
                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                      ## number 
                                                                                                                                                                                                                                                                                                      ## of 
                                                                                                                                                                                                                                                                                                      ## results 
                                                                                                                                                                                                                                                                                                      ## is 
                                                                                                                                                                                                                                                                                                      ## larger 
                                                                                                                                                                                                                                                                                                      ## than 
                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                      ## number 
                                                                                                                                                                                                                                                                                                      ## that 
                                                                                                                                                                                                                                                                                                      ## you 
                                                                                                                                                                                                                                                                                                      ## specify 
                                                                                                                                                                                                                                                                                                      ## in 
                                                                                                                                                                                                                                                                                                      ## this 
                                                                                                                                                                                                                                                                                                      ## parameter, 
                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                      ## response 
                                                                                                                                                                                                                                                                                                      ## includes 
                                                                                                                                                                                                                                                                                                      ## a 
                                                                                                                                                                                                                                                                                                      ## <code>NextToken</code> 
                                                                                                                                                                                                                                                                                                      ## element, 
                                                                                                                                                                                                                                                                                                      ## which 
                                                                                                                                                                                                                                                                                                      ## you 
                                                                                                                                                                                                                                                                                                      ## can 
                                                                                                                                                                                                                                                                                                      ## use 
                                                                                                                                                                                                                                                                                                      ## to 
                                                                                                                                                                                                                                                                                                      ## obtain 
                                                                                                                                                                                                                                                                                                      ## additional 
                                                                                                                                                                                                                                                                                                      ## results.
  ##   
                                                                                                                                                                                                                                                                                                                 ## EndDate: string (required)
                                                                                                                                                                                                                                                                                                                 ##          
                                                                                                                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                                                                                                                 ## The 
                                                                                                                                                                                                                                                                                                                 ## last 
                                                                                                                                                                                                                                                                                                                 ## day, 
                                                                                                                                                                                                                                                                                                                 ## in 
                                                                                                                                                                                                                                                                                                                 ## Unix 
                                                                                                                                                                                                                                                                                                                 ## time 
                                                                                                                                                                                                                                                                                                                 ## format, 
                                                                                                                                                                                                                                                                                                                 ## that 
                                                                                                                                                                                                                                                                                                                 ## you 
                                                                                                                                                                                                                                                                                                                 ## want 
                                                                                                                                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                                                                                                                                 ## obtain 
                                                                                                                                                                                                                                                                                                                 ## deliverability 
                                                                                                                                                                                                                                                                                                                 ## data 
                                                                                                                                                                                                                                                                                                                 ## for. 
                                                                                                                                                                                                                                                                                                                 ## This 
                                                                                                                                                                                                                                                                                                                 ## value 
                                                                                                                                                                                                                                                                                                                 ## has 
                                                                                                                                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                                                                                                                                 ## be 
                                                                                                                                                                                                                                                                                                                 ## less 
                                                                                                                                                                                                                                                                                                                 ## than 
                                                                                                                                                                                                                                                                                                                 ## or 
                                                                                                                                                                                                                                                                                                                 ## equal 
                                                                                                                                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                                                                                                                                 ## 30 
                                                                                                                                                                                                                                                                                                                 ## days 
                                                                                                                                                                                                                                                                                                                 ## after 
                                                                                                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                                                                                                 ## value 
                                                                                                                                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                                                                                                 ## <code>StartDate</code> 
                                                                                                                                                                                                                                                                                                                 ## parameter.
  ##   
                                                                                                                                                                                                                                                                                                                              ## SubscribedDomain: string (required)
                                                                                                                                                                                                                                                                                                                              ##                   
                                                                                                                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                                                                                                                              ## The 
                                                                                                                                                                                                                                                                                                                              ## domain 
                                                                                                                                                                                                                                                                                                                              ## to 
                                                                                                                                                                                                                                                                                                                              ## obtain 
                                                                                                                                                                                                                                                                                                                              ## deliverability 
                                                                                                                                                                                                                                                                                                                              ## data 
                                                                                                                                                                                                                                                                                                                              ## for.
  ##   
                                                                                                                                                                                                                                                                                                                                     ## NextToken: string
                                                                                                                                                                                                                                                                                                                                     ##            
                                                                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                                                                     ## A 
                                                                                                                                                                                                                                                                                                                                     ## token 
                                                                                                                                                                                                                                                                                                                                     ## that’s 
                                                                                                                                                                                                                                                                                                                                     ## returned 
                                                                                                                                                                                                                                                                                                                                     ## from 
                                                                                                                                                                                                                                                                                                                                     ## a 
                                                                                                                                                                                                                                                                                                                                     ## previous 
                                                                                                                                                                                                                                                                                                                                     ## call 
                                                                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                     ## <code>ListDomainDeliverabilityCampaigns</code> 
                                                                                                                                                                                                                                                                                                                                     ## operation. 
                                                                                                                                                                                                                                                                                                                                     ## This 
                                                                                                                                                                                                                                                                                                                                     ## token 
                                                                                                                                                                                                                                                                                                                                     ## indicates 
                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                     ## position 
                                                                                                                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                                                                                                                     ## a 
                                                                                                                                                                                                                                                                                                                                     ## campaign 
                                                                                                                                                                                                                                                                                                                                     ## in 
                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                     ## list 
                                                                                                                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                                                                                                                     ## campaigns.
  var path_402656865 = newJObject()
  var query_402656866 = newJObject()
  add(query_402656866, "StartDate", newJString(StartDate))
  add(query_402656866, "PageSize", newJInt(PageSize))
  add(query_402656866, "EndDate", newJString(EndDate))
  add(path_402656865, "SubscribedDomain", newJString(SubscribedDomain))
  add(query_402656866, "NextToken", newJString(NextToken))
  result = call_402656864.call(path_402656865, query_402656866, nil, nil, nil)

var listDomainDeliverabilityCampaigns* = Call_ListDomainDeliverabilityCampaigns_402656848(
    name: "listDomainDeliverabilityCampaigns", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard/domains/{SubscribedDomain}/campaigns#StartDate&EndDate",
    validator: validate_ListDomainDeliverabilityCampaigns_402656849, base: "/",
    makeUrl: url_ListDomainDeliverabilityCampaigns_402656850,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402656867 = ref object of OpenApiRestCall_402656044
proc url_ListTagsForResource_402656869(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_402656868(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieve a list of the tags (keys and values) that are associated with a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource in Amazon Pinpoint. Each tag consists of a required <i>tag key</i> and an optional associated <i>tag value</i>. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceArn: JString (required)
                                  ##              : The Amazon Resource Name (ARN) of the resource that you want to retrieve tag information for.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `ResourceArn` field"
  var valid_402656870 = query.getOrDefault("ResourceArn")
  valid_402656870 = validateParameter(valid_402656870, JString, required = true,
                                      default = nil)
  if valid_402656870 != nil:
    section.add "ResourceArn", valid_402656870
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656871 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656871 = validateParameter(valid_402656871, JString,
                                      required = false, default = nil)
  if valid_402656871 != nil:
    section.add "X-Amz-Security-Token", valid_402656871
  var valid_402656872 = header.getOrDefault("X-Amz-Signature")
  valid_402656872 = validateParameter(valid_402656872, JString,
                                      required = false, default = nil)
  if valid_402656872 != nil:
    section.add "X-Amz-Signature", valid_402656872
  var valid_402656873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656873 = validateParameter(valid_402656873, JString,
                                      required = false, default = nil)
  if valid_402656873 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656873
  var valid_402656874 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656874 = validateParameter(valid_402656874, JString,
                                      required = false, default = nil)
  if valid_402656874 != nil:
    section.add "X-Amz-Algorithm", valid_402656874
  var valid_402656875 = header.getOrDefault("X-Amz-Date")
  valid_402656875 = validateParameter(valid_402656875, JString,
                                      required = false, default = nil)
  if valid_402656875 != nil:
    section.add "X-Amz-Date", valid_402656875
  var valid_402656876 = header.getOrDefault("X-Amz-Credential")
  valid_402656876 = validateParameter(valid_402656876, JString,
                                      required = false, default = nil)
  if valid_402656876 != nil:
    section.add "X-Amz-Credential", valid_402656876
  var valid_402656877 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656877 = validateParameter(valid_402656877, JString,
                                      required = false, default = nil)
  if valid_402656877 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656877
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656878: Call_ListTagsForResource_402656867;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve a list of the tags (keys and values) that are associated with a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource in Amazon Pinpoint. Each tag consists of a required <i>tag key</i> and an optional associated <i>tag value</i>. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.
                                                                                         ## 
  let valid = call_402656878.validator(path, query, header, formData, body, _)
  let scheme = call_402656878.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656878.makeUrl(scheme.get, call_402656878.host, call_402656878.base,
                                   call_402656878.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656878, uri, valid, _)

proc call*(call_402656879: Call_ListTagsForResource_402656867;
           ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieve a list of the tags (keys and values) that are associated with a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource in Amazon Pinpoint. Each tag consists of a required <i>tag key</i> and an optional associated <i>tag value</i>. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                             ## ResourceArn: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                             ##              
                                                                                                                                                                                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                             ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                             ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                             ## Resource 
                                                                                                                                                                                                                                                                                                                                                                                                                                             ## Name 
                                                                                                                                                                                                                                                                                                                                                                                                                                             ## (ARN) 
                                                                                                                                                                                                                                                                                                                                                                                                                                             ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                             ## resource 
                                                                                                                                                                                                                                                                                                                                                                                                                                             ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                             ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                             ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                                             ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                             ## retrieve 
                                                                                                                                                                                                                                                                                                                                                                                                                                             ## tag 
                                                                                                                                                                                                                                                                                                                                                                                                                                             ## information 
                                                                                                                                                                                                                                                                                                                                                                                                                                             ## for.
  var query_402656880 = newJObject()
  add(query_402656880, "ResourceArn", newJString(ResourceArn))
  result = call_402656879.call(nil, query_402656880, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_402656867(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/tags#ResourceArn",
    validator: validate_ListTagsForResource_402656868, base: "/",
    makeUrl: url_ListTagsForResource_402656869,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAccountDedicatedIpWarmupAttributes_402656881 = ref object of OpenApiRestCall_402656044
proc url_PutAccountDedicatedIpWarmupAttributes_402656883(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutAccountDedicatedIpWarmupAttributes_402656882(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Enable or disable the automatic warm-up feature for dedicated IP addresses.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656884 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656884 = validateParameter(valid_402656884, JString,
                                      required = false, default = nil)
  if valid_402656884 != nil:
    section.add "X-Amz-Security-Token", valid_402656884
  var valid_402656885 = header.getOrDefault("X-Amz-Signature")
  valid_402656885 = validateParameter(valid_402656885, JString,
                                      required = false, default = nil)
  if valid_402656885 != nil:
    section.add "X-Amz-Signature", valid_402656885
  var valid_402656886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656886 = validateParameter(valid_402656886, JString,
                                      required = false, default = nil)
  if valid_402656886 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656886
  var valid_402656887 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656887 = validateParameter(valid_402656887, JString,
                                      required = false, default = nil)
  if valid_402656887 != nil:
    section.add "X-Amz-Algorithm", valid_402656887
  var valid_402656888 = header.getOrDefault("X-Amz-Date")
  valid_402656888 = validateParameter(valid_402656888, JString,
                                      required = false, default = nil)
  if valid_402656888 != nil:
    section.add "X-Amz-Date", valid_402656888
  var valid_402656889 = header.getOrDefault("X-Amz-Credential")
  valid_402656889 = validateParameter(valid_402656889, JString,
                                      required = false, default = nil)
  if valid_402656889 != nil:
    section.add "X-Amz-Credential", valid_402656889
  var valid_402656890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656890 = validateParameter(valid_402656890, JString,
                                      required = false, default = nil)
  if valid_402656890 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656892: Call_PutAccountDedicatedIpWarmupAttributes_402656881;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Enable or disable the automatic warm-up feature for dedicated IP addresses.
                                                                                         ## 
  let valid = call_402656892.validator(path, query, header, formData, body, _)
  let scheme = call_402656892.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656892.makeUrl(scheme.get, call_402656892.host, call_402656892.base,
                                   call_402656892.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656892, uri, valid, _)

proc call*(call_402656893: Call_PutAccountDedicatedIpWarmupAttributes_402656881;
           body: JsonNode): Recallable =
  ## putAccountDedicatedIpWarmupAttributes
  ## Enable or disable the automatic warm-up feature for dedicated IP addresses.
  ##   
                                                                                ## body: JObject (required)
  var body_402656894 = newJObject()
  if body != nil:
    body_402656894 = body
  result = call_402656893.call(nil, nil, nil, nil, body_402656894)

var putAccountDedicatedIpWarmupAttributes* = Call_PutAccountDedicatedIpWarmupAttributes_402656881(
    name: "putAccountDedicatedIpWarmupAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v1/email/account/dedicated-ips/warmup",
    validator: validate_PutAccountDedicatedIpWarmupAttributes_402656882,
    base: "/", makeUrl: url_PutAccountDedicatedIpWarmupAttributes_402656883,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAccountSendingAttributes_402656895 = ref object of OpenApiRestCall_402656044
proc url_PutAccountSendingAttributes_402656897(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutAccountSendingAttributes_402656896(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Enable or disable the ability of your account to send email.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656898 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656898 = validateParameter(valid_402656898, JString,
                                      required = false, default = nil)
  if valid_402656898 != nil:
    section.add "X-Amz-Security-Token", valid_402656898
  var valid_402656899 = header.getOrDefault("X-Amz-Signature")
  valid_402656899 = validateParameter(valid_402656899, JString,
                                      required = false, default = nil)
  if valid_402656899 != nil:
    section.add "X-Amz-Signature", valid_402656899
  var valid_402656900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656900 = validateParameter(valid_402656900, JString,
                                      required = false, default = nil)
  if valid_402656900 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656900
  var valid_402656901 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656901 = validateParameter(valid_402656901, JString,
                                      required = false, default = nil)
  if valid_402656901 != nil:
    section.add "X-Amz-Algorithm", valid_402656901
  var valid_402656902 = header.getOrDefault("X-Amz-Date")
  valid_402656902 = validateParameter(valid_402656902, JString,
                                      required = false, default = nil)
  if valid_402656902 != nil:
    section.add "X-Amz-Date", valid_402656902
  var valid_402656903 = header.getOrDefault("X-Amz-Credential")
  valid_402656903 = validateParameter(valid_402656903, JString,
                                      required = false, default = nil)
  if valid_402656903 != nil:
    section.add "X-Amz-Credential", valid_402656903
  var valid_402656904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656904 = validateParameter(valid_402656904, JString,
                                      required = false, default = nil)
  if valid_402656904 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656904
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656906: Call_PutAccountSendingAttributes_402656895;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Enable or disable the ability of your account to send email.
                                                                                         ## 
  let valid = call_402656906.validator(path, query, header, formData, body, _)
  let scheme = call_402656906.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656906.makeUrl(scheme.get, call_402656906.host, call_402656906.base,
                                   call_402656906.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656906, uri, valid, _)

proc call*(call_402656907: Call_PutAccountSendingAttributes_402656895;
           body: JsonNode): Recallable =
  ## putAccountSendingAttributes
  ## Enable or disable the ability of your account to send email.
  ##   body: JObject (required)
  var body_402656908 = newJObject()
  if body != nil:
    body_402656908 = body
  result = call_402656907.call(nil, nil, nil, nil, body_402656908)

var putAccountSendingAttributes* = Call_PutAccountSendingAttributes_402656895(
    name: "putAccountSendingAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/account/sending",
    validator: validate_PutAccountSendingAttributes_402656896, base: "/",
    makeUrl: url_PutAccountSendingAttributes_402656897,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetDeliveryOptions_402656909 = ref object of OpenApiRestCall_402656044
proc url_PutConfigurationSetDeliveryOptions_402656911(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
         "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/configuration-sets/"),
                 (kind: VariableSegment, value: "ConfigurationSetName"),
                 (kind: ConstantSegment, value: "/delivery-options")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutConfigurationSetDeliveryOptions_402656910(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Associate a configuration set with a dedicated IP pool. You can use dedicated IP pools to create groups of dedicated IP addresses for sending specific types of email.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
                                 ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_402656912 = path.getOrDefault("ConfigurationSetName")
  valid_402656912 = validateParameter(valid_402656912, JString, required = true,
                                      default = nil)
  if valid_402656912 != nil:
    section.add "ConfigurationSetName", valid_402656912
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656913 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656913 = validateParameter(valid_402656913, JString,
                                      required = false, default = nil)
  if valid_402656913 != nil:
    section.add "X-Amz-Security-Token", valid_402656913
  var valid_402656914 = header.getOrDefault("X-Amz-Signature")
  valid_402656914 = validateParameter(valid_402656914, JString,
                                      required = false, default = nil)
  if valid_402656914 != nil:
    section.add "X-Amz-Signature", valid_402656914
  var valid_402656915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656915 = validateParameter(valid_402656915, JString,
                                      required = false, default = nil)
  if valid_402656915 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656915
  var valid_402656916 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656916 = validateParameter(valid_402656916, JString,
                                      required = false, default = nil)
  if valid_402656916 != nil:
    section.add "X-Amz-Algorithm", valid_402656916
  var valid_402656917 = header.getOrDefault("X-Amz-Date")
  valid_402656917 = validateParameter(valid_402656917, JString,
                                      required = false, default = nil)
  if valid_402656917 != nil:
    section.add "X-Amz-Date", valid_402656917
  var valid_402656918 = header.getOrDefault("X-Amz-Credential")
  valid_402656918 = validateParameter(valid_402656918, JString,
                                      required = false, default = nil)
  if valid_402656918 != nil:
    section.add "X-Amz-Credential", valid_402656918
  var valid_402656919 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656919 = validateParameter(valid_402656919, JString,
                                      required = false, default = nil)
  if valid_402656919 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656919
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656921: Call_PutConfigurationSetDeliveryOptions_402656909;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associate a configuration set with a dedicated IP pool. You can use dedicated IP pools to create groups of dedicated IP addresses for sending specific types of email.
                                                                                         ## 
  let valid = call_402656921.validator(path, query, header, formData, body, _)
  let scheme = call_402656921.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656921.makeUrl(scheme.get, call_402656921.host, call_402656921.base,
                                   call_402656921.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656921, uri, valid, _)

proc call*(call_402656922: Call_PutConfigurationSetDeliveryOptions_402656909;
           ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetDeliveryOptions
  ## Associate a configuration set with a dedicated IP pool. You can use dedicated IP pools to create groups of dedicated IP addresses for sending specific types of email.
  ##   
                                                                                                                                                                           ## ConfigurationSetName: string (required)
                                                                                                                                                                           ##                       
                                                                                                                                                                           ## : 
                                                                                                                                                                           ## <p>The 
                                                                                                                                                                           ## name 
                                                                                                                                                                           ## of 
                                                                                                                                                                           ## a 
                                                                                                                                                                           ## configuration 
                                                                                                                                                                           ## set.</p> 
                                                                                                                                                                           ## <p>In 
                                                                                                                                                                           ## Amazon 
                                                                                                                                                                           ## Pinpoint, 
                                                                                                                                                                           ## <i>configuration 
                                                                                                                                                                           ## sets</i> 
                                                                                                                                                                           ## are 
                                                                                                                                                                           ## groups 
                                                                                                                                                                           ## of 
                                                                                                                                                                           ## rules 
                                                                                                                                                                           ## that 
                                                                                                                                                                           ## you 
                                                                                                                                                                           ## can 
                                                                                                                                                                           ## apply 
                                                                                                                                                                           ## to 
                                                                                                                                                                           ## the 
                                                                                                                                                                           ## emails 
                                                                                                                                                                           ## you 
                                                                                                                                                                           ## send. 
                                                                                                                                                                           ## You 
                                                                                                                                                                           ## apply 
                                                                                                                                                                           ## a 
                                                                                                                                                                           ## configuration 
                                                                                                                                                                           ## set 
                                                                                                                                                                           ## to 
                                                                                                                                                                           ## an 
                                                                                                                                                                           ## email 
                                                                                                                                                                           ## by 
                                                                                                                                                                           ## including 
                                                                                                                                                                           ## a 
                                                                                                                                                                           ## reference 
                                                                                                                                                                           ## to 
                                                                                                                                                                           ## the 
                                                                                                                                                                           ## configuration 
                                                                                                                                                                           ## set 
                                                                                                                                                                           ## in 
                                                                                                                                                                           ## the 
                                                                                                                                                                           ## headers 
                                                                                                                                                                           ## of 
                                                                                                                                                                           ## the 
                                                                                                                                                                           ## email. 
                                                                                                                                                                           ## When 
                                                                                                                                                                           ## you 
                                                                                                                                                                           ## apply 
                                                                                                                                                                           ## a 
                                                                                                                                                                           ## configuration 
                                                                                                                                                                           ## set 
                                                                                                                                                                           ## to 
                                                                                                                                                                           ## an 
                                                                                                                                                                           ## email, 
                                                                                                                                                                           ## all 
                                                                                                                                                                           ## of 
                                                                                                                                                                           ## the 
                                                                                                                                                                           ## rules 
                                                                                                                                                                           ## in 
                                                                                                                                                                           ## that 
                                                                                                                                                                           ## configuration 
                                                                                                                                                                           ## set 
                                                                                                                                                                           ## are 
                                                                                                                                                                           ## applied 
                                                                                                                                                                           ## to 
                                                                                                                                                                           ## the 
                                                                                                                                                                           ## email.</p>
  ##   
                                                                                                                                                                                        ## body: JObject (required)
  var path_402656923 = newJObject()
  var body_402656924 = newJObject()
  add(path_402656923, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_402656924 = body
  result = call_402656922.call(path_402656923, nil, nil, nil, body_402656924)

var putConfigurationSetDeliveryOptions* = Call_PutConfigurationSetDeliveryOptions_402656909(
    name: "putConfigurationSetDeliveryOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/delivery-options",
    validator: validate_PutConfigurationSetDeliveryOptions_402656910, base: "/",
    makeUrl: url_PutConfigurationSetDeliveryOptions_402656911,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetReputationOptions_402656925 = ref object of OpenApiRestCall_402656044
proc url_PutConfigurationSetReputationOptions_402656927(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
         "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/configuration-sets/"),
                 (kind: VariableSegment, value: "ConfigurationSetName"),
                 (kind: ConstantSegment, value: "/reputation-options")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutConfigurationSetReputationOptions_402656926(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Enable or disable collection of reputation metrics for emails that you send using a particular configuration set in a specific AWS Region.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
                                 ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_402656928 = path.getOrDefault("ConfigurationSetName")
  valid_402656928 = validateParameter(valid_402656928, JString, required = true,
                                      default = nil)
  if valid_402656928 != nil:
    section.add "ConfigurationSetName", valid_402656928
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656929 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656929 = validateParameter(valid_402656929, JString,
                                      required = false, default = nil)
  if valid_402656929 != nil:
    section.add "X-Amz-Security-Token", valid_402656929
  var valid_402656930 = header.getOrDefault("X-Amz-Signature")
  valid_402656930 = validateParameter(valid_402656930, JString,
                                      required = false, default = nil)
  if valid_402656930 != nil:
    section.add "X-Amz-Signature", valid_402656930
  var valid_402656931 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656931 = validateParameter(valid_402656931, JString,
                                      required = false, default = nil)
  if valid_402656931 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656931
  var valid_402656932 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656932 = validateParameter(valid_402656932, JString,
                                      required = false, default = nil)
  if valid_402656932 != nil:
    section.add "X-Amz-Algorithm", valid_402656932
  var valid_402656933 = header.getOrDefault("X-Amz-Date")
  valid_402656933 = validateParameter(valid_402656933, JString,
                                      required = false, default = nil)
  if valid_402656933 != nil:
    section.add "X-Amz-Date", valid_402656933
  var valid_402656934 = header.getOrDefault("X-Amz-Credential")
  valid_402656934 = validateParameter(valid_402656934, JString,
                                      required = false, default = nil)
  if valid_402656934 != nil:
    section.add "X-Amz-Credential", valid_402656934
  var valid_402656935 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656935 = validateParameter(valid_402656935, JString,
                                      required = false, default = nil)
  if valid_402656935 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656935
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656937: Call_PutConfigurationSetReputationOptions_402656925;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Enable or disable collection of reputation metrics for emails that you send using a particular configuration set in a specific AWS Region.
                                                                                         ## 
  let valid = call_402656937.validator(path, query, header, formData, body, _)
  let scheme = call_402656937.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656937.makeUrl(scheme.get, call_402656937.host, call_402656937.base,
                                   call_402656937.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656937, uri, valid, _)

proc call*(call_402656938: Call_PutConfigurationSetReputationOptions_402656925;
           ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetReputationOptions
  ## Enable or disable collection of reputation metrics for emails that you send using a particular configuration set in a specific AWS Region.
  ##   
                                                                                                                                               ## ConfigurationSetName: string (required)
                                                                                                                                               ##                       
                                                                                                                                               ## : 
                                                                                                                                               ## <p>The 
                                                                                                                                               ## name 
                                                                                                                                               ## of 
                                                                                                                                               ## a 
                                                                                                                                               ## configuration 
                                                                                                                                               ## set.</p> 
                                                                                                                                               ## <p>In 
                                                                                                                                               ## Amazon 
                                                                                                                                               ## Pinpoint, 
                                                                                                                                               ## <i>configuration 
                                                                                                                                               ## sets</i> 
                                                                                                                                               ## are 
                                                                                                                                               ## groups 
                                                                                                                                               ## of 
                                                                                                                                               ## rules 
                                                                                                                                               ## that 
                                                                                                                                               ## you 
                                                                                                                                               ## can 
                                                                                                                                               ## apply 
                                                                                                                                               ## to 
                                                                                                                                               ## the 
                                                                                                                                               ## emails 
                                                                                                                                               ## you 
                                                                                                                                               ## send. 
                                                                                                                                               ## You 
                                                                                                                                               ## apply 
                                                                                                                                               ## a 
                                                                                                                                               ## configuration 
                                                                                                                                               ## set 
                                                                                                                                               ## to 
                                                                                                                                               ## an 
                                                                                                                                               ## email 
                                                                                                                                               ## by 
                                                                                                                                               ## including 
                                                                                                                                               ## a 
                                                                                                                                               ## reference 
                                                                                                                                               ## to 
                                                                                                                                               ## the 
                                                                                                                                               ## configuration 
                                                                                                                                               ## set 
                                                                                                                                               ## in 
                                                                                                                                               ## the 
                                                                                                                                               ## headers 
                                                                                                                                               ## of 
                                                                                                                                               ## the 
                                                                                                                                               ## email. 
                                                                                                                                               ## When 
                                                                                                                                               ## you 
                                                                                                                                               ## apply 
                                                                                                                                               ## a 
                                                                                                                                               ## configuration 
                                                                                                                                               ## set 
                                                                                                                                               ## to 
                                                                                                                                               ## an 
                                                                                                                                               ## email, 
                                                                                                                                               ## all 
                                                                                                                                               ## of 
                                                                                                                                               ## the 
                                                                                                                                               ## rules 
                                                                                                                                               ## in 
                                                                                                                                               ## that 
                                                                                                                                               ## configuration 
                                                                                                                                               ## set 
                                                                                                                                               ## are 
                                                                                                                                               ## applied 
                                                                                                                                               ## to 
                                                                                                                                               ## the 
                                                                                                                                               ## email.</p>
  ##   
                                                                                                                                                            ## body: JObject (required)
  var path_402656939 = newJObject()
  var body_402656940 = newJObject()
  add(path_402656939, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_402656940 = body
  result = call_402656938.call(path_402656939, nil, nil, nil, body_402656940)

var putConfigurationSetReputationOptions* = Call_PutConfigurationSetReputationOptions_402656925(
    name: "putConfigurationSetReputationOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/reputation-options",
    validator: validate_PutConfigurationSetReputationOptions_402656926,
    base: "/", makeUrl: url_PutConfigurationSetReputationOptions_402656927,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetSendingOptions_402656941 = ref object of OpenApiRestCall_402656044
proc url_PutConfigurationSetSendingOptions_402656943(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
         "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/configuration-sets/"),
                 (kind: VariableSegment, value: "ConfigurationSetName"),
                 (kind: ConstantSegment, value: "/sending")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutConfigurationSetSendingOptions_402656942(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Enable or disable email sending for messages that use a particular configuration set in a specific AWS Region.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
                                 ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_402656944 = path.getOrDefault("ConfigurationSetName")
  valid_402656944 = validateParameter(valid_402656944, JString, required = true,
                                      default = nil)
  if valid_402656944 != nil:
    section.add "ConfigurationSetName", valid_402656944
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656945 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656945 = validateParameter(valid_402656945, JString,
                                      required = false, default = nil)
  if valid_402656945 != nil:
    section.add "X-Amz-Security-Token", valid_402656945
  var valid_402656946 = header.getOrDefault("X-Amz-Signature")
  valid_402656946 = validateParameter(valid_402656946, JString,
                                      required = false, default = nil)
  if valid_402656946 != nil:
    section.add "X-Amz-Signature", valid_402656946
  var valid_402656947 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656947 = validateParameter(valid_402656947, JString,
                                      required = false, default = nil)
  if valid_402656947 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656947
  var valid_402656948 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656948 = validateParameter(valid_402656948, JString,
                                      required = false, default = nil)
  if valid_402656948 != nil:
    section.add "X-Amz-Algorithm", valid_402656948
  var valid_402656949 = header.getOrDefault("X-Amz-Date")
  valid_402656949 = validateParameter(valid_402656949, JString,
                                      required = false, default = nil)
  if valid_402656949 != nil:
    section.add "X-Amz-Date", valid_402656949
  var valid_402656950 = header.getOrDefault("X-Amz-Credential")
  valid_402656950 = validateParameter(valid_402656950, JString,
                                      required = false, default = nil)
  if valid_402656950 != nil:
    section.add "X-Amz-Credential", valid_402656950
  var valid_402656951 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656951 = validateParameter(valid_402656951, JString,
                                      required = false, default = nil)
  if valid_402656951 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656951
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656953: Call_PutConfigurationSetSendingOptions_402656941;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Enable or disable email sending for messages that use a particular configuration set in a specific AWS Region.
                                                                                         ## 
  let valid = call_402656953.validator(path, query, header, formData, body, _)
  let scheme = call_402656953.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656953.makeUrl(scheme.get, call_402656953.host, call_402656953.base,
                                   call_402656953.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656953, uri, valid, _)

proc call*(call_402656954: Call_PutConfigurationSetSendingOptions_402656941;
           ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetSendingOptions
  ## Enable or disable email sending for messages that use a particular configuration set in a specific AWS Region.
  ##   
                                                                                                                   ## ConfigurationSetName: string (required)
                                                                                                                   ##                       
                                                                                                                   ## : 
                                                                                                                   ## <p>The 
                                                                                                                   ## name 
                                                                                                                   ## of 
                                                                                                                   ## a 
                                                                                                                   ## configuration 
                                                                                                                   ## set.</p> 
                                                                                                                   ## <p>In 
                                                                                                                   ## Amazon 
                                                                                                                   ## Pinpoint, 
                                                                                                                   ## <i>configuration 
                                                                                                                   ## sets</i> 
                                                                                                                   ## are 
                                                                                                                   ## groups 
                                                                                                                   ## of 
                                                                                                                   ## rules 
                                                                                                                   ## that 
                                                                                                                   ## you 
                                                                                                                   ## can 
                                                                                                                   ## apply 
                                                                                                                   ## to 
                                                                                                                   ## the 
                                                                                                                   ## emails 
                                                                                                                   ## you 
                                                                                                                   ## send. 
                                                                                                                   ## You 
                                                                                                                   ## apply 
                                                                                                                   ## a 
                                                                                                                   ## configuration 
                                                                                                                   ## set 
                                                                                                                   ## to 
                                                                                                                   ## an 
                                                                                                                   ## email 
                                                                                                                   ## by 
                                                                                                                   ## including 
                                                                                                                   ## a 
                                                                                                                   ## reference 
                                                                                                                   ## to 
                                                                                                                   ## the 
                                                                                                                   ## configuration 
                                                                                                                   ## set 
                                                                                                                   ## in 
                                                                                                                   ## the 
                                                                                                                   ## headers 
                                                                                                                   ## of 
                                                                                                                   ## the 
                                                                                                                   ## email. 
                                                                                                                   ## When 
                                                                                                                   ## you 
                                                                                                                   ## apply 
                                                                                                                   ## a 
                                                                                                                   ## configuration 
                                                                                                                   ## set 
                                                                                                                   ## to 
                                                                                                                   ## an 
                                                                                                                   ## email, 
                                                                                                                   ## all 
                                                                                                                   ## of 
                                                                                                                   ## the 
                                                                                                                   ## rules 
                                                                                                                   ## in 
                                                                                                                   ## that 
                                                                                                                   ## configuration 
                                                                                                                   ## set 
                                                                                                                   ## are 
                                                                                                                   ## applied 
                                                                                                                   ## to 
                                                                                                                   ## the 
                                                                                                                   ## email.</p>
  ##   
                                                                                                                                ## body: JObject (required)
  var path_402656955 = newJObject()
  var body_402656956 = newJObject()
  add(path_402656955, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_402656956 = body
  result = call_402656954.call(path_402656955, nil, nil, nil, body_402656956)

var putConfigurationSetSendingOptions* = Call_PutConfigurationSetSendingOptions_402656941(
    name: "putConfigurationSetSendingOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v1/email/configuration-sets/{ConfigurationSetName}/sending",
    validator: validate_PutConfigurationSetSendingOptions_402656942, base: "/",
    makeUrl: url_PutConfigurationSetSendingOptions_402656943,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetTrackingOptions_402656957 = ref object of OpenApiRestCall_402656044
proc url_PutConfigurationSetTrackingOptions_402656959(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
         "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/configuration-sets/"),
                 (kind: VariableSegment, value: "ConfigurationSetName"),
                 (kind: ConstantSegment, value: "/tracking-options")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutConfigurationSetTrackingOptions_402656958(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Specify a custom domain to use for open and click tracking elements in email that you send using Amazon Pinpoint.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
                                 ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_402656960 = path.getOrDefault("ConfigurationSetName")
  valid_402656960 = validateParameter(valid_402656960, JString, required = true,
                                      default = nil)
  if valid_402656960 != nil:
    section.add "ConfigurationSetName", valid_402656960
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656961 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656961 = validateParameter(valid_402656961, JString,
                                      required = false, default = nil)
  if valid_402656961 != nil:
    section.add "X-Amz-Security-Token", valid_402656961
  var valid_402656962 = header.getOrDefault("X-Amz-Signature")
  valid_402656962 = validateParameter(valid_402656962, JString,
                                      required = false, default = nil)
  if valid_402656962 != nil:
    section.add "X-Amz-Signature", valid_402656962
  var valid_402656963 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656963 = validateParameter(valid_402656963, JString,
                                      required = false, default = nil)
  if valid_402656963 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656963
  var valid_402656964 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656964 = validateParameter(valid_402656964, JString,
                                      required = false, default = nil)
  if valid_402656964 != nil:
    section.add "X-Amz-Algorithm", valid_402656964
  var valid_402656965 = header.getOrDefault("X-Amz-Date")
  valid_402656965 = validateParameter(valid_402656965, JString,
                                      required = false, default = nil)
  if valid_402656965 != nil:
    section.add "X-Amz-Date", valid_402656965
  var valid_402656966 = header.getOrDefault("X-Amz-Credential")
  valid_402656966 = validateParameter(valid_402656966, JString,
                                      required = false, default = nil)
  if valid_402656966 != nil:
    section.add "X-Amz-Credential", valid_402656966
  var valid_402656967 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656967 = validateParameter(valid_402656967, JString,
                                      required = false, default = nil)
  if valid_402656967 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656967
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656969: Call_PutConfigurationSetTrackingOptions_402656957;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Specify a custom domain to use for open and click tracking elements in email that you send using Amazon Pinpoint.
                                                                                         ## 
  let valid = call_402656969.validator(path, query, header, formData, body, _)
  let scheme = call_402656969.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656969.makeUrl(scheme.get, call_402656969.host, call_402656969.base,
                                   call_402656969.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656969, uri, valid, _)

proc call*(call_402656970: Call_PutConfigurationSetTrackingOptions_402656957;
           ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetTrackingOptions
  ## Specify a custom domain to use for open and click tracking elements in email that you send using Amazon Pinpoint.
  ##   
                                                                                                                      ## ConfigurationSetName: string (required)
                                                                                                                      ##                       
                                                                                                                      ## : 
                                                                                                                      ## <p>The 
                                                                                                                      ## name 
                                                                                                                      ## of 
                                                                                                                      ## a 
                                                                                                                      ## configuration 
                                                                                                                      ## set.</p> 
                                                                                                                      ## <p>In 
                                                                                                                      ## Amazon 
                                                                                                                      ## Pinpoint, 
                                                                                                                      ## <i>configuration 
                                                                                                                      ## sets</i> 
                                                                                                                      ## are 
                                                                                                                      ## groups 
                                                                                                                      ## of 
                                                                                                                      ## rules 
                                                                                                                      ## that 
                                                                                                                      ## you 
                                                                                                                      ## can 
                                                                                                                      ## apply 
                                                                                                                      ## to 
                                                                                                                      ## the 
                                                                                                                      ## emails 
                                                                                                                      ## you 
                                                                                                                      ## send. 
                                                                                                                      ## You 
                                                                                                                      ## apply 
                                                                                                                      ## a 
                                                                                                                      ## configuration 
                                                                                                                      ## set 
                                                                                                                      ## to 
                                                                                                                      ## an 
                                                                                                                      ## email 
                                                                                                                      ## by 
                                                                                                                      ## including 
                                                                                                                      ## a 
                                                                                                                      ## reference 
                                                                                                                      ## to 
                                                                                                                      ## the 
                                                                                                                      ## configuration 
                                                                                                                      ## set 
                                                                                                                      ## in 
                                                                                                                      ## the 
                                                                                                                      ## headers 
                                                                                                                      ## of 
                                                                                                                      ## the 
                                                                                                                      ## email. 
                                                                                                                      ## When 
                                                                                                                      ## you 
                                                                                                                      ## apply 
                                                                                                                      ## a 
                                                                                                                      ## configuration 
                                                                                                                      ## set 
                                                                                                                      ## to 
                                                                                                                      ## an 
                                                                                                                      ## email, 
                                                                                                                      ## all 
                                                                                                                      ## of 
                                                                                                                      ## the 
                                                                                                                      ## rules 
                                                                                                                      ## in 
                                                                                                                      ## that 
                                                                                                                      ## configuration 
                                                                                                                      ## set 
                                                                                                                      ## are 
                                                                                                                      ## applied 
                                                                                                                      ## to 
                                                                                                                      ## the 
                                                                                                                      ## email.</p>
  ##   
                                                                                                                                   ## body: JObject (required)
  var path_402656971 = newJObject()
  var body_402656972 = newJObject()
  add(path_402656971, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_402656972 = body
  result = call_402656970.call(path_402656971, nil, nil, nil, body_402656972)

var putConfigurationSetTrackingOptions* = Call_PutConfigurationSetTrackingOptions_402656957(
    name: "putConfigurationSetTrackingOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/tracking-options",
    validator: validate_PutConfigurationSetTrackingOptions_402656958, base: "/",
    makeUrl: url_PutConfigurationSetTrackingOptions_402656959,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDedicatedIpInPool_402656973 = ref object of OpenApiRestCall_402656044
proc url_PutDedicatedIpInPool_402656975(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IP" in path, "`IP` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/dedicated-ips/"),
                 (kind: VariableSegment, value: "IP"),
                 (kind: ConstantSegment, value: "/pool")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutDedicatedIpInPool_402656974(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Move a dedicated IP address to an existing dedicated IP pool.</p> <note> <p>The dedicated IP address that you specify must already exist, and must be associated with your Amazon Pinpoint account. </p> <p>The dedicated IP pool you specify must already exist. You can create a new pool by using the <code>CreateDedicatedIpPool</code> operation.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IP: JString (required)
                                 ##     : A dedicated IP address that is associated with your Amazon Pinpoint account.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `IP` field"
  var valid_402656976 = path.getOrDefault("IP")
  valid_402656976 = validateParameter(valid_402656976, JString, required = true,
                                      default = nil)
  if valid_402656976 != nil:
    section.add "IP", valid_402656976
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656977 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656977 = validateParameter(valid_402656977, JString,
                                      required = false, default = nil)
  if valid_402656977 != nil:
    section.add "X-Amz-Security-Token", valid_402656977
  var valid_402656978 = header.getOrDefault("X-Amz-Signature")
  valid_402656978 = validateParameter(valid_402656978, JString,
                                      required = false, default = nil)
  if valid_402656978 != nil:
    section.add "X-Amz-Signature", valid_402656978
  var valid_402656979 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656979 = validateParameter(valid_402656979, JString,
                                      required = false, default = nil)
  if valid_402656979 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656979
  var valid_402656980 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656980 = validateParameter(valid_402656980, JString,
                                      required = false, default = nil)
  if valid_402656980 != nil:
    section.add "X-Amz-Algorithm", valid_402656980
  var valid_402656981 = header.getOrDefault("X-Amz-Date")
  valid_402656981 = validateParameter(valid_402656981, JString,
                                      required = false, default = nil)
  if valid_402656981 != nil:
    section.add "X-Amz-Date", valid_402656981
  var valid_402656982 = header.getOrDefault("X-Amz-Credential")
  valid_402656982 = validateParameter(valid_402656982, JString,
                                      required = false, default = nil)
  if valid_402656982 != nil:
    section.add "X-Amz-Credential", valid_402656982
  var valid_402656983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656983 = validateParameter(valid_402656983, JString,
                                      required = false, default = nil)
  if valid_402656983 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656983
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656985: Call_PutDedicatedIpInPool_402656973;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Move a dedicated IP address to an existing dedicated IP pool.</p> <note> <p>The dedicated IP address that you specify must already exist, and must be associated with your Amazon Pinpoint account. </p> <p>The dedicated IP pool you specify must already exist. You can create a new pool by using the <code>CreateDedicatedIpPool</code> operation.</p> </note>
                                                                                         ## 
  let valid = call_402656985.validator(path, query, header, formData, body, _)
  let scheme = call_402656985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656985.makeUrl(scheme.get, call_402656985.host, call_402656985.base,
                                   call_402656985.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656985, uri, valid, _)

proc call*(call_402656986: Call_PutDedicatedIpInPool_402656973; body: JsonNode;
           IP: string): Recallable =
  ## putDedicatedIpInPool
  ## <p>Move a dedicated IP address to an existing dedicated IP pool.</p> <note> <p>The dedicated IP address that you specify must already exist, and must be associated with your Amazon Pinpoint account. </p> <p>The dedicated IP pool you specify must already exist. You can create a new pool by using the <code>CreateDedicatedIpPool</code> operation.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                     ## IP: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                     ##     
                                                                                                                                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                                                                                                                                     ## A 
                                                                                                                                                                                                                                                                                                                                                                                                     ## dedicated 
                                                                                                                                                                                                                                                                                                                                                                                                     ## IP 
                                                                                                                                                                                                                                                                                                                                                                                                     ## address 
                                                                                                                                                                                                                                                                                                                                                                                                     ## that 
                                                                                                                                                                                                                                                                                                                                                                                                     ## is 
                                                                                                                                                                                                                                                                                                                                                                                                     ## associated 
                                                                                                                                                                                                                                                                                                                                                                                                     ## with 
                                                                                                                                                                                                                                                                                                                                                                                                     ## your 
                                                                                                                                                                                                                                                                                                                                                                                                     ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                     ## Pinpoint 
                                                                                                                                                                                                                                                                                                                                                                                                     ## account.
  var path_402656987 = newJObject()
  var body_402656988 = newJObject()
  if body != nil:
    body_402656988 = body
  add(path_402656987, "IP", newJString(IP))
  result = call_402656986.call(path_402656987, nil, nil, nil, body_402656988)

var putDedicatedIpInPool* = Call_PutDedicatedIpInPool_402656973(
    name: "putDedicatedIpInPool", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/dedicated-ips/{IP}/pool",
    validator: validate_PutDedicatedIpInPool_402656974, base: "/",
    makeUrl: url_PutDedicatedIpInPool_402656975,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDedicatedIpWarmupAttributes_402656989 = ref object of OpenApiRestCall_402656044
proc url_PutDedicatedIpWarmupAttributes_402656991(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IP" in path, "`IP` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/dedicated-ips/"),
                 (kind: VariableSegment, value: "IP"),
                 (kind: ConstantSegment, value: "/warmup")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutDedicatedIpWarmupAttributes_402656990(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p/>
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IP: JString (required)
                                 ##     : A dedicated IP address that is associated with your Amazon Pinpoint account.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `IP` field"
  var valid_402656992 = path.getOrDefault("IP")
  valid_402656992 = validateParameter(valid_402656992, JString, required = true,
                                      default = nil)
  if valid_402656992 != nil:
    section.add "IP", valid_402656992
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656993 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656993 = validateParameter(valid_402656993, JString,
                                      required = false, default = nil)
  if valid_402656993 != nil:
    section.add "X-Amz-Security-Token", valid_402656993
  var valid_402656994 = header.getOrDefault("X-Amz-Signature")
  valid_402656994 = validateParameter(valid_402656994, JString,
                                      required = false, default = nil)
  if valid_402656994 != nil:
    section.add "X-Amz-Signature", valid_402656994
  var valid_402656995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656995 = validateParameter(valid_402656995, JString,
                                      required = false, default = nil)
  if valid_402656995 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656995
  var valid_402656996 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656996 = validateParameter(valid_402656996, JString,
                                      required = false, default = nil)
  if valid_402656996 != nil:
    section.add "X-Amz-Algorithm", valid_402656996
  var valid_402656997 = header.getOrDefault("X-Amz-Date")
  valid_402656997 = validateParameter(valid_402656997, JString,
                                      required = false, default = nil)
  if valid_402656997 != nil:
    section.add "X-Amz-Date", valid_402656997
  var valid_402656998 = header.getOrDefault("X-Amz-Credential")
  valid_402656998 = validateParameter(valid_402656998, JString,
                                      required = false, default = nil)
  if valid_402656998 != nil:
    section.add "X-Amz-Credential", valid_402656998
  var valid_402656999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656999 = validateParameter(valid_402656999, JString,
                                      required = false, default = nil)
  if valid_402656999 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657001: Call_PutDedicatedIpWarmupAttributes_402656989;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p/>
                                                                                         ## 
  let valid = call_402657001.validator(path, query, header, formData, body, _)
  let scheme = call_402657001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657001.makeUrl(scheme.get, call_402657001.host, call_402657001.base,
                                   call_402657001.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657001, uri, valid, _)

proc call*(call_402657002: Call_PutDedicatedIpWarmupAttributes_402656989;
           body: JsonNode; IP: string): Recallable =
  ## putDedicatedIpWarmupAttributes
  ## <p/>
  ##   body: JObject (required)
  ##   IP: string (required)
                               ##     : A dedicated IP address that is associated with your Amazon Pinpoint account.
  var path_402657003 = newJObject()
  var body_402657004 = newJObject()
  if body != nil:
    body_402657004 = body
  add(path_402657003, "IP", newJString(IP))
  result = call_402657002.call(path_402657003, nil, nil, nil, body_402657004)

var putDedicatedIpWarmupAttributes* = Call_PutDedicatedIpWarmupAttributes_402656989(
    name: "putDedicatedIpWarmupAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/dedicated-ips/{IP}/warmup",
    validator: validate_PutDedicatedIpWarmupAttributes_402656990, base: "/",
    makeUrl: url_PutDedicatedIpWarmupAttributes_402656991,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEmailIdentityDkimAttributes_402657005 = ref object of OpenApiRestCall_402656044
proc url_PutEmailIdentityDkimAttributes_402657007(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "EmailIdentity" in path, "`EmailIdentity` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/identities/"),
                 (kind: VariableSegment, value: "EmailIdentity"),
                 (kind: ConstantSegment, value: "/dkim")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutEmailIdentityDkimAttributes_402657006(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Used to enable or disable DKIM authentication for an email identity.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EmailIdentity: JString (required)
                                 ##                : The email identity that you want to change the DKIM settings for.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `EmailIdentity` field"
  var valid_402657008 = path.getOrDefault("EmailIdentity")
  valid_402657008 = validateParameter(valid_402657008, JString, required = true,
                                      default = nil)
  if valid_402657008 != nil:
    section.add "EmailIdentity", valid_402657008
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657009 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657009 = validateParameter(valid_402657009, JString,
                                      required = false, default = nil)
  if valid_402657009 != nil:
    section.add "X-Amz-Security-Token", valid_402657009
  var valid_402657010 = header.getOrDefault("X-Amz-Signature")
  valid_402657010 = validateParameter(valid_402657010, JString,
                                      required = false, default = nil)
  if valid_402657010 != nil:
    section.add "X-Amz-Signature", valid_402657010
  var valid_402657011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657011 = validateParameter(valid_402657011, JString,
                                      required = false, default = nil)
  if valid_402657011 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657011
  var valid_402657012 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657012 = validateParameter(valid_402657012, JString,
                                      required = false, default = nil)
  if valid_402657012 != nil:
    section.add "X-Amz-Algorithm", valid_402657012
  var valid_402657013 = header.getOrDefault("X-Amz-Date")
  valid_402657013 = validateParameter(valid_402657013, JString,
                                      required = false, default = nil)
  if valid_402657013 != nil:
    section.add "X-Amz-Date", valid_402657013
  var valid_402657014 = header.getOrDefault("X-Amz-Credential")
  valid_402657014 = validateParameter(valid_402657014, JString,
                                      required = false, default = nil)
  if valid_402657014 != nil:
    section.add "X-Amz-Credential", valid_402657014
  var valid_402657015 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657015 = validateParameter(valid_402657015, JString,
                                      required = false, default = nil)
  if valid_402657015 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657015
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657017: Call_PutEmailIdentityDkimAttributes_402657005;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Used to enable or disable DKIM authentication for an email identity.
                                                                                         ## 
  let valid = call_402657017.validator(path, query, header, formData, body, _)
  let scheme = call_402657017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657017.makeUrl(scheme.get, call_402657017.host, call_402657017.base,
                                   call_402657017.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657017, uri, valid, _)

proc call*(call_402657018: Call_PutEmailIdentityDkimAttributes_402657005;
           body: JsonNode; EmailIdentity: string): Recallable =
  ## putEmailIdentityDkimAttributes
  ## Used to enable or disable DKIM authentication for an email identity.
  ##   body: JObject 
                                                                         ## (required)
  ##   
                                                                                      ## EmailIdentity: string (required)
                                                                                      ##                
                                                                                      ## : 
                                                                                      ## The 
                                                                                      ## email 
                                                                                      ## identity 
                                                                                      ## that 
                                                                                      ## you 
                                                                                      ## want 
                                                                                      ## to 
                                                                                      ## change 
                                                                                      ## the 
                                                                                      ## DKIM 
                                                                                      ## settings 
                                                                                      ## for.
  var path_402657019 = newJObject()
  var body_402657020 = newJObject()
  if body != nil:
    body_402657020 = body
  add(path_402657019, "EmailIdentity", newJString(EmailIdentity))
  result = call_402657018.call(path_402657019, nil, nil, nil, body_402657020)

var putEmailIdentityDkimAttributes* = Call_PutEmailIdentityDkimAttributes_402657005(
    name: "putEmailIdentityDkimAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v1/email/identities/{EmailIdentity}/dkim",
    validator: validate_PutEmailIdentityDkimAttributes_402657006, base: "/",
    makeUrl: url_PutEmailIdentityDkimAttributes_402657007,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEmailIdentityFeedbackAttributes_402657021 = ref object of OpenApiRestCall_402656044
proc url_PutEmailIdentityFeedbackAttributes_402657023(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "EmailIdentity" in path, "`EmailIdentity` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/identities/"),
                 (kind: VariableSegment, value: "EmailIdentity"),
                 (kind: ConstantSegment, value: "/feedback")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutEmailIdentityFeedbackAttributes_402657022(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Used to enable or disable feedback forwarding for an identity. This setting determines what happens when an identity is used to send an email that results in a bounce or complaint event.</p> <p>When you enable feedback forwarding, Amazon Pinpoint sends you email notifications when bounce or complaint events occur. Amazon Pinpoint sends this notification to the address that you specified in the Return-Path header of the original email.</p> <p>When you disable feedback forwarding, Amazon Pinpoint sends notifications through other mechanisms, such as by notifying an Amazon SNS topic. You're required to have a method of tracking bounces and complaints. If you haven't set up another mechanism for receiving bounce or complaint notifications, Amazon Pinpoint sends an email notification when these events occur (even if this setting is disabled).</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EmailIdentity: JString (required)
                                 ##                : The email identity that you want to configure bounce and complaint feedback forwarding for.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `EmailIdentity` field"
  var valid_402657024 = path.getOrDefault("EmailIdentity")
  valid_402657024 = validateParameter(valid_402657024, JString, required = true,
                                      default = nil)
  if valid_402657024 != nil:
    section.add "EmailIdentity", valid_402657024
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657025 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657025 = validateParameter(valid_402657025, JString,
                                      required = false, default = nil)
  if valid_402657025 != nil:
    section.add "X-Amz-Security-Token", valid_402657025
  var valid_402657026 = header.getOrDefault("X-Amz-Signature")
  valid_402657026 = validateParameter(valid_402657026, JString,
                                      required = false, default = nil)
  if valid_402657026 != nil:
    section.add "X-Amz-Signature", valid_402657026
  var valid_402657027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657027 = validateParameter(valid_402657027, JString,
                                      required = false, default = nil)
  if valid_402657027 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657027
  var valid_402657028 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657028 = validateParameter(valid_402657028, JString,
                                      required = false, default = nil)
  if valid_402657028 != nil:
    section.add "X-Amz-Algorithm", valid_402657028
  var valid_402657029 = header.getOrDefault("X-Amz-Date")
  valid_402657029 = validateParameter(valid_402657029, JString,
                                      required = false, default = nil)
  if valid_402657029 != nil:
    section.add "X-Amz-Date", valid_402657029
  var valid_402657030 = header.getOrDefault("X-Amz-Credential")
  valid_402657030 = validateParameter(valid_402657030, JString,
                                      required = false, default = nil)
  if valid_402657030 != nil:
    section.add "X-Amz-Credential", valid_402657030
  var valid_402657031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657031 = validateParameter(valid_402657031, JString,
                                      required = false, default = nil)
  if valid_402657031 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657033: Call_PutEmailIdentityFeedbackAttributes_402657021;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Used to enable or disable feedback forwarding for an identity. This setting determines what happens when an identity is used to send an email that results in a bounce or complaint event.</p> <p>When you enable feedback forwarding, Amazon Pinpoint sends you email notifications when bounce or complaint events occur. Amazon Pinpoint sends this notification to the address that you specified in the Return-Path header of the original email.</p> <p>When you disable feedback forwarding, Amazon Pinpoint sends notifications through other mechanisms, such as by notifying an Amazon SNS topic. You're required to have a method of tracking bounces and complaints. If you haven't set up another mechanism for receiving bounce or complaint notifications, Amazon Pinpoint sends an email notification when these events occur (even if this setting is disabled).</p>
                                                                                         ## 
  let valid = call_402657033.validator(path, query, header, formData, body, _)
  let scheme = call_402657033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657033.makeUrl(scheme.get, call_402657033.host, call_402657033.base,
                                   call_402657033.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657033, uri, valid, _)

proc call*(call_402657034: Call_PutEmailIdentityFeedbackAttributes_402657021;
           body: JsonNode; EmailIdentity: string): Recallable =
  ## putEmailIdentityFeedbackAttributes
  ## <p>Used to enable or disable feedback forwarding for an identity. This setting determines what happens when an identity is used to send an email that results in a bounce or complaint event.</p> <p>When you enable feedback forwarding, Amazon Pinpoint sends you email notifications when bounce or complaint events occur. Amazon Pinpoint sends this notification to the address that you specified in the Return-Path header of the original email.</p> <p>When you disable feedback forwarding, Amazon Pinpoint sends notifications through other mechanisms, such as by notifying an Amazon SNS topic. You're required to have a method of tracking bounces and complaints. If you haven't set up another mechanism for receiving bounce or complaint notifications, Amazon Pinpoint sends an email notification when these events occur (even if this setting is disabled).</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## EmailIdentity: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ##                
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## email 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## identity 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## configure 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## bounce 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## complaint 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## feedback 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## forwarding 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## for.
  var path_402657035 = newJObject()
  var body_402657036 = newJObject()
  if body != nil:
    body_402657036 = body
  add(path_402657035, "EmailIdentity", newJString(EmailIdentity))
  result = call_402657034.call(path_402657035, nil, nil, nil, body_402657036)

var putEmailIdentityFeedbackAttributes* = Call_PutEmailIdentityFeedbackAttributes_402657021(
    name: "putEmailIdentityFeedbackAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v1/email/identities/{EmailIdentity}/feedback",
    validator: validate_PutEmailIdentityFeedbackAttributes_402657022, base: "/",
    makeUrl: url_PutEmailIdentityFeedbackAttributes_402657023,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEmailIdentityMailFromAttributes_402657037 = ref object of OpenApiRestCall_402656044
proc url_PutEmailIdentityMailFromAttributes_402657039(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "EmailIdentity" in path, "`EmailIdentity` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/identities/"),
                 (kind: VariableSegment, value: "EmailIdentity"),
                 (kind: ConstantSegment, value: "/mail-from")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutEmailIdentityMailFromAttributes_402657038(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Used to enable or disable the custom Mail-From domain configuration for an email identity.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EmailIdentity: JString (required)
                                 ##                : The verified email identity that you want to set up the custom MAIL FROM domain for.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `EmailIdentity` field"
  var valid_402657040 = path.getOrDefault("EmailIdentity")
  valid_402657040 = validateParameter(valid_402657040, JString, required = true,
                                      default = nil)
  if valid_402657040 != nil:
    section.add "EmailIdentity", valid_402657040
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657041 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657041 = validateParameter(valid_402657041, JString,
                                      required = false, default = nil)
  if valid_402657041 != nil:
    section.add "X-Amz-Security-Token", valid_402657041
  var valid_402657042 = header.getOrDefault("X-Amz-Signature")
  valid_402657042 = validateParameter(valid_402657042, JString,
                                      required = false, default = nil)
  if valid_402657042 != nil:
    section.add "X-Amz-Signature", valid_402657042
  var valid_402657043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657043 = validateParameter(valid_402657043, JString,
                                      required = false, default = nil)
  if valid_402657043 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657043
  var valid_402657044 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657044 = validateParameter(valid_402657044, JString,
                                      required = false, default = nil)
  if valid_402657044 != nil:
    section.add "X-Amz-Algorithm", valid_402657044
  var valid_402657045 = header.getOrDefault("X-Amz-Date")
  valid_402657045 = validateParameter(valid_402657045, JString,
                                      required = false, default = nil)
  if valid_402657045 != nil:
    section.add "X-Amz-Date", valid_402657045
  var valid_402657046 = header.getOrDefault("X-Amz-Credential")
  valid_402657046 = validateParameter(valid_402657046, JString,
                                      required = false, default = nil)
  if valid_402657046 != nil:
    section.add "X-Amz-Credential", valid_402657046
  var valid_402657047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657047 = validateParameter(valid_402657047, JString,
                                      required = false, default = nil)
  if valid_402657047 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657049: Call_PutEmailIdentityMailFromAttributes_402657037;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Used to enable or disable the custom Mail-From domain configuration for an email identity.
                                                                                         ## 
  let valid = call_402657049.validator(path, query, header, formData, body, _)
  let scheme = call_402657049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657049.makeUrl(scheme.get, call_402657049.host, call_402657049.base,
                                   call_402657049.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657049, uri, valid, _)

proc call*(call_402657050: Call_PutEmailIdentityMailFromAttributes_402657037;
           body: JsonNode; EmailIdentity: string): Recallable =
  ## putEmailIdentityMailFromAttributes
  ## Used to enable or disable the custom Mail-From domain configuration for an email identity.
  ##   
                                                                                               ## body: JObject (required)
  ##   
                                                                                                                          ## EmailIdentity: string (required)
                                                                                                                          ##                
                                                                                                                          ## : 
                                                                                                                          ## The 
                                                                                                                          ## verified 
                                                                                                                          ## email 
                                                                                                                          ## identity 
                                                                                                                          ## that 
                                                                                                                          ## you 
                                                                                                                          ## want 
                                                                                                                          ## to 
                                                                                                                          ## set 
                                                                                                                          ## up 
                                                                                                                          ## the 
                                                                                                                          ## custom 
                                                                                                                          ## MAIL 
                                                                                                                          ## FROM 
                                                                                                                          ## domain 
                                                                                                                          ## for.
  var path_402657051 = newJObject()
  var body_402657052 = newJObject()
  if body != nil:
    body_402657052 = body
  add(path_402657051, "EmailIdentity", newJString(EmailIdentity))
  result = call_402657050.call(path_402657051, nil, nil, nil, body_402657052)

var putEmailIdentityMailFromAttributes* = Call_PutEmailIdentityMailFromAttributes_402657037(
    name: "putEmailIdentityMailFromAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v1/email/identities/{EmailIdentity}/mail-from",
    validator: validate_PutEmailIdentityMailFromAttributes_402657038, base: "/",
    makeUrl: url_PutEmailIdentityMailFromAttributes_402657039,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendEmail_402657053 = ref object of OpenApiRestCall_402656044
proc url_SendEmail_402657055(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendEmail_402657054(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Sends an email message. You can use the Amazon Pinpoint Email API to send two types of messages:</p> <ul> <li> <p> <b>Simple</b> – A standard email message. When you create this type of message, you specify the sender, the recipient, and the message body, and Amazon Pinpoint assembles the message for you.</p> </li> <li> <p> <b>Raw</b> – A raw, MIME-formatted email message. When you send this type of email, you have to specify all of the message headers, as well as the message body. You can use this message type to send messages that contain attachments. The message that you specify has to be a valid MIME message.</p> </li> </ul>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657056 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657056 = validateParameter(valid_402657056, JString,
                                      required = false, default = nil)
  if valid_402657056 != nil:
    section.add "X-Amz-Security-Token", valid_402657056
  var valid_402657057 = header.getOrDefault("X-Amz-Signature")
  valid_402657057 = validateParameter(valid_402657057, JString,
                                      required = false, default = nil)
  if valid_402657057 != nil:
    section.add "X-Amz-Signature", valid_402657057
  var valid_402657058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657058 = validateParameter(valid_402657058, JString,
                                      required = false, default = nil)
  if valid_402657058 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657058
  var valid_402657059 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657059 = validateParameter(valid_402657059, JString,
                                      required = false, default = nil)
  if valid_402657059 != nil:
    section.add "X-Amz-Algorithm", valid_402657059
  var valid_402657060 = header.getOrDefault("X-Amz-Date")
  valid_402657060 = validateParameter(valid_402657060, JString,
                                      required = false, default = nil)
  if valid_402657060 != nil:
    section.add "X-Amz-Date", valid_402657060
  var valid_402657061 = header.getOrDefault("X-Amz-Credential")
  valid_402657061 = validateParameter(valid_402657061, JString,
                                      required = false, default = nil)
  if valid_402657061 != nil:
    section.add "X-Amz-Credential", valid_402657061
  var valid_402657062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657062 = validateParameter(valid_402657062, JString,
                                      required = false, default = nil)
  if valid_402657062 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657064: Call_SendEmail_402657053; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sends an email message. You can use the Amazon Pinpoint Email API to send two types of messages:</p> <ul> <li> <p> <b>Simple</b> – A standard email message. When you create this type of message, you specify the sender, the recipient, and the message body, and Amazon Pinpoint assembles the message for you.</p> </li> <li> <p> <b>Raw</b> – A raw, MIME-formatted email message. When you send this type of email, you have to specify all of the message headers, as well as the message body. You can use this message type to send messages that contain attachments. The message that you specify has to be a valid MIME message.</p> </li> </ul>
                                                                                         ## 
  let valid = call_402657064.validator(path, query, header, formData, body, _)
  let scheme = call_402657064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657064.makeUrl(scheme.get, call_402657064.host, call_402657064.base,
                                   call_402657064.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657064, uri, valid, _)

proc call*(call_402657065: Call_SendEmail_402657053; body: JsonNode): Recallable =
  ## sendEmail
  ## <p>Sends an email message. You can use the Amazon Pinpoint Email API to send two types of messages:</p> <ul> <li> <p> <b>Simple</b> – A standard email message. When you create this type of message, you specify the sender, the recipient, and the message body, and Amazon Pinpoint assembles the message for you.</p> </li> <li> <p> <b>Raw</b> – A raw, MIME-formatted email message. When you send this type of email, you have to specify all of the message headers, as well as the message body. You can use this message type to send messages that contain attachments. The message that you specify has to be a valid MIME message.</p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402657066 = newJObject()
  if body != nil:
    body_402657066 = body
  result = call_402657065.call(nil, nil, nil, nil, body_402657066)

var sendEmail* = Call_SendEmail_402657053(name: "sendEmail",
    meth: HttpMethod.HttpPost, host: "email.amazonaws.com",
    route: "/v1/email/outbound-emails", validator: validate_SendEmail_402657054,
    base: "/", makeUrl: url_SendEmail_402657055,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402657067 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402657069(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_402657068(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Add one or more tags (keys and values) to a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource in Amazon Pinpoint. Tags can help you categorize and manage resources in different ways, such as by purpose, owner, environment, or other criteria. A resource can have as many as 50 tags.</p> <p>Each tag consists of a required <i>tag key</i> and an associated <i>tag value</i>, both of which you define. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657070 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657070 = validateParameter(valid_402657070, JString,
                                      required = false, default = nil)
  if valid_402657070 != nil:
    section.add "X-Amz-Security-Token", valid_402657070
  var valid_402657071 = header.getOrDefault("X-Amz-Signature")
  valid_402657071 = validateParameter(valid_402657071, JString,
                                      required = false, default = nil)
  if valid_402657071 != nil:
    section.add "X-Amz-Signature", valid_402657071
  var valid_402657072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657072 = validateParameter(valid_402657072, JString,
                                      required = false, default = nil)
  if valid_402657072 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657072
  var valid_402657073 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657073 = validateParameter(valid_402657073, JString,
                                      required = false, default = nil)
  if valid_402657073 != nil:
    section.add "X-Amz-Algorithm", valid_402657073
  var valid_402657074 = header.getOrDefault("X-Amz-Date")
  valid_402657074 = validateParameter(valid_402657074, JString,
                                      required = false, default = nil)
  if valid_402657074 != nil:
    section.add "X-Amz-Date", valid_402657074
  var valid_402657075 = header.getOrDefault("X-Amz-Credential")
  valid_402657075 = validateParameter(valid_402657075, JString,
                                      required = false, default = nil)
  if valid_402657075 != nil:
    section.add "X-Amz-Credential", valid_402657075
  var valid_402657076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657076 = validateParameter(valid_402657076, JString,
                                      required = false, default = nil)
  if valid_402657076 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657078: Call_TagResource_402657067; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Add one or more tags (keys and values) to a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource in Amazon Pinpoint. Tags can help you categorize and manage resources in different ways, such as by purpose, owner, environment, or other criteria. A resource can have as many as 50 tags.</p> <p>Each tag consists of a required <i>tag key</i> and an associated <i>tag value</i>, both of which you define. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.</p>
                                                                                         ## 
  let valid = call_402657078.validator(path, query, header, formData, body, _)
  let scheme = call_402657078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657078.makeUrl(scheme.get, call_402657078.host, call_402657078.base,
                                   call_402657078.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657078, uri, valid, _)

proc call*(call_402657079: Call_TagResource_402657067; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Add one or more tags (keys and values) to a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource in Amazon Pinpoint. Tags can help you categorize and manage resources in different ways, such as by purpose, owner, environment, or other criteria. A resource can have as many as 50 tags.</p> <p>Each tag consists of a required <i>tag key</i> and an associated <i>tag value</i>, both of which you define. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402657080 = newJObject()
  if body != nil:
    body_402657080 = body
  result = call_402657079.call(nil, nil, nil, nil, body_402657080)

var tagResource* = Call_TagResource_402657067(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "email.amazonaws.com",
    route: "/v1/email/tags", validator: validate_TagResource_402657068,
    base: "/", makeUrl: url_TagResource_402657069,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402657081 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402657083(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_402657082(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Remove one or more tags (keys and values) from a specified resource.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   TagKeys: JArray (required)
                                  ##          : <p>The tags (tag keys) that you want to remove from the resource. When you specify a tag key, the action removes both that key and its associated tag value.</p> <p>To remove more than one tag from the resource, append the <code>TagKeys</code> parameter and argument for each additional tag to remove, separated by an ampersand. For example: 
                                  ## <code>/v1/email/tags?ResourceArn=ResourceArn&amp;TagKeys=Key1&amp;TagKeys=Key2</code> 
                                  ## </p>
  ##   ResourceArn: JString (required)
                                         ##              : The Amazon Resource Name (ARN) of the resource that you want to remove one or more tags from.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `TagKeys` field"
  var valid_402657084 = query.getOrDefault("TagKeys")
  valid_402657084 = validateParameter(valid_402657084, JArray, required = true,
                                      default = nil)
  if valid_402657084 != nil:
    section.add "TagKeys", valid_402657084
  var valid_402657085 = query.getOrDefault("ResourceArn")
  valid_402657085 = validateParameter(valid_402657085, JString, required = true,
                                      default = nil)
  if valid_402657085 != nil:
    section.add "ResourceArn", valid_402657085
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657086 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657086 = validateParameter(valid_402657086, JString,
                                      required = false, default = nil)
  if valid_402657086 != nil:
    section.add "X-Amz-Security-Token", valid_402657086
  var valid_402657087 = header.getOrDefault("X-Amz-Signature")
  valid_402657087 = validateParameter(valid_402657087, JString,
                                      required = false, default = nil)
  if valid_402657087 != nil:
    section.add "X-Amz-Signature", valid_402657087
  var valid_402657088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657088 = validateParameter(valid_402657088, JString,
                                      required = false, default = nil)
  if valid_402657088 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657088
  var valid_402657089 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657089 = validateParameter(valid_402657089, JString,
                                      required = false, default = nil)
  if valid_402657089 != nil:
    section.add "X-Amz-Algorithm", valid_402657089
  var valid_402657090 = header.getOrDefault("X-Amz-Date")
  valid_402657090 = validateParameter(valid_402657090, JString,
                                      required = false, default = nil)
  if valid_402657090 != nil:
    section.add "X-Amz-Date", valid_402657090
  var valid_402657091 = header.getOrDefault("X-Amz-Credential")
  valid_402657091 = validateParameter(valid_402657091, JString,
                                      required = false, default = nil)
  if valid_402657091 != nil:
    section.add "X-Amz-Credential", valid_402657091
  var valid_402657092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657092 = validateParameter(valid_402657092, JString,
                                      required = false, default = nil)
  if valid_402657092 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657093: Call_UntagResource_402657081; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Remove one or more tags (keys and values) from a specified resource.
                                                                                         ## 
  let valid = call_402657093.validator(path, query, header, formData, body, _)
  let scheme = call_402657093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657093.makeUrl(scheme.get, call_402657093.host, call_402657093.base,
                                   call_402657093.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657093, uri, valid, _)

proc call*(call_402657094: Call_UntagResource_402657081; TagKeys: JsonNode;
           ResourceArn: string): Recallable =
  ## untagResource
  ## Remove one or more tags (keys and values) from a specified resource.
  ##   
                                                                         ## TagKeys: JArray (required)
                                                                         ##          
                                                                         ## : 
                                                                         ## <p>The 
                                                                         ## tags 
                                                                         ## (tag 
                                                                         ## keys) 
                                                                         ## that 
                                                                         ## you 
                                                                         ## want 
                                                                         ## to 
                                                                         ## remove 
                                                                         ## from 
                                                                         ## the 
                                                                         ## resource. 
                                                                         ## When 
                                                                         ## you 
                                                                         ## specify 
                                                                         ## a 
                                                                         ## tag 
                                                                         ## key, 
                                                                         ## the 
                                                                         ## action 
                                                                         ## removes 
                                                                         ## both 
                                                                         ## that 
                                                                         ## key 
                                                                         ## and 
                                                                         ## its 
                                                                         ## associated 
                                                                         ## tag 
                                                                         ## value.</p> 
                                                                         ## <p>To 
                                                                         ## remove 
                                                                         ## more 
                                                                         ## than 
                                                                         ## one 
                                                                         ## tag 
                                                                         ## from 
                                                                         ## the 
                                                                         ## resource, 
                                                                         ## append 
                                                                         ## the 
                                                                         ## <code>TagKeys</code> 
                                                                         ## parameter 
                                                                         ## and 
                                                                         ## argument 
                                                                         ## for 
                                                                         ## each 
                                                                         ## additional 
                                                                         ## tag 
                                                                         ## to 
                                                                         ## remove, 
                                                                         ## separated 
                                                                         ## by 
                                                                         ## an 
                                                                         ## ampersand. 
                                                                         ## For 
                                                                         ## example: 
                                                                         ## <code>/v1/email/tags?ResourceArn=ResourceArn&amp;TagKeys=Key1&amp;TagKeys=Key2</code> 
                                                                         ## </p>
  ##   
                                                                                ## ResourceArn: string (required)
                                                                                ##              
                                                                                ## : 
                                                                                ## The 
                                                                                ## Amazon 
                                                                                ## Resource 
                                                                                ## Name 
                                                                                ## (ARN) 
                                                                                ## of 
                                                                                ## the 
                                                                                ## resource 
                                                                                ## that 
                                                                                ## you 
                                                                                ## want 
                                                                                ## to 
                                                                                ## remove 
                                                                                ## one 
                                                                                ## or 
                                                                                ## more 
                                                                                ## tags 
                                                                                ## from.
  var query_402657095 = newJObject()
  if TagKeys != nil:
    query_402657095.add "TagKeys", TagKeys
  add(query_402657095, "ResourceArn", newJString(ResourceArn))
  result = call_402657094.call(nil, query_402657095, nil, nil, nil)

var untagResource* = Call_UntagResource_402657081(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "email.amazonaws.com",
    route: "/v1/email/tags#ResourceArn&TagKeys",
    validator: validate_UntagResource_402657082, base: "/",
    makeUrl: url_UntagResource_402657083, schemes: {Scheme.Https, Scheme.Http})
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
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
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