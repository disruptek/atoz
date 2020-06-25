
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Simple Email Service
## version: 2019-09-27
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon SES API v2</fullname> <p>Welcome to the Amazon SES API v2 Reference. This guide provides information about the Amazon SES API v2, including supported operations, data types, parameters, and schemas.</p> <p> <a href="https://aws.amazon.com/pinpoint">Amazon SES</a> is an AWS service that you can use to send email messages to your customers.</p> <p>If you're new to Amazon SES API v2, you might find it helpful to also review the <a href="https://docs.aws.amazon.com/ses/latest/DeveloperGuide/">Amazon Simple Email Service Developer Guide</a>. The <i>Amazon SES Developer Guide</i> provides information and code samples that demonstrate how to use Amazon SES API v2 features programmatically.</p> <p>The Amazon SES API v2 is available in several AWS Regions and it provides an endpoint for each of these Regions. For a list of all the Regions and endpoints where the API is currently available, see <a href="https://docs.aws.amazon.com/general/latest/gr/rande.html#ses_region">AWS Service Endpoints</a> in the <i>Amazon Web Services General Reference</i>. To learn more about AWS Regions, see <a href="https://docs.aws.amazon.com/general/latest/gr/rande-manage.html">Managing AWS Regions</a> in the <i>Amazon Web Services General Reference</i>.</p> <p>In each Region, AWS maintains multiple Availability Zones. These Availability Zones are physically isolated from each other, but are united by private, low-latency, high-throughput, and highly redundant network connections. These Availability Zones enable us to provide very high levels of availability and redundancy, while also minimizing latency. To learn more about the number of Availability Zones that are available in each Region, see <a href="http://aws.amazon.com/about-aws/global-infrastructure/">AWS Global Infrastructure</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/email/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "email.ap-northeast-1.amazonaws.com", "ap-southeast-1": "email.ap-southeast-1.amazonaws.com",
                           "us-west-2": "email.us-west-2.amazonaws.com",
                           "eu-west-2": "email.eu-west-2.amazonaws.com", "ap-northeast-3": "email.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "email.eu-central-1.amazonaws.com",
                           "us-east-2": "email.us-east-2.amazonaws.com",
                           "us-east-1": "email.us-east-1.amazonaws.com", "cn-northwest-1": "email.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "email.ap-south-1.amazonaws.com",
                           "eu-north-1": "email.eu-north-1.amazonaws.com", "ap-northeast-2": "email.ap-northeast-2.amazonaws.com",
                           "us-west-1": "email.us-west-1.amazonaws.com", "us-gov-east-1": "email.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "email.eu-west-3.amazonaws.com",
                           "cn-north-1": "email.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "email.sa-east-1.amazonaws.com",
                           "eu-west-1": "email.eu-west-1.amazonaws.com", "us-gov-west-1": "email.us-gov-west-1.amazonaws.com", "ap-southeast-2": "email.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "email.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
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
  awsServiceName = "sesv2"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CreateConfigurationSet_21626019 = ref object of OpenApiRestCall_21625435
proc url_CreateConfigurationSet_21626021(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConfigurationSet_21626020(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Create a configuration set. <i>Configuration sets</i> are groups of rules that you can apply to the emails that you send. You apply a configuration set to an email by specifying the name of the configuration set when you call the Amazon SES API v2. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email. 
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
  var valid_21626022 = header.getOrDefault("X-Amz-Date")
  valid_21626022 = validateParameter(valid_21626022, JString, required = false,
                                   default = nil)
  if valid_21626022 != nil:
    section.add "X-Amz-Date", valid_21626022
  var valid_21626023 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626023 = validateParameter(valid_21626023, JString, required = false,
                                   default = nil)
  if valid_21626023 != nil:
    section.add "X-Amz-Security-Token", valid_21626023
  var valid_21626024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626024 = validateParameter(valid_21626024, JString, required = false,
                                   default = nil)
  if valid_21626024 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626024
  var valid_21626025 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626025 = validateParameter(valid_21626025, JString, required = false,
                                   default = nil)
  if valid_21626025 != nil:
    section.add "X-Amz-Algorithm", valid_21626025
  var valid_21626026 = header.getOrDefault("X-Amz-Signature")
  valid_21626026 = validateParameter(valid_21626026, JString, required = false,
                                   default = nil)
  if valid_21626026 != nil:
    section.add "X-Amz-Signature", valid_21626026
  var valid_21626027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626027 = validateParameter(valid_21626027, JString, required = false,
                                   default = nil)
  if valid_21626027 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626027
  var valid_21626028 = header.getOrDefault("X-Amz-Credential")
  valid_21626028 = validateParameter(valid_21626028, JString, required = false,
                                   default = nil)
  if valid_21626028 != nil:
    section.add "X-Amz-Credential", valid_21626028
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

proc call*(call_21626030: Call_CreateConfigurationSet_21626019;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a configuration set. <i>Configuration sets</i> are groups of rules that you can apply to the emails that you send. You apply a configuration set to an email by specifying the name of the configuration set when you call the Amazon SES API v2. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email. 
  ## 
  let valid = call_21626030.validator(path, query, header, formData, body, _)
  let scheme = call_21626030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626030.makeUrl(scheme.get, call_21626030.host, call_21626030.base,
                               call_21626030.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626030, uri, valid, _)

proc call*(call_21626031: Call_CreateConfigurationSet_21626019; body: JsonNode): Recallable =
  ## createConfigurationSet
  ## Create a configuration set. <i>Configuration sets</i> are groups of rules that you can apply to the emails that you send. You apply a configuration set to an email by specifying the name of the configuration set when you call the Amazon SES API v2. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email. 
  ##   body: JObject (required)
  var body_21626032 = newJObject()
  if body != nil:
    body_21626032 = body
  result = call_21626031.call(nil, nil, nil, nil, body_21626032)

var createConfigurationSet* = Call_CreateConfigurationSet_21626019(
    name: "createConfigurationSet", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v2/email/configuration-sets",
    validator: validate_CreateConfigurationSet_21626020, base: "/",
    makeUrl: url_CreateConfigurationSet_21626021,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationSets_21625779 = ref object of OpenApiRestCall_21625435
proc url_ListConfigurationSets_21625781(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConfigurationSets_21625780(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>List all of the configuration sets associated with your account in the current region.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JInt
  ##           : The number of results to show in a single call to <code>ListConfigurationSets</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   NextToken: JString
  ##            : A token returned from a previous call to <code>ListConfigurationSets</code> to indicate the position in the list of configuration sets.
  section = newJObject()
  var valid_21625882 = query.getOrDefault("PageSize")
  valid_21625882 = validateParameter(valid_21625882, JInt, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "PageSize", valid_21625882
  var valid_21625883 = query.getOrDefault("NextToken")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "NextToken", valid_21625883
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21625884 = header.getOrDefault("X-Amz-Date")
  valid_21625884 = validateParameter(valid_21625884, JString, required = false,
                                   default = nil)
  if valid_21625884 != nil:
    section.add "X-Amz-Date", valid_21625884
  var valid_21625885 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625885 = validateParameter(valid_21625885, JString, required = false,
                                   default = nil)
  if valid_21625885 != nil:
    section.add "X-Amz-Security-Token", valid_21625885
  var valid_21625886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625886 = validateParameter(valid_21625886, JString, required = false,
                                   default = nil)
  if valid_21625886 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625886
  var valid_21625887 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625887 = validateParameter(valid_21625887, JString, required = false,
                                   default = nil)
  if valid_21625887 != nil:
    section.add "X-Amz-Algorithm", valid_21625887
  var valid_21625888 = header.getOrDefault("X-Amz-Signature")
  valid_21625888 = validateParameter(valid_21625888, JString, required = false,
                                   default = nil)
  if valid_21625888 != nil:
    section.add "X-Amz-Signature", valid_21625888
  var valid_21625889 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625889 = validateParameter(valid_21625889, JString, required = false,
                                   default = nil)
  if valid_21625889 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625889
  var valid_21625890 = header.getOrDefault("X-Amz-Credential")
  valid_21625890 = validateParameter(valid_21625890, JString, required = false,
                                   default = nil)
  if valid_21625890 != nil:
    section.add "X-Amz-Credential", valid_21625890
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625915: Call_ListConfigurationSets_21625779;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>List all of the configuration sets associated with your account in the current region.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  let valid = call_21625915.validator(path, query, header, formData, body, _)
  let scheme = call_21625915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625915.makeUrl(scheme.get, call_21625915.host, call_21625915.base,
                               call_21625915.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625915, uri, valid, _)

proc call*(call_21625978: Call_ListConfigurationSets_21625779; PageSize: int = 0;
          NextToken: string = ""): Recallable =
  ## listConfigurationSets
  ## <p>List all of the configuration sets associated with your account in the current region.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   PageSize: int
  ##           : The number of results to show in a single call to <code>ListConfigurationSets</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>ListConfigurationSets</code> to indicate the position in the list of configuration sets.
  var query_21625980 = newJObject()
  add(query_21625980, "PageSize", newJInt(PageSize))
  add(query_21625980, "NextToken", newJString(NextToken))
  result = call_21625978.call(nil, query_21625980, nil, nil, nil)

var listConfigurationSets* = Call_ListConfigurationSets_21625779(
    name: "listConfigurationSets", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v2/email/configuration-sets",
    validator: validate_ListConfigurationSets_21625780, base: "/",
    makeUrl: url_ListConfigurationSets_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfigurationSetEventDestination_21626060 = ref object of OpenApiRestCall_21625435
proc url_CreateConfigurationSetEventDestination_21626062(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/event-destinations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateConfigurationSetEventDestination_21626061(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Create an event destination. <i>Events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p> <p>A single configuration set can include more than one event destination.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_21626063 = path.getOrDefault("ConfigurationSetName")
  valid_21626063 = validateParameter(valid_21626063, JString, required = true,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "ConfigurationSetName", valid_21626063
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
  var valid_21626064 = header.getOrDefault("X-Amz-Date")
  valid_21626064 = validateParameter(valid_21626064, JString, required = false,
                                   default = nil)
  if valid_21626064 != nil:
    section.add "X-Amz-Date", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Security-Token", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Algorithm", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-Signature")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-Signature", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626069
  var valid_21626070 = header.getOrDefault("X-Amz-Credential")
  valid_21626070 = validateParameter(valid_21626070, JString, required = false,
                                   default = nil)
  if valid_21626070 != nil:
    section.add "X-Amz-Credential", valid_21626070
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

proc call*(call_21626072: Call_CreateConfigurationSetEventDestination_21626060;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Create an event destination. <i>Events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p> <p>A single configuration set can include more than one event destination.</p>
  ## 
  let valid = call_21626072.validator(path, query, header, formData, body, _)
  let scheme = call_21626072.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626072.makeUrl(scheme.get, call_21626072.host, call_21626072.base,
                               call_21626072.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626072, uri, valid, _)

proc call*(call_21626073: Call_CreateConfigurationSetEventDestination_21626060;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## createConfigurationSetEventDestination
  ## <p>Create an event destination. <i>Events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p> <p>A single configuration set can include more than one event destination.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_21626074 = newJObject()
  var body_21626075 = newJObject()
  add(path_21626074, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_21626075 = body
  result = call_21626073.call(path_21626074, nil, nil, nil, body_21626075)

var createConfigurationSetEventDestination* = Call_CreateConfigurationSetEventDestination_21626060(
    name: "createConfigurationSetEventDestination", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v2/email/configuration-sets/{ConfigurationSetName}/event-destinations",
    validator: validate_CreateConfigurationSetEventDestination_21626061,
    base: "/", makeUrl: url_CreateConfigurationSetEventDestination_21626062,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigurationSetEventDestinations_21626033 = ref object of OpenApiRestCall_21625435
proc url_GetConfigurationSetEventDestinations_21626035(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/event-destinations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetConfigurationSetEventDestinations_21626034(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Retrieve a list of event destinations that are associated with a configuration set.</p> <p> <i>Events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_21626049 = path.getOrDefault("ConfigurationSetName")
  valid_21626049 = validateParameter(valid_21626049, JString, required = true,
                                   default = nil)
  if valid_21626049 != nil:
    section.add "ConfigurationSetName", valid_21626049
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
  var valid_21626050 = header.getOrDefault("X-Amz-Date")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Date", valid_21626050
  var valid_21626051 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "X-Amz-Security-Token", valid_21626051
  var valid_21626052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626052 = validateParameter(valid_21626052, JString, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626052
  var valid_21626053 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "X-Amz-Algorithm", valid_21626053
  var valid_21626054 = header.getOrDefault("X-Amz-Signature")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Signature", valid_21626054
  var valid_21626055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626055
  var valid_21626056 = header.getOrDefault("X-Amz-Credential")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-Credential", valid_21626056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626057: Call_GetConfigurationSetEventDestinations_21626033;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieve a list of event destinations that are associated with a configuration set.</p> <p> <i>Events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  let valid = call_21626057.validator(path, query, header, formData, body, _)
  let scheme = call_21626057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626057.makeUrl(scheme.get, call_21626057.host, call_21626057.base,
                               call_21626057.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626057, uri, valid, _)

proc call*(call_21626058: Call_GetConfigurationSetEventDestinations_21626033;
          ConfigurationSetName: string): Recallable =
  ## getConfigurationSetEventDestinations
  ## <p>Retrieve a list of event destinations that are associated with a configuration set.</p> <p> <i>Events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  var path_21626059 = newJObject()
  add(path_21626059, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_21626058.call(path_21626059, nil, nil, nil, nil)

var getConfigurationSetEventDestinations* = Call_GetConfigurationSetEventDestinations_21626033(
    name: "getConfigurationSetEventDestinations", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v2/email/configuration-sets/{ConfigurationSetName}/event-destinations",
    validator: validate_GetConfigurationSetEventDestinations_21626034, base: "/",
    makeUrl: url_GetConfigurationSetEventDestinations_21626035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDedicatedIpPool_21626091 = ref object of OpenApiRestCall_21625435
proc url_CreateDedicatedIpPool_21626093(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDedicatedIpPool_21626092(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Create a new pool of dedicated IP addresses. A pool can include one or more dedicated IP addresses that are associated with your AWS account. You can associate a pool with a configuration set. When you send an email that uses that configuration set, the message is sent from one of the addresses in the associated pool.
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
  var valid_21626094 = header.getOrDefault("X-Amz-Date")
  valid_21626094 = validateParameter(valid_21626094, JString, required = false,
                                   default = nil)
  if valid_21626094 != nil:
    section.add "X-Amz-Date", valid_21626094
  var valid_21626095 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-Security-Token", valid_21626095
  var valid_21626096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Algorithm", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-Signature")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-Signature", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626099
  var valid_21626100 = header.getOrDefault("X-Amz-Credential")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "X-Amz-Credential", valid_21626100
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

proc call*(call_21626102: Call_CreateDedicatedIpPool_21626091;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new pool of dedicated IP addresses. A pool can include one or more dedicated IP addresses that are associated with your AWS account. You can associate a pool with a configuration set. When you send an email that uses that configuration set, the message is sent from one of the addresses in the associated pool.
  ## 
  let valid = call_21626102.validator(path, query, header, formData, body, _)
  let scheme = call_21626102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626102.makeUrl(scheme.get, call_21626102.host, call_21626102.base,
                               call_21626102.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626102, uri, valid, _)

proc call*(call_21626103: Call_CreateDedicatedIpPool_21626091; body: JsonNode): Recallable =
  ## createDedicatedIpPool
  ## Create a new pool of dedicated IP addresses. A pool can include one or more dedicated IP addresses that are associated with your AWS account. You can associate a pool with a configuration set. When you send an email that uses that configuration set, the message is sent from one of the addresses in the associated pool.
  ##   body: JObject (required)
  var body_21626104 = newJObject()
  if body != nil:
    body_21626104 = body
  result = call_21626103.call(nil, nil, nil, nil, body_21626104)

var createDedicatedIpPool* = Call_CreateDedicatedIpPool_21626091(
    name: "createDedicatedIpPool", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v2/email/dedicated-ip-pools",
    validator: validate_CreateDedicatedIpPool_21626092, base: "/",
    makeUrl: url_CreateDedicatedIpPool_21626093,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDedicatedIpPools_21626076 = ref object of OpenApiRestCall_21625435
proc url_ListDedicatedIpPools_21626078(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDedicatedIpPools_21626077(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List all of the dedicated IP pools that exist in your AWS account in the current Region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JInt
  ##           : The number of results to show in a single call to <code>ListDedicatedIpPools</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   NextToken: JString
  ##            : A token returned from a previous call to <code>ListDedicatedIpPools</code> to indicate the position in the list of dedicated IP pools.
  section = newJObject()
  var valid_21626079 = query.getOrDefault("PageSize")
  valid_21626079 = validateParameter(valid_21626079, JInt, required = false,
                                   default = nil)
  if valid_21626079 != nil:
    section.add "PageSize", valid_21626079
  var valid_21626080 = query.getOrDefault("NextToken")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "NextToken", valid_21626080
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626081 = header.getOrDefault("X-Amz-Date")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-Date", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Security-Token", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Algorithm", valid_21626084
  var valid_21626085 = header.getOrDefault("X-Amz-Signature")
  valid_21626085 = validateParameter(valid_21626085, JString, required = false,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "X-Amz-Signature", valid_21626085
  var valid_21626086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626086
  var valid_21626087 = header.getOrDefault("X-Amz-Credential")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "X-Amz-Credential", valid_21626087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626088: Call_ListDedicatedIpPools_21626076; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## List all of the dedicated IP pools that exist in your AWS account in the current Region.
  ## 
  let valid = call_21626088.validator(path, query, header, formData, body, _)
  let scheme = call_21626088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626088.makeUrl(scheme.get, call_21626088.host, call_21626088.base,
                               call_21626088.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626088, uri, valid, _)

proc call*(call_21626089: Call_ListDedicatedIpPools_21626076; PageSize: int = 0;
          NextToken: string = ""): Recallable =
  ## listDedicatedIpPools
  ## List all of the dedicated IP pools that exist in your AWS account in the current Region.
  ##   PageSize: int
  ##           : The number of results to show in a single call to <code>ListDedicatedIpPools</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>ListDedicatedIpPools</code> to indicate the position in the list of dedicated IP pools.
  var query_21626090 = newJObject()
  add(query_21626090, "PageSize", newJInt(PageSize))
  add(query_21626090, "NextToken", newJString(NextToken))
  result = call_21626089.call(nil, query_21626090, nil, nil, nil)

var listDedicatedIpPools* = Call_ListDedicatedIpPools_21626076(
    name: "listDedicatedIpPools", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v2/email/dedicated-ip-pools",
    validator: validate_ListDedicatedIpPools_21626077, base: "/",
    makeUrl: url_ListDedicatedIpPools_21626078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeliverabilityTestReport_21626105 = ref object of OpenApiRestCall_21625435
proc url_CreateDeliverabilityTestReport_21626107(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDeliverabilityTestReport_21626106(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Create a new predictive inbox placement test. Predictive inbox placement tests can help you predict how your messages will be handled by various email providers around the world. When you perform a predictive inbox placement test, you provide a sample message that contains the content that you plan to send to your customers. Amazon SES then sends that message to special email addresses spread across several major email providers. After about 24 hours, the test is complete, and you can use the <code>GetDeliverabilityTestReport</code> operation to view the results of the test.
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
  var valid_21626108 = header.getOrDefault("X-Amz-Date")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "X-Amz-Date", valid_21626108
  var valid_21626109 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626109 = validateParameter(valid_21626109, JString, required = false,
                                   default = nil)
  if valid_21626109 != nil:
    section.add "X-Amz-Security-Token", valid_21626109
  var valid_21626110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626110
  var valid_21626111 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "X-Amz-Algorithm", valid_21626111
  var valid_21626112 = header.getOrDefault("X-Amz-Signature")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-Signature", valid_21626112
  var valid_21626113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626113
  var valid_21626114 = header.getOrDefault("X-Amz-Credential")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Credential", valid_21626114
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

proc call*(call_21626116: Call_CreateDeliverabilityTestReport_21626105;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new predictive inbox placement test. Predictive inbox placement tests can help you predict how your messages will be handled by various email providers around the world. When you perform a predictive inbox placement test, you provide a sample message that contains the content that you plan to send to your customers. Amazon SES then sends that message to special email addresses spread across several major email providers. After about 24 hours, the test is complete, and you can use the <code>GetDeliverabilityTestReport</code> operation to view the results of the test.
  ## 
  let valid = call_21626116.validator(path, query, header, formData, body, _)
  let scheme = call_21626116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626116.makeUrl(scheme.get, call_21626116.host, call_21626116.base,
                               call_21626116.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626116, uri, valid, _)

proc call*(call_21626117: Call_CreateDeliverabilityTestReport_21626105;
          body: JsonNode): Recallable =
  ## createDeliverabilityTestReport
  ## Create a new predictive inbox placement test. Predictive inbox placement tests can help you predict how your messages will be handled by various email providers around the world. When you perform a predictive inbox placement test, you provide a sample message that contains the content that you plan to send to your customers. Amazon SES then sends that message to special email addresses spread across several major email providers. After about 24 hours, the test is complete, and you can use the <code>GetDeliverabilityTestReport</code> operation to view the results of the test.
  ##   body: JObject (required)
  var body_21626118 = newJObject()
  if body != nil:
    body_21626118 = body
  result = call_21626117.call(nil, nil, nil, nil, body_21626118)

var createDeliverabilityTestReport* = Call_CreateDeliverabilityTestReport_21626105(
    name: "createDeliverabilityTestReport", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v2/email/deliverability-dashboard/test",
    validator: validate_CreateDeliverabilityTestReport_21626106, base: "/",
    makeUrl: url_CreateDeliverabilityTestReport_21626107,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEmailIdentity_21626134 = ref object of OpenApiRestCall_21625435
proc url_CreateEmailIdentity_21626136(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateEmailIdentity_21626135(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Starts the process of verifying an email identity. An <i>identity</i> is an email address or domain that you use when you send email. Before you can use an identity to send email, you first have to verify it. By verifying an identity, you demonstrate that you're the owner of the identity, and that you've given Amazon SES API v2 permission to send email from the identity.</p> <p>When you verify an email address, Amazon SES sends an email to the address. Your email address is verified as soon as you follow the link in the verification email. </p> <p>When you verify a domain without specifying the <code>DkimSigningAttributes</code> object, this operation provides a set of DKIM tokens. You can convert these tokens into CNAME records, which you then add to the DNS configuration for your domain. Your domain is verified when Amazon SES detects these records in the DNS configuration for your domain. This verification method is known as <a href="https://docs.aws.amazon.com/ses/latest/DeveloperGuide/easy-dkim.html">Easy DKIM</a>.</p> <p>Alternatively, you can perform the verification process by providing your own public-private key pair. This verification method is known as Bring Your Own DKIM (BYODKIM). To use BYODKIM, your call to the <code>CreateEmailIdentity</code> operation has to include the <code>DkimSigningAttributes</code> object. When you specify this object, you provide a selector (a component of the DNS record name that identifies the public key that you want to use for DKIM authentication) and a private key.</p>
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
  var valid_21626137 = header.getOrDefault("X-Amz-Date")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-Date", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-Security-Token", valid_21626138
  var valid_21626139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Algorithm", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-Signature")
  valid_21626141 = validateParameter(valid_21626141, JString, required = false,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "X-Amz-Signature", valid_21626141
  var valid_21626142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626142
  var valid_21626143 = header.getOrDefault("X-Amz-Credential")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-Credential", valid_21626143
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

proc call*(call_21626145: Call_CreateEmailIdentity_21626134; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Starts the process of verifying an email identity. An <i>identity</i> is an email address or domain that you use when you send email. Before you can use an identity to send email, you first have to verify it. By verifying an identity, you demonstrate that you're the owner of the identity, and that you've given Amazon SES API v2 permission to send email from the identity.</p> <p>When you verify an email address, Amazon SES sends an email to the address. Your email address is verified as soon as you follow the link in the verification email. </p> <p>When you verify a domain without specifying the <code>DkimSigningAttributes</code> object, this operation provides a set of DKIM tokens. You can convert these tokens into CNAME records, which you then add to the DNS configuration for your domain. Your domain is verified when Amazon SES detects these records in the DNS configuration for your domain. This verification method is known as <a href="https://docs.aws.amazon.com/ses/latest/DeveloperGuide/easy-dkim.html">Easy DKIM</a>.</p> <p>Alternatively, you can perform the verification process by providing your own public-private key pair. This verification method is known as Bring Your Own DKIM (BYODKIM). To use BYODKIM, your call to the <code>CreateEmailIdentity</code> operation has to include the <code>DkimSigningAttributes</code> object. When you specify this object, you provide a selector (a component of the DNS record name that identifies the public key that you want to use for DKIM authentication) and a private key.</p>
  ## 
  let valid = call_21626145.validator(path, query, header, formData, body, _)
  let scheme = call_21626145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626145.makeUrl(scheme.get, call_21626145.host, call_21626145.base,
                               call_21626145.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626145, uri, valid, _)

proc call*(call_21626146: Call_CreateEmailIdentity_21626134; body: JsonNode): Recallable =
  ## createEmailIdentity
  ## <p>Starts the process of verifying an email identity. An <i>identity</i> is an email address or domain that you use when you send email. Before you can use an identity to send email, you first have to verify it. By verifying an identity, you demonstrate that you're the owner of the identity, and that you've given Amazon SES API v2 permission to send email from the identity.</p> <p>When you verify an email address, Amazon SES sends an email to the address. Your email address is verified as soon as you follow the link in the verification email. </p> <p>When you verify a domain without specifying the <code>DkimSigningAttributes</code> object, this operation provides a set of DKIM tokens. You can convert these tokens into CNAME records, which you then add to the DNS configuration for your domain. Your domain is verified when Amazon SES detects these records in the DNS configuration for your domain. This verification method is known as <a href="https://docs.aws.amazon.com/ses/latest/DeveloperGuide/easy-dkim.html">Easy DKIM</a>.</p> <p>Alternatively, you can perform the verification process by providing your own public-private key pair. This verification method is known as Bring Your Own DKIM (BYODKIM). To use BYODKIM, your call to the <code>CreateEmailIdentity</code> operation has to include the <code>DkimSigningAttributes</code> object. When you specify this object, you provide a selector (a component of the DNS record name that identifies the public key that you want to use for DKIM authentication) and a private key.</p>
  ##   body: JObject (required)
  var body_21626147 = newJObject()
  if body != nil:
    body_21626147 = body
  result = call_21626146.call(nil, nil, nil, nil, body_21626147)

var createEmailIdentity* = Call_CreateEmailIdentity_21626134(
    name: "createEmailIdentity", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v2/email/identities",
    validator: validate_CreateEmailIdentity_21626135, base: "/",
    makeUrl: url_CreateEmailIdentity_21626136,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEmailIdentities_21626119 = ref object of OpenApiRestCall_21625435
proc url_ListEmailIdentities_21626121(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEmailIdentities_21626120(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of all of the email identities that are associated with your AWS account. An identity can be either an email address or a domain. This operation returns identities that are verified as well as those that aren't. This operation returns identities that are associated with Amazon SES and Amazon Pinpoint.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JInt
  ##           : <p>The number of results to show in a single call to <code>ListEmailIdentities</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.</p> <p>The value you specify has to be at least 0, and can be no more than 1000.</p>
  ##   NextToken: JString
  ##            : A token returned from a previous call to <code>ListEmailIdentities</code> to indicate the position in the list of identities.
  section = newJObject()
  var valid_21626122 = query.getOrDefault("PageSize")
  valid_21626122 = validateParameter(valid_21626122, JInt, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "PageSize", valid_21626122
  var valid_21626123 = query.getOrDefault("NextToken")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "NextToken", valid_21626123
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626124 = header.getOrDefault("X-Amz-Date")
  valid_21626124 = validateParameter(valid_21626124, JString, required = false,
                                   default = nil)
  if valid_21626124 != nil:
    section.add "X-Amz-Date", valid_21626124
  var valid_21626125 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-Security-Token", valid_21626125
  var valid_21626126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626126
  var valid_21626127 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "X-Amz-Algorithm", valid_21626127
  var valid_21626128 = header.getOrDefault("X-Amz-Signature")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "X-Amz-Signature", valid_21626128
  var valid_21626129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626129
  var valid_21626130 = header.getOrDefault("X-Amz-Credential")
  valid_21626130 = validateParameter(valid_21626130, JString, required = false,
                                   default = nil)
  if valid_21626130 != nil:
    section.add "X-Amz-Credential", valid_21626130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626131: Call_ListEmailIdentities_21626119; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of all of the email identities that are associated with your AWS account. An identity can be either an email address or a domain. This operation returns identities that are verified as well as those that aren't. This operation returns identities that are associated with Amazon SES and Amazon Pinpoint.
  ## 
  let valid = call_21626131.validator(path, query, header, formData, body, _)
  let scheme = call_21626131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626131.makeUrl(scheme.get, call_21626131.host, call_21626131.base,
                               call_21626131.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626131, uri, valid, _)

proc call*(call_21626132: Call_ListEmailIdentities_21626119; PageSize: int = 0;
          NextToken: string = ""): Recallable =
  ## listEmailIdentities
  ## Returns a list of all of the email identities that are associated with your AWS account. An identity can be either an email address or a domain. This operation returns identities that are verified as well as those that aren't. This operation returns identities that are associated with Amazon SES and Amazon Pinpoint.
  ##   PageSize: int
  ##           : <p>The number of results to show in a single call to <code>ListEmailIdentities</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.</p> <p>The value you specify has to be at least 0, and can be no more than 1000.</p>
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>ListEmailIdentities</code> to indicate the position in the list of identities.
  var query_21626133 = newJObject()
  add(query_21626133, "PageSize", newJInt(PageSize))
  add(query_21626133, "NextToken", newJString(NextToken))
  result = call_21626132.call(nil, query_21626133, nil, nil, nil)

var listEmailIdentities* = Call_ListEmailIdentities_21626119(
    name: "listEmailIdentities", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v2/email/identities",
    validator: validate_ListEmailIdentities_21626120, base: "/",
    makeUrl: url_ListEmailIdentities_21626121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigurationSet_21626148 = ref object of OpenApiRestCall_21625435
proc url_GetConfigurationSet_21626150(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetConfigurationSet_21626149(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Get information about an existing configuration set, including the dedicated IP pool that it's associated with, whether or not it's enabled for sending email, and more.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_21626151 = path.getOrDefault("ConfigurationSetName")
  valid_21626151 = validateParameter(valid_21626151, JString, required = true,
                                   default = nil)
  if valid_21626151 != nil:
    section.add "ConfigurationSetName", valid_21626151
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
  var valid_21626152 = header.getOrDefault("X-Amz-Date")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-Date", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-Security-Token", valid_21626153
  var valid_21626154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626154 = validateParameter(valid_21626154, JString, required = false,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626154
  var valid_21626155 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-Algorithm", valid_21626155
  var valid_21626156 = header.getOrDefault("X-Amz-Signature")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "X-Amz-Signature", valid_21626156
  var valid_21626157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626157
  var valid_21626158 = header.getOrDefault("X-Amz-Credential")
  valid_21626158 = validateParameter(valid_21626158, JString, required = false,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "X-Amz-Credential", valid_21626158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626159: Call_GetConfigurationSet_21626148; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Get information about an existing configuration set, including the dedicated IP pool that it's associated with, whether or not it's enabled for sending email, and more.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  let valid = call_21626159.validator(path, query, header, formData, body, _)
  let scheme = call_21626159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626159.makeUrl(scheme.get, call_21626159.host, call_21626159.base,
                               call_21626159.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626159, uri, valid, _)

proc call*(call_21626160: Call_GetConfigurationSet_21626148;
          ConfigurationSetName: string): Recallable =
  ## getConfigurationSet
  ## <p>Get information about an existing configuration set, including the dedicated IP pool that it's associated with, whether or not it's enabled for sending email, and more.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  var path_21626161 = newJObject()
  add(path_21626161, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_21626160.call(path_21626161, nil, nil, nil, nil)

var getConfigurationSet* = Call_GetConfigurationSet_21626148(
    name: "getConfigurationSet", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v2/email/configuration-sets/{ConfigurationSetName}",
    validator: validate_GetConfigurationSet_21626149, base: "/",
    makeUrl: url_GetConfigurationSet_21626150,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationSet_21626162 = ref object of OpenApiRestCall_21625435
proc url_DeleteConfigurationSet_21626164(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteConfigurationSet_21626163(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Delete an existing configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_21626165 = path.getOrDefault("ConfigurationSetName")
  valid_21626165 = validateParameter(valid_21626165, JString, required = true,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "ConfigurationSetName", valid_21626165
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
  var valid_21626166 = header.getOrDefault("X-Amz-Date")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "X-Amz-Date", valid_21626166
  var valid_21626167 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "X-Amz-Security-Token", valid_21626167
  var valid_21626168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626168
  var valid_21626169 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626169 = validateParameter(valid_21626169, JString, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "X-Amz-Algorithm", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-Signature")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Signature", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626171
  var valid_21626172 = header.getOrDefault("X-Amz-Credential")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "X-Amz-Credential", valid_21626172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626173: Call_DeleteConfigurationSet_21626162;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Delete an existing configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  let valid = call_21626173.validator(path, query, header, formData, body, _)
  let scheme = call_21626173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626173.makeUrl(scheme.get, call_21626173.host, call_21626173.base,
                               call_21626173.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626173, uri, valid, _)

proc call*(call_21626174: Call_DeleteConfigurationSet_21626162;
          ConfigurationSetName: string): Recallable =
  ## deleteConfigurationSet
  ## <p>Delete an existing configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  var path_21626175 = newJObject()
  add(path_21626175, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_21626174.call(path_21626175, nil, nil, nil, nil)

var deleteConfigurationSet* = Call_DeleteConfigurationSet_21626162(
    name: "deleteConfigurationSet", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com",
    route: "/v2/email/configuration-sets/{ConfigurationSetName}",
    validator: validate_DeleteConfigurationSet_21626163, base: "/",
    makeUrl: url_DeleteConfigurationSet_21626164,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfigurationSetEventDestination_21626176 = ref object of OpenApiRestCall_21625435
proc url_UpdateConfigurationSetEventDestination_21626178(protocol: Scheme;
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
    segments = @[(kind: ConstantSegment, value: "/v2/email/configuration-sets/"),
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

proc validate_UpdateConfigurationSetEventDestination_21626177(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Update the configuration of an event destination for a configuration set.</p> <p> <i>Events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   EventDestinationName: JString (required)
  ##                       : <p>The name of an event destination.</p> <p> <i>Events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_21626179 = path.getOrDefault("ConfigurationSetName")
  valid_21626179 = validateParameter(valid_21626179, JString, required = true,
                                   default = nil)
  if valid_21626179 != nil:
    section.add "ConfigurationSetName", valid_21626179
  var valid_21626180 = path.getOrDefault("EventDestinationName")
  valid_21626180 = validateParameter(valid_21626180, JString, required = true,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "EventDestinationName", valid_21626180
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
  var valid_21626181 = header.getOrDefault("X-Amz-Date")
  valid_21626181 = validateParameter(valid_21626181, JString, required = false,
                                   default = nil)
  if valid_21626181 != nil:
    section.add "X-Amz-Date", valid_21626181
  var valid_21626182 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-Security-Token", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "X-Amz-Algorithm", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-Signature")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-Signature", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626186
  var valid_21626187 = header.getOrDefault("X-Amz-Credential")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Credential", valid_21626187
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

proc call*(call_21626189: Call_UpdateConfigurationSetEventDestination_21626176;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Update the configuration of an event destination for a configuration set.</p> <p> <i>Events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  let valid = call_21626189.validator(path, query, header, formData, body, _)
  let scheme = call_21626189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626189.makeUrl(scheme.get, call_21626189.host, call_21626189.base,
                               call_21626189.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626189, uri, valid, _)

proc call*(call_21626190: Call_UpdateConfigurationSetEventDestination_21626176;
          ConfigurationSetName: string; body: JsonNode; EventDestinationName: string): Recallable =
  ## updateConfigurationSetEventDestination
  ## <p>Update the configuration of an event destination for a configuration set.</p> <p> <i>Events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  ##   EventDestinationName: string (required)
  ##                       : <p>The name of an event destination.</p> <p> <i>Events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  var path_21626191 = newJObject()
  var body_21626192 = newJObject()
  add(path_21626191, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_21626192 = body
  add(path_21626191, "EventDestinationName", newJString(EventDestinationName))
  result = call_21626190.call(path_21626191, nil, nil, nil, body_21626192)

var updateConfigurationSetEventDestination* = Call_UpdateConfigurationSetEventDestination_21626176(
    name: "updateConfigurationSetEventDestination", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v2/email/configuration-sets/{ConfigurationSetName}/event-destinations/{EventDestinationName}",
    validator: validate_UpdateConfigurationSetEventDestination_21626177,
    base: "/", makeUrl: url_UpdateConfigurationSetEventDestination_21626178,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationSetEventDestination_21626193 = ref object of OpenApiRestCall_21625435
proc url_DeleteConfigurationSetEventDestination_21626195(protocol: Scheme;
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
    segments = @[(kind: ConstantSegment, value: "/v2/email/configuration-sets/"),
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

proc validate_DeleteConfigurationSetEventDestination_21626194(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Delete an event destination.</p> <p> <i>Events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   EventDestinationName: JString (required)
  ##                       : <p>The name of an event destination.</p> <p> <i>Events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_21626196 = path.getOrDefault("ConfigurationSetName")
  valid_21626196 = validateParameter(valid_21626196, JString, required = true,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "ConfigurationSetName", valid_21626196
  var valid_21626197 = path.getOrDefault("EventDestinationName")
  valid_21626197 = validateParameter(valid_21626197, JString, required = true,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "EventDestinationName", valid_21626197
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
  var valid_21626198 = header.getOrDefault("X-Amz-Date")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Date", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626199 = validateParameter(valid_21626199, JString, required = false,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "X-Amz-Security-Token", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-Algorithm", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-Signature")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-Signature", valid_21626202
  var valid_21626203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626203
  var valid_21626204 = header.getOrDefault("X-Amz-Credential")
  valid_21626204 = validateParameter(valid_21626204, JString, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "X-Amz-Credential", valid_21626204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626205: Call_DeleteConfigurationSetEventDestination_21626193;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Delete an event destination.</p> <p> <i>Events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  let valid = call_21626205.validator(path, query, header, formData, body, _)
  let scheme = call_21626205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626205.makeUrl(scheme.get, call_21626205.host, call_21626205.base,
                               call_21626205.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626205, uri, valid, _)

proc call*(call_21626206: Call_DeleteConfigurationSetEventDestination_21626193;
          ConfigurationSetName: string; EventDestinationName: string): Recallable =
  ## deleteConfigurationSetEventDestination
  ## <p>Delete an event destination.</p> <p> <i>Events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   EventDestinationName: string (required)
  ##                       : <p>The name of an event destination.</p> <p> <i>Events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  var path_21626207 = newJObject()
  add(path_21626207, "ConfigurationSetName", newJString(ConfigurationSetName))
  add(path_21626207, "EventDestinationName", newJString(EventDestinationName))
  result = call_21626206.call(path_21626207, nil, nil, nil, nil)

var deleteConfigurationSetEventDestination* = Call_DeleteConfigurationSetEventDestination_21626193(
    name: "deleteConfigurationSetEventDestination", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com", route: "/v2/email/configuration-sets/{ConfigurationSetName}/event-destinations/{EventDestinationName}",
    validator: validate_DeleteConfigurationSetEventDestination_21626194,
    base: "/", makeUrl: url_DeleteConfigurationSetEventDestination_21626195,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDedicatedIpPool_21626208 = ref object of OpenApiRestCall_21625435
proc url_DeleteDedicatedIpPool_21626210(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "PoolName" in path, "`PoolName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/dedicated-ip-pools/"),
               (kind: VariableSegment, value: "PoolName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDedicatedIpPool_21626209(path: JsonNode; query: JsonNode;
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
  assert path != nil, "path argument is necessary due to required `PoolName` field"
  var valid_21626211 = path.getOrDefault("PoolName")
  valid_21626211 = validateParameter(valid_21626211, JString, required = true,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "PoolName", valid_21626211
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
  var valid_21626212 = header.getOrDefault("X-Amz-Date")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "X-Amz-Date", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-Security-Token", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Algorithm", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-Signature")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-Signature", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-Credential")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-Credential", valid_21626218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626219: Call_DeleteDedicatedIpPool_21626208;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete a dedicated IP pool.
  ## 
  let valid = call_21626219.validator(path, query, header, formData, body, _)
  let scheme = call_21626219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626219.makeUrl(scheme.get, call_21626219.host, call_21626219.base,
                               call_21626219.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626219, uri, valid, _)

proc call*(call_21626220: Call_DeleteDedicatedIpPool_21626208; PoolName: string): Recallable =
  ## deleteDedicatedIpPool
  ## Delete a dedicated IP pool.
  ##   PoolName: string (required)
  ##           : The name of a dedicated IP pool.
  var path_21626221 = newJObject()
  add(path_21626221, "PoolName", newJString(PoolName))
  result = call_21626220.call(path_21626221, nil, nil, nil, nil)

var deleteDedicatedIpPool* = Call_DeleteDedicatedIpPool_21626208(
    name: "deleteDedicatedIpPool", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com", route: "/v2/email/dedicated-ip-pools/{PoolName}",
    validator: validate_DeleteDedicatedIpPool_21626209, base: "/",
    makeUrl: url_DeleteDedicatedIpPool_21626210,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEmailIdentity_21626222 = ref object of OpenApiRestCall_21625435
proc url_GetEmailIdentity_21626224(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "EmailIdentity" in path, "`EmailIdentity` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/identities/"),
               (kind: VariableSegment, value: "EmailIdentity")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetEmailIdentity_21626223(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Provides information about a specific identity, including the identity's verification status, its DKIM authentication status, and its custom Mail-From settings.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EmailIdentity: JString (required)
  ##                : The email identity that you want to retrieve details for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `EmailIdentity` field"
  var valid_21626225 = path.getOrDefault("EmailIdentity")
  valid_21626225 = validateParameter(valid_21626225, JString, required = true,
                                   default = nil)
  if valid_21626225 != nil:
    section.add "EmailIdentity", valid_21626225
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
  var valid_21626226 = header.getOrDefault("X-Amz-Date")
  valid_21626226 = validateParameter(valid_21626226, JString, required = false,
                                   default = nil)
  if valid_21626226 != nil:
    section.add "X-Amz-Date", valid_21626226
  var valid_21626227 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "X-Amz-Security-Token", valid_21626227
  var valid_21626228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "X-Amz-Algorithm", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Signature")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Signature", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Credential")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Credential", valid_21626232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626233: Call_GetEmailIdentity_21626222; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides information about a specific identity, including the identity's verification status, its DKIM authentication status, and its custom Mail-From settings.
  ## 
  let valid = call_21626233.validator(path, query, header, formData, body, _)
  let scheme = call_21626233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626233.makeUrl(scheme.get, call_21626233.host, call_21626233.base,
                               call_21626233.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626233, uri, valid, _)

proc call*(call_21626234: Call_GetEmailIdentity_21626222; EmailIdentity: string): Recallable =
  ## getEmailIdentity
  ## Provides information about a specific identity, including the identity's verification status, its DKIM authentication status, and its custom Mail-From settings.
  ##   EmailIdentity: string (required)
  ##                : The email identity that you want to retrieve details for.
  var path_21626235 = newJObject()
  add(path_21626235, "EmailIdentity", newJString(EmailIdentity))
  result = call_21626234.call(path_21626235, nil, nil, nil, nil)

var getEmailIdentity* = Call_GetEmailIdentity_21626222(name: "getEmailIdentity",
    meth: HttpMethod.HttpGet, host: "email.amazonaws.com",
    route: "/v2/email/identities/{EmailIdentity}",
    validator: validate_GetEmailIdentity_21626223, base: "/",
    makeUrl: url_GetEmailIdentity_21626224, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEmailIdentity_21626236 = ref object of OpenApiRestCall_21625435
proc url_DeleteEmailIdentity_21626238(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "EmailIdentity" in path, "`EmailIdentity` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/identities/"),
               (kind: VariableSegment, value: "EmailIdentity")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteEmailIdentity_21626237(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an email identity. An identity can be either an email address or a domain name.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EmailIdentity: JString (required)
  ##                : The identity (that is, the email address or domain) that you want to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `EmailIdentity` field"
  var valid_21626239 = path.getOrDefault("EmailIdentity")
  valid_21626239 = validateParameter(valid_21626239, JString, required = true,
                                   default = nil)
  if valid_21626239 != nil:
    section.add "EmailIdentity", valid_21626239
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
  var valid_21626240 = header.getOrDefault("X-Amz-Date")
  valid_21626240 = validateParameter(valid_21626240, JString, required = false,
                                   default = nil)
  if valid_21626240 != nil:
    section.add "X-Amz-Date", valid_21626240
  var valid_21626241 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626241 = validateParameter(valid_21626241, JString, required = false,
                                   default = nil)
  if valid_21626241 != nil:
    section.add "X-Amz-Security-Token", valid_21626241
  var valid_21626242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626242 = validateParameter(valid_21626242, JString, required = false,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626242
  var valid_21626243 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626243 = validateParameter(valid_21626243, JString, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "X-Amz-Algorithm", valid_21626243
  var valid_21626244 = header.getOrDefault("X-Amz-Signature")
  valid_21626244 = validateParameter(valid_21626244, JString, required = false,
                                   default = nil)
  if valid_21626244 != nil:
    section.add "X-Amz-Signature", valid_21626244
  var valid_21626245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-Credential")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "X-Amz-Credential", valid_21626246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626247: Call_DeleteEmailIdentity_21626236; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an email identity. An identity can be either an email address or a domain name.
  ## 
  let valid = call_21626247.validator(path, query, header, formData, body, _)
  let scheme = call_21626247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626247.makeUrl(scheme.get, call_21626247.host, call_21626247.base,
                               call_21626247.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626247, uri, valid, _)

proc call*(call_21626248: Call_DeleteEmailIdentity_21626236; EmailIdentity: string): Recallable =
  ## deleteEmailIdentity
  ## Deletes an email identity. An identity can be either an email address or a domain name.
  ##   EmailIdentity: string (required)
  ##                : The identity (that is, the email address or domain) that you want to delete.
  var path_21626249 = newJObject()
  add(path_21626249, "EmailIdentity", newJString(EmailIdentity))
  result = call_21626248.call(path_21626249, nil, nil, nil, nil)

var deleteEmailIdentity* = Call_DeleteEmailIdentity_21626236(
    name: "deleteEmailIdentity", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com", route: "/v2/email/identities/{EmailIdentity}",
    validator: validate_DeleteEmailIdentity_21626237, base: "/",
    makeUrl: url_DeleteEmailIdentity_21626238,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSuppressedDestination_21626250 = ref object of OpenApiRestCall_21625435
proc url_GetSuppressedDestination_21626252(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "EmailAddress" in path, "`EmailAddress` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/suppression/addresses/"),
               (kind: VariableSegment, value: "EmailAddress")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSuppressedDestination_21626251(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about a specific email address that's on the suppression list for your account.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EmailAddress: JString (required)
  ##               : The email address that's on the account suppression list.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `EmailAddress` field"
  var valid_21626253 = path.getOrDefault("EmailAddress")
  valid_21626253 = validateParameter(valid_21626253, JString, required = true,
                                   default = nil)
  if valid_21626253 != nil:
    section.add "EmailAddress", valid_21626253
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
  var valid_21626254 = header.getOrDefault("X-Amz-Date")
  valid_21626254 = validateParameter(valid_21626254, JString, required = false,
                                   default = nil)
  if valid_21626254 != nil:
    section.add "X-Amz-Date", valid_21626254
  var valid_21626255 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626255 = validateParameter(valid_21626255, JString, required = false,
                                   default = nil)
  if valid_21626255 != nil:
    section.add "X-Amz-Security-Token", valid_21626255
  var valid_21626256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626256 = validateParameter(valid_21626256, JString, required = false,
                                   default = nil)
  if valid_21626256 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626256
  var valid_21626257 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626257 = validateParameter(valid_21626257, JString, required = false,
                                   default = nil)
  if valid_21626257 != nil:
    section.add "X-Amz-Algorithm", valid_21626257
  var valid_21626258 = header.getOrDefault("X-Amz-Signature")
  valid_21626258 = validateParameter(valid_21626258, JString, required = false,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "X-Amz-Signature", valid_21626258
  var valid_21626259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626259 = validateParameter(valid_21626259, JString, required = false,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626259
  var valid_21626260 = header.getOrDefault("X-Amz-Credential")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "X-Amz-Credential", valid_21626260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626261: Call_GetSuppressedDestination_21626250;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a specific email address that's on the suppression list for your account.
  ## 
  let valid = call_21626261.validator(path, query, header, formData, body, _)
  let scheme = call_21626261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626261.makeUrl(scheme.get, call_21626261.host, call_21626261.base,
                               call_21626261.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626261, uri, valid, _)

proc call*(call_21626262: Call_GetSuppressedDestination_21626250;
          EmailAddress: string): Recallable =
  ## getSuppressedDestination
  ## Retrieves information about a specific email address that's on the suppression list for your account.
  ##   EmailAddress: string (required)
  ##               : The email address that's on the account suppression list.
  var path_21626263 = newJObject()
  add(path_21626263, "EmailAddress", newJString(EmailAddress))
  result = call_21626262.call(path_21626263, nil, nil, nil, nil)

var getSuppressedDestination* = Call_GetSuppressedDestination_21626250(
    name: "getSuppressedDestination", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v2/email/suppression/addresses/{EmailAddress}",
    validator: validate_GetSuppressedDestination_21626251, base: "/",
    makeUrl: url_GetSuppressedDestination_21626252,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSuppressedDestination_21626264 = ref object of OpenApiRestCall_21625435
proc url_DeleteSuppressedDestination_21626266(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "EmailAddress" in path, "`EmailAddress` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/suppression/addresses/"),
               (kind: VariableSegment, value: "EmailAddress")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteSuppressedDestination_21626265(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes an email address from the suppression list for your account.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EmailAddress: JString (required)
  ##               : The suppressed email destination to remove from the account suppression list.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `EmailAddress` field"
  var valid_21626267 = path.getOrDefault("EmailAddress")
  valid_21626267 = validateParameter(valid_21626267, JString, required = true,
                                   default = nil)
  if valid_21626267 != nil:
    section.add "EmailAddress", valid_21626267
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
  var valid_21626268 = header.getOrDefault("X-Amz-Date")
  valid_21626268 = validateParameter(valid_21626268, JString, required = false,
                                   default = nil)
  if valid_21626268 != nil:
    section.add "X-Amz-Date", valid_21626268
  var valid_21626269 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626269 = validateParameter(valid_21626269, JString, required = false,
                                   default = nil)
  if valid_21626269 != nil:
    section.add "X-Amz-Security-Token", valid_21626269
  var valid_21626270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626270 = validateParameter(valid_21626270, JString, required = false,
                                   default = nil)
  if valid_21626270 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626270
  var valid_21626271 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626271 = validateParameter(valid_21626271, JString, required = false,
                                   default = nil)
  if valid_21626271 != nil:
    section.add "X-Amz-Algorithm", valid_21626271
  var valid_21626272 = header.getOrDefault("X-Amz-Signature")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "X-Amz-Signature", valid_21626272
  var valid_21626273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626273 = validateParameter(valid_21626273, JString, required = false,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626273
  var valid_21626274 = header.getOrDefault("X-Amz-Credential")
  valid_21626274 = validateParameter(valid_21626274, JString, required = false,
                                   default = nil)
  if valid_21626274 != nil:
    section.add "X-Amz-Credential", valid_21626274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626275: Call_DeleteSuppressedDestination_21626264;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes an email address from the suppression list for your account.
  ## 
  let valid = call_21626275.validator(path, query, header, formData, body, _)
  let scheme = call_21626275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626275.makeUrl(scheme.get, call_21626275.host, call_21626275.base,
                               call_21626275.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626275, uri, valid, _)

proc call*(call_21626276: Call_DeleteSuppressedDestination_21626264;
          EmailAddress: string): Recallable =
  ## deleteSuppressedDestination
  ## Removes an email address from the suppression list for your account.
  ##   EmailAddress: string (required)
  ##               : The suppressed email destination to remove from the account suppression list.
  var path_21626277 = newJObject()
  add(path_21626277, "EmailAddress", newJString(EmailAddress))
  result = call_21626276.call(path_21626277, nil, nil, nil, nil)

var deleteSuppressedDestination* = Call_DeleteSuppressedDestination_21626264(
    name: "deleteSuppressedDestination", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com",
    route: "/v2/email/suppression/addresses/{EmailAddress}",
    validator: validate_DeleteSuppressedDestination_21626265, base: "/",
    makeUrl: url_DeleteSuppressedDestination_21626266,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccount_21626278 = ref object of OpenApiRestCall_21625435
proc url_GetAccount_21626280(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAccount_21626279(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Obtain information about the email-sending status and capabilities of your Amazon SES account in the current AWS Region.
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
  var valid_21626281 = header.getOrDefault("X-Amz-Date")
  valid_21626281 = validateParameter(valid_21626281, JString, required = false,
                                   default = nil)
  if valid_21626281 != nil:
    section.add "X-Amz-Date", valid_21626281
  var valid_21626282 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626282 = validateParameter(valid_21626282, JString, required = false,
                                   default = nil)
  if valid_21626282 != nil:
    section.add "X-Amz-Security-Token", valid_21626282
  var valid_21626283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626283 = validateParameter(valid_21626283, JString, required = false,
                                   default = nil)
  if valid_21626283 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626283
  var valid_21626284 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626284 = validateParameter(valid_21626284, JString, required = false,
                                   default = nil)
  if valid_21626284 != nil:
    section.add "X-Amz-Algorithm", valid_21626284
  var valid_21626285 = header.getOrDefault("X-Amz-Signature")
  valid_21626285 = validateParameter(valid_21626285, JString, required = false,
                                   default = nil)
  if valid_21626285 != nil:
    section.add "X-Amz-Signature", valid_21626285
  var valid_21626286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626286 = validateParameter(valid_21626286, JString, required = false,
                                   default = nil)
  if valid_21626286 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626286
  var valid_21626287 = header.getOrDefault("X-Amz-Credential")
  valid_21626287 = validateParameter(valid_21626287, JString, required = false,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "X-Amz-Credential", valid_21626287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626288: Call_GetAccount_21626278; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Obtain information about the email-sending status and capabilities of your Amazon SES account in the current AWS Region.
  ## 
  let valid = call_21626288.validator(path, query, header, formData, body, _)
  let scheme = call_21626288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626288.makeUrl(scheme.get, call_21626288.host, call_21626288.base,
                               call_21626288.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626288, uri, valid, _)

proc call*(call_21626289: Call_GetAccount_21626278): Recallable =
  ## getAccount
  ## Obtain information about the email-sending status and capabilities of your Amazon SES account in the current AWS Region.
  result = call_21626289.call(nil, nil, nil, nil, nil)

var getAccount* = Call_GetAccount_21626278(name: "getAccount",
                                        meth: HttpMethod.HttpGet,
                                        host: "email.amazonaws.com",
                                        route: "/v2/email/account",
                                        validator: validate_GetAccount_21626279,
                                        base: "/", makeUrl: url_GetAccount_21626280,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBlacklistReports_21626290 = ref object of OpenApiRestCall_21625435
proc url_GetBlacklistReports_21626292(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBlacklistReports_21626291(path: JsonNode; query: JsonNode;
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
  ##                     : A list of IP addresses that you want to retrieve blacklist information about. You can only specify the dedicated IP addresses that you use to send email using Amazon SES or Amazon Pinpoint.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `BlacklistItemNames` field"
  var valid_21626293 = query.getOrDefault("BlacklistItemNames")
  valid_21626293 = validateParameter(valid_21626293, JArray, required = true,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "BlacklistItemNames", valid_21626293
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626294 = header.getOrDefault("X-Amz-Date")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "X-Amz-Date", valid_21626294
  var valid_21626295 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626295 = validateParameter(valid_21626295, JString, required = false,
                                   default = nil)
  if valid_21626295 != nil:
    section.add "X-Amz-Security-Token", valid_21626295
  var valid_21626296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626296 = validateParameter(valid_21626296, JString, required = false,
                                   default = nil)
  if valid_21626296 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626296
  var valid_21626297 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626297 = validateParameter(valid_21626297, JString, required = false,
                                   default = nil)
  if valid_21626297 != nil:
    section.add "X-Amz-Algorithm", valid_21626297
  var valid_21626298 = header.getOrDefault("X-Amz-Signature")
  valid_21626298 = validateParameter(valid_21626298, JString, required = false,
                                   default = nil)
  if valid_21626298 != nil:
    section.add "X-Amz-Signature", valid_21626298
  var valid_21626299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626299 = validateParameter(valid_21626299, JString, required = false,
                                   default = nil)
  if valid_21626299 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626299
  var valid_21626300 = header.getOrDefault("X-Amz-Credential")
  valid_21626300 = validateParameter(valid_21626300, JString, required = false,
                                   default = nil)
  if valid_21626300 != nil:
    section.add "X-Amz-Credential", valid_21626300
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626301: Call_GetBlacklistReports_21626290; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve a list of the blacklists that your dedicated IP addresses appear on.
  ## 
  let valid = call_21626301.validator(path, query, header, formData, body, _)
  let scheme = call_21626301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626301.makeUrl(scheme.get, call_21626301.host, call_21626301.base,
                               call_21626301.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626301, uri, valid, _)

proc call*(call_21626302: Call_GetBlacklistReports_21626290;
          BlacklistItemNames: JsonNode): Recallable =
  ## getBlacklistReports
  ## Retrieve a list of the blacklists that your dedicated IP addresses appear on.
  ##   BlacklistItemNames: JArray (required)
  ##                     : A list of IP addresses that you want to retrieve blacklist information about. You can only specify the dedicated IP addresses that you use to send email using Amazon SES or Amazon Pinpoint.
  var query_21626303 = newJObject()
  if BlacklistItemNames != nil:
    query_21626303.add "BlacklistItemNames", BlacklistItemNames
  result = call_21626302.call(nil, query_21626303, nil, nil, nil)

var getBlacklistReports* = Call_GetBlacklistReports_21626290(
    name: "getBlacklistReports", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v2/email/deliverability-dashboard/blacklist-report#BlacklistItemNames",
    validator: validate_GetBlacklistReports_21626291, base: "/",
    makeUrl: url_GetBlacklistReports_21626292,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDedicatedIp_21626304 = ref object of OpenApiRestCall_21625435
proc url_GetDedicatedIp_21626306(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IP" in path, "`IP` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/dedicated-ips/"),
               (kind: VariableSegment, value: "IP")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDedicatedIp_21626305(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Get information about a dedicated IP address, including the name of the dedicated IP pool that it's associated with, as well information about the automatic warm-up process for the address.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IP: JString (required)
  ##     : An IPv4 address.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `IP` field"
  var valid_21626307 = path.getOrDefault("IP")
  valid_21626307 = validateParameter(valid_21626307, JString, required = true,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "IP", valid_21626307
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
  var valid_21626308 = header.getOrDefault("X-Amz-Date")
  valid_21626308 = validateParameter(valid_21626308, JString, required = false,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "X-Amz-Date", valid_21626308
  var valid_21626309 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-Security-Token", valid_21626309
  var valid_21626310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626310 = validateParameter(valid_21626310, JString, required = false,
                                   default = nil)
  if valid_21626310 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626310
  var valid_21626311 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626311 = validateParameter(valid_21626311, JString, required = false,
                                   default = nil)
  if valid_21626311 != nil:
    section.add "X-Amz-Algorithm", valid_21626311
  var valid_21626312 = header.getOrDefault("X-Amz-Signature")
  valid_21626312 = validateParameter(valid_21626312, JString, required = false,
                                   default = nil)
  if valid_21626312 != nil:
    section.add "X-Amz-Signature", valid_21626312
  var valid_21626313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626313 = validateParameter(valid_21626313, JString, required = false,
                                   default = nil)
  if valid_21626313 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626313
  var valid_21626314 = header.getOrDefault("X-Amz-Credential")
  valid_21626314 = validateParameter(valid_21626314, JString, required = false,
                                   default = nil)
  if valid_21626314 != nil:
    section.add "X-Amz-Credential", valid_21626314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626315: Call_GetDedicatedIp_21626304; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Get information about a dedicated IP address, including the name of the dedicated IP pool that it's associated with, as well information about the automatic warm-up process for the address.
  ## 
  let valid = call_21626315.validator(path, query, header, formData, body, _)
  let scheme = call_21626315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626315.makeUrl(scheme.get, call_21626315.host, call_21626315.base,
                               call_21626315.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626315, uri, valid, _)

proc call*(call_21626316: Call_GetDedicatedIp_21626304; IP: string): Recallable =
  ## getDedicatedIp
  ## Get information about a dedicated IP address, including the name of the dedicated IP pool that it's associated with, as well information about the automatic warm-up process for the address.
  ##   IP: string (required)
  ##     : An IPv4 address.
  var path_21626317 = newJObject()
  add(path_21626317, "IP", newJString(IP))
  result = call_21626316.call(path_21626317, nil, nil, nil, nil)

var getDedicatedIp* = Call_GetDedicatedIp_21626304(name: "getDedicatedIp",
    meth: HttpMethod.HttpGet, host: "email.amazonaws.com",
    route: "/v2/email/dedicated-ips/{IP}", validator: validate_GetDedicatedIp_21626305,
    base: "/", makeUrl: url_GetDedicatedIp_21626306,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDedicatedIps_21626318 = ref object of OpenApiRestCall_21625435
proc url_GetDedicatedIps_21626320(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDedicatedIps_21626319(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List the dedicated IP addresses that are associated with your AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JInt
  ##           : The number of results to show in a single call to <code>GetDedicatedIpsRequest</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   NextToken: JString
  ##            : A token returned from a previous call to <code>GetDedicatedIps</code> to indicate the position of the dedicated IP pool in the list of IP pools.
  ##   PoolName: JString
  ##           : The name of a dedicated IP pool.
  section = newJObject()
  var valid_21626321 = query.getOrDefault("PageSize")
  valid_21626321 = validateParameter(valid_21626321, JInt, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "PageSize", valid_21626321
  var valid_21626322 = query.getOrDefault("NextToken")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "NextToken", valid_21626322
  var valid_21626323 = query.getOrDefault("PoolName")
  valid_21626323 = validateParameter(valid_21626323, JString, required = false,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "PoolName", valid_21626323
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626324 = header.getOrDefault("X-Amz-Date")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "X-Amz-Date", valid_21626324
  var valid_21626325 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626325 = validateParameter(valid_21626325, JString, required = false,
                                   default = nil)
  if valid_21626325 != nil:
    section.add "X-Amz-Security-Token", valid_21626325
  var valid_21626326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626326 = validateParameter(valid_21626326, JString, required = false,
                                   default = nil)
  if valid_21626326 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626326
  var valid_21626327 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626327 = validateParameter(valid_21626327, JString, required = false,
                                   default = nil)
  if valid_21626327 != nil:
    section.add "X-Amz-Algorithm", valid_21626327
  var valid_21626328 = header.getOrDefault("X-Amz-Signature")
  valid_21626328 = validateParameter(valid_21626328, JString, required = false,
                                   default = nil)
  if valid_21626328 != nil:
    section.add "X-Amz-Signature", valid_21626328
  var valid_21626329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626329 = validateParameter(valid_21626329, JString, required = false,
                                   default = nil)
  if valid_21626329 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626329
  var valid_21626330 = header.getOrDefault("X-Amz-Credential")
  valid_21626330 = validateParameter(valid_21626330, JString, required = false,
                                   default = nil)
  if valid_21626330 != nil:
    section.add "X-Amz-Credential", valid_21626330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626331: Call_GetDedicatedIps_21626318; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## List the dedicated IP addresses that are associated with your AWS account.
  ## 
  let valid = call_21626331.validator(path, query, header, formData, body, _)
  let scheme = call_21626331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626331.makeUrl(scheme.get, call_21626331.host, call_21626331.base,
                               call_21626331.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626331, uri, valid, _)

proc call*(call_21626332: Call_GetDedicatedIps_21626318; PageSize: int = 0;
          NextToken: string = ""; PoolName: string = ""): Recallable =
  ## getDedicatedIps
  ## List the dedicated IP addresses that are associated with your AWS account.
  ##   PageSize: int
  ##           : The number of results to show in a single call to <code>GetDedicatedIpsRequest</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>GetDedicatedIps</code> to indicate the position of the dedicated IP pool in the list of IP pools.
  ##   PoolName: string
  ##           : The name of a dedicated IP pool.
  var query_21626333 = newJObject()
  add(query_21626333, "PageSize", newJInt(PageSize))
  add(query_21626333, "NextToken", newJString(NextToken))
  add(query_21626333, "PoolName", newJString(PoolName))
  result = call_21626332.call(nil, query_21626333, nil, nil, nil)

var getDedicatedIps* = Call_GetDedicatedIps_21626318(name: "getDedicatedIps",
    meth: HttpMethod.HttpGet, host: "email.amazonaws.com",
    route: "/v2/email/dedicated-ips", validator: validate_GetDedicatedIps_21626319,
    base: "/", makeUrl: url_GetDedicatedIps_21626320,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDeliverabilityDashboardOption_21626346 = ref object of OpenApiRestCall_21625435
proc url_PutDeliverabilityDashboardOption_21626348(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutDeliverabilityDashboardOption_21626347(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Enable or disable the Deliverability dashboard. When you enable the Deliverability dashboard, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon SES and other AWS services. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/ses/pricing/">Amazon SES Pricing</a>.</p>
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
  var valid_21626349 = header.getOrDefault("X-Amz-Date")
  valid_21626349 = validateParameter(valid_21626349, JString, required = false,
                                   default = nil)
  if valid_21626349 != nil:
    section.add "X-Amz-Date", valid_21626349
  var valid_21626350 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626350 = validateParameter(valid_21626350, JString, required = false,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "X-Amz-Security-Token", valid_21626350
  var valid_21626351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626351 = validateParameter(valid_21626351, JString, required = false,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626351
  var valid_21626352 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-Algorithm", valid_21626352
  var valid_21626353 = header.getOrDefault("X-Amz-Signature")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "X-Amz-Signature", valid_21626353
  var valid_21626354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626354 = validateParameter(valid_21626354, JString, required = false,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626354
  var valid_21626355 = header.getOrDefault("X-Amz-Credential")
  valid_21626355 = validateParameter(valid_21626355, JString, required = false,
                                   default = nil)
  if valid_21626355 != nil:
    section.add "X-Amz-Credential", valid_21626355
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

proc call*(call_21626357: Call_PutDeliverabilityDashboardOption_21626346;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Enable or disable the Deliverability dashboard. When you enable the Deliverability dashboard, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon SES and other AWS services. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/ses/pricing/">Amazon SES Pricing</a>.</p>
  ## 
  let valid = call_21626357.validator(path, query, header, formData, body, _)
  let scheme = call_21626357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626357.makeUrl(scheme.get, call_21626357.host, call_21626357.base,
                               call_21626357.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626357, uri, valid, _)

proc call*(call_21626358: Call_PutDeliverabilityDashboardOption_21626346;
          body: JsonNode): Recallable =
  ## putDeliverabilityDashboardOption
  ## <p>Enable or disable the Deliverability dashboard. When you enable the Deliverability dashboard, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon SES and other AWS services. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/ses/pricing/">Amazon SES Pricing</a>.</p>
  ##   body: JObject (required)
  var body_21626359 = newJObject()
  if body != nil:
    body_21626359 = body
  result = call_21626358.call(nil, nil, nil, nil, body_21626359)

var putDeliverabilityDashboardOption* = Call_PutDeliverabilityDashboardOption_21626346(
    name: "putDeliverabilityDashboardOption", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v2/email/deliverability-dashboard",
    validator: validate_PutDeliverabilityDashboardOption_21626347, base: "/",
    makeUrl: url_PutDeliverabilityDashboardOption_21626348,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeliverabilityDashboardOptions_21626334 = ref object of OpenApiRestCall_21625435
proc url_GetDeliverabilityDashboardOptions_21626336(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeliverabilityDashboardOptions_21626335(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Retrieve information about the status of the Deliverability dashboard for your account. When the Deliverability dashboard is enabled, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon SES and other AWS services. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/ses/pricing/">Amazon SES Pricing</a>.</p>
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
  var valid_21626337 = header.getOrDefault("X-Amz-Date")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-Date", valid_21626337
  var valid_21626338 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-Security-Token", valid_21626338
  var valid_21626339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626339
  var valid_21626340 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626340 = validateParameter(valid_21626340, JString, required = false,
                                   default = nil)
  if valid_21626340 != nil:
    section.add "X-Amz-Algorithm", valid_21626340
  var valid_21626341 = header.getOrDefault("X-Amz-Signature")
  valid_21626341 = validateParameter(valid_21626341, JString, required = false,
                                   default = nil)
  if valid_21626341 != nil:
    section.add "X-Amz-Signature", valid_21626341
  var valid_21626342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626342 = validateParameter(valid_21626342, JString, required = false,
                                   default = nil)
  if valid_21626342 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626342
  var valid_21626343 = header.getOrDefault("X-Amz-Credential")
  valid_21626343 = validateParameter(valid_21626343, JString, required = false,
                                   default = nil)
  if valid_21626343 != nil:
    section.add "X-Amz-Credential", valid_21626343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626344: Call_GetDeliverabilityDashboardOptions_21626334;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieve information about the status of the Deliverability dashboard for your account. When the Deliverability dashboard is enabled, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon SES and other AWS services. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/ses/pricing/">Amazon SES Pricing</a>.</p>
  ## 
  let valid = call_21626344.validator(path, query, header, formData, body, _)
  let scheme = call_21626344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626344.makeUrl(scheme.get, call_21626344.host, call_21626344.base,
                               call_21626344.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626344, uri, valid, _)

proc call*(call_21626345: Call_GetDeliverabilityDashboardOptions_21626334): Recallable =
  ## getDeliverabilityDashboardOptions
  ## <p>Retrieve information about the status of the Deliverability dashboard for your account. When the Deliverability dashboard is enabled, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon SES and other AWS services. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/ses/pricing/">Amazon SES Pricing</a>.</p>
  result = call_21626345.call(nil, nil, nil, nil, nil)

var getDeliverabilityDashboardOptions* = Call_GetDeliverabilityDashboardOptions_21626334(
    name: "getDeliverabilityDashboardOptions", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v2/email/deliverability-dashboard",
    validator: validate_GetDeliverabilityDashboardOptions_21626335, base: "/",
    makeUrl: url_GetDeliverabilityDashboardOptions_21626336,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeliverabilityTestReport_21626360 = ref object of OpenApiRestCall_21625435
proc url_GetDeliverabilityTestReport_21626362(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ReportId" in path, "`ReportId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/v2/email/deliverability-dashboard/test-reports/"),
               (kind: VariableSegment, value: "ReportId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDeliverabilityTestReport_21626361(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieve the results of a predictive inbox placement test.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ReportId: JString (required)
  ##           : A unique string that identifies a Deliverability dashboard report.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ReportId` field"
  var valid_21626363 = path.getOrDefault("ReportId")
  valid_21626363 = validateParameter(valid_21626363, JString, required = true,
                                   default = nil)
  if valid_21626363 != nil:
    section.add "ReportId", valid_21626363
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
  var valid_21626364 = header.getOrDefault("X-Amz-Date")
  valid_21626364 = validateParameter(valid_21626364, JString, required = false,
                                   default = nil)
  if valid_21626364 != nil:
    section.add "X-Amz-Date", valid_21626364
  var valid_21626365 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626365 = validateParameter(valid_21626365, JString, required = false,
                                   default = nil)
  if valid_21626365 != nil:
    section.add "X-Amz-Security-Token", valid_21626365
  var valid_21626366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626366 = validateParameter(valid_21626366, JString, required = false,
                                   default = nil)
  if valid_21626366 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626366
  var valid_21626367 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626367 = validateParameter(valid_21626367, JString, required = false,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "X-Amz-Algorithm", valid_21626367
  var valid_21626368 = header.getOrDefault("X-Amz-Signature")
  valid_21626368 = validateParameter(valid_21626368, JString, required = false,
                                   default = nil)
  if valid_21626368 != nil:
    section.add "X-Amz-Signature", valid_21626368
  var valid_21626369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626369 = validateParameter(valid_21626369, JString, required = false,
                                   default = nil)
  if valid_21626369 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626369
  var valid_21626370 = header.getOrDefault("X-Amz-Credential")
  valid_21626370 = validateParameter(valid_21626370, JString, required = false,
                                   default = nil)
  if valid_21626370 != nil:
    section.add "X-Amz-Credential", valid_21626370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626371: Call_GetDeliverabilityTestReport_21626360;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve the results of a predictive inbox placement test.
  ## 
  let valid = call_21626371.validator(path, query, header, formData, body, _)
  let scheme = call_21626371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626371.makeUrl(scheme.get, call_21626371.host, call_21626371.base,
                               call_21626371.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626371, uri, valid, _)

proc call*(call_21626372: Call_GetDeliverabilityTestReport_21626360;
          ReportId: string): Recallable =
  ## getDeliverabilityTestReport
  ## Retrieve the results of a predictive inbox placement test.
  ##   ReportId: string (required)
  ##           : A unique string that identifies a Deliverability dashboard report.
  var path_21626373 = newJObject()
  add(path_21626373, "ReportId", newJString(ReportId))
  result = call_21626372.call(path_21626373, nil, nil, nil, nil)

var getDeliverabilityTestReport* = Call_GetDeliverabilityTestReport_21626360(
    name: "getDeliverabilityTestReport", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v2/email/deliverability-dashboard/test-reports/{ReportId}",
    validator: validate_GetDeliverabilityTestReport_21626361, base: "/",
    makeUrl: url_GetDeliverabilityTestReport_21626362,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainDeliverabilityCampaign_21626374 = ref object of OpenApiRestCall_21625435
proc url_GetDomainDeliverabilityCampaign_21626376(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "CampaignId" in path, "`CampaignId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/v2/email/deliverability-dashboard/campaigns/"),
               (kind: VariableSegment, value: "CampaignId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDomainDeliverabilityCampaign_21626375(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieve all the deliverability data for a specific campaign. This data is available for a campaign only if the campaign sent email by using a domain that the Deliverability dashboard is enabled for.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   CampaignId: JString (required)
  ##             : The unique identifier for the campaign. The Deliverability dashboard automatically generates and assigns this identifier to a campaign.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `CampaignId` field"
  var valid_21626377 = path.getOrDefault("CampaignId")
  valid_21626377 = validateParameter(valid_21626377, JString, required = true,
                                   default = nil)
  if valid_21626377 != nil:
    section.add "CampaignId", valid_21626377
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
  var valid_21626378 = header.getOrDefault("X-Amz-Date")
  valid_21626378 = validateParameter(valid_21626378, JString, required = false,
                                   default = nil)
  if valid_21626378 != nil:
    section.add "X-Amz-Date", valid_21626378
  var valid_21626379 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626379 = validateParameter(valid_21626379, JString, required = false,
                                   default = nil)
  if valid_21626379 != nil:
    section.add "X-Amz-Security-Token", valid_21626379
  var valid_21626380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626380 = validateParameter(valid_21626380, JString, required = false,
                                   default = nil)
  if valid_21626380 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626380
  var valid_21626381 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626381 = validateParameter(valid_21626381, JString, required = false,
                                   default = nil)
  if valid_21626381 != nil:
    section.add "X-Amz-Algorithm", valid_21626381
  var valid_21626382 = header.getOrDefault("X-Amz-Signature")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "X-Amz-Signature", valid_21626382
  var valid_21626383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626383 = validateParameter(valid_21626383, JString, required = false,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626383
  var valid_21626384 = header.getOrDefault("X-Amz-Credential")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "X-Amz-Credential", valid_21626384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626385: Call_GetDomainDeliverabilityCampaign_21626374;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve all the deliverability data for a specific campaign. This data is available for a campaign only if the campaign sent email by using a domain that the Deliverability dashboard is enabled for.
  ## 
  let valid = call_21626385.validator(path, query, header, formData, body, _)
  let scheme = call_21626385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626385.makeUrl(scheme.get, call_21626385.host, call_21626385.base,
                               call_21626385.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626385, uri, valid, _)

proc call*(call_21626386: Call_GetDomainDeliverabilityCampaign_21626374;
          CampaignId: string): Recallable =
  ## getDomainDeliverabilityCampaign
  ## Retrieve all the deliverability data for a specific campaign. This data is available for a campaign only if the campaign sent email by using a domain that the Deliverability dashboard is enabled for.
  ##   CampaignId: string (required)
  ##             : The unique identifier for the campaign. The Deliverability dashboard automatically generates and assigns this identifier to a campaign.
  var path_21626387 = newJObject()
  add(path_21626387, "CampaignId", newJString(CampaignId))
  result = call_21626386.call(path_21626387, nil, nil, nil, nil)

var getDomainDeliverabilityCampaign* = Call_GetDomainDeliverabilityCampaign_21626374(
    name: "getDomainDeliverabilityCampaign", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v2/email/deliverability-dashboard/campaigns/{CampaignId}",
    validator: validate_GetDomainDeliverabilityCampaign_21626375, base: "/",
    makeUrl: url_GetDomainDeliverabilityCampaign_21626376,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainStatisticsReport_21626388 = ref object of OpenApiRestCall_21625435
proc url_GetDomainStatisticsReport_21626390(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Domain" in path, "`Domain` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/v2/email/deliverability-dashboard/statistics-report/"),
               (kind: VariableSegment, value: "Domain"),
               (kind: ConstantSegment, value: "#StartDate&EndDate")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDomainStatisticsReport_21626389(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieve inbox placement and engagement rates for the domains that you use to send email.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Domain: JString (required)
  ##         : The domain that you want to obtain deliverability metrics for.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Domain` field"
  var valid_21626391 = path.getOrDefault("Domain")
  valid_21626391 = validateParameter(valid_21626391, JString, required = true,
                                   default = nil)
  if valid_21626391 != nil:
    section.add "Domain", valid_21626391
  result.add "path", section
  ## parameters in `query` object:
  ##   EndDate: JString (required)
  ##          : The last day (in Unix time) that you want to obtain domain deliverability metrics for. The <code>EndDate</code> that you specify has to be less than or equal to 30 days after the <code>StartDate</code>.
  ##   StartDate: JString (required)
  ##            : The first day (in Unix time) that you want to obtain domain deliverability metrics for.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `EndDate` field"
  var valid_21626392 = query.getOrDefault("EndDate")
  valid_21626392 = validateParameter(valid_21626392, JString, required = true,
                                   default = nil)
  if valid_21626392 != nil:
    section.add "EndDate", valid_21626392
  var valid_21626393 = query.getOrDefault("StartDate")
  valid_21626393 = validateParameter(valid_21626393, JString, required = true,
                                   default = nil)
  if valid_21626393 != nil:
    section.add "StartDate", valid_21626393
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626394 = header.getOrDefault("X-Amz-Date")
  valid_21626394 = validateParameter(valid_21626394, JString, required = false,
                                   default = nil)
  if valid_21626394 != nil:
    section.add "X-Amz-Date", valid_21626394
  var valid_21626395 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626395 = validateParameter(valid_21626395, JString, required = false,
                                   default = nil)
  if valid_21626395 != nil:
    section.add "X-Amz-Security-Token", valid_21626395
  var valid_21626396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626396 = validateParameter(valid_21626396, JString, required = false,
                                   default = nil)
  if valid_21626396 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626396
  var valid_21626397 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "X-Amz-Algorithm", valid_21626397
  var valid_21626398 = header.getOrDefault("X-Amz-Signature")
  valid_21626398 = validateParameter(valid_21626398, JString, required = false,
                                   default = nil)
  if valid_21626398 != nil:
    section.add "X-Amz-Signature", valid_21626398
  var valid_21626399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626399 = validateParameter(valid_21626399, JString, required = false,
                                   default = nil)
  if valid_21626399 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626399
  var valid_21626400 = header.getOrDefault("X-Amz-Credential")
  valid_21626400 = validateParameter(valid_21626400, JString, required = false,
                                   default = nil)
  if valid_21626400 != nil:
    section.add "X-Amz-Credential", valid_21626400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626401: Call_GetDomainStatisticsReport_21626388;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve inbox placement and engagement rates for the domains that you use to send email.
  ## 
  let valid = call_21626401.validator(path, query, header, formData, body, _)
  let scheme = call_21626401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626401.makeUrl(scheme.get, call_21626401.host, call_21626401.base,
                               call_21626401.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626401, uri, valid, _)

proc call*(call_21626402: Call_GetDomainStatisticsReport_21626388; Domain: string;
          EndDate: string; StartDate: string): Recallable =
  ## getDomainStatisticsReport
  ## Retrieve inbox placement and engagement rates for the domains that you use to send email.
  ##   Domain: string (required)
  ##         : The domain that you want to obtain deliverability metrics for.
  ##   EndDate: string (required)
  ##          : The last day (in Unix time) that you want to obtain domain deliverability metrics for. The <code>EndDate</code> that you specify has to be less than or equal to 30 days after the <code>StartDate</code>.
  ##   StartDate: string (required)
  ##            : The first day (in Unix time) that you want to obtain domain deliverability metrics for.
  var path_21626403 = newJObject()
  var query_21626404 = newJObject()
  add(path_21626403, "Domain", newJString(Domain))
  add(query_21626404, "EndDate", newJString(EndDate))
  add(query_21626404, "StartDate", newJString(StartDate))
  result = call_21626402.call(path_21626403, query_21626404, nil, nil, nil)

var getDomainStatisticsReport* = Call_GetDomainStatisticsReport_21626388(
    name: "getDomainStatisticsReport", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v2/email/deliverability-dashboard/statistics-report/{Domain}#StartDate&EndDate",
    validator: validate_GetDomainStatisticsReport_21626389, base: "/",
    makeUrl: url_GetDomainStatisticsReport_21626390,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeliverabilityTestReports_21626405 = ref object of OpenApiRestCall_21625435
proc url_ListDeliverabilityTestReports_21626407(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDeliverabilityTestReports_21626406(path: JsonNode;
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
  ##   NextToken: JString
  ##            : A token returned from a previous call to <code>ListDeliverabilityTestReports</code> to indicate the position in the list of predictive inbox placement tests.
  section = newJObject()
  var valid_21626408 = query.getOrDefault("PageSize")
  valid_21626408 = validateParameter(valid_21626408, JInt, required = false,
                                   default = nil)
  if valid_21626408 != nil:
    section.add "PageSize", valid_21626408
  var valid_21626409 = query.getOrDefault("NextToken")
  valid_21626409 = validateParameter(valid_21626409, JString, required = false,
                                   default = nil)
  if valid_21626409 != nil:
    section.add "NextToken", valid_21626409
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626410 = header.getOrDefault("X-Amz-Date")
  valid_21626410 = validateParameter(valid_21626410, JString, required = false,
                                   default = nil)
  if valid_21626410 != nil:
    section.add "X-Amz-Date", valid_21626410
  var valid_21626411 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626411 = validateParameter(valid_21626411, JString, required = false,
                                   default = nil)
  if valid_21626411 != nil:
    section.add "X-Amz-Security-Token", valid_21626411
  var valid_21626412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626412 = validateParameter(valid_21626412, JString, required = false,
                                   default = nil)
  if valid_21626412 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626412
  var valid_21626413 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626413 = validateParameter(valid_21626413, JString, required = false,
                                   default = nil)
  if valid_21626413 != nil:
    section.add "X-Amz-Algorithm", valid_21626413
  var valid_21626414 = header.getOrDefault("X-Amz-Signature")
  valid_21626414 = validateParameter(valid_21626414, JString, required = false,
                                   default = nil)
  if valid_21626414 != nil:
    section.add "X-Amz-Signature", valid_21626414
  var valid_21626415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626415 = validateParameter(valid_21626415, JString, required = false,
                                   default = nil)
  if valid_21626415 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626415
  var valid_21626416 = header.getOrDefault("X-Amz-Credential")
  valid_21626416 = validateParameter(valid_21626416, JString, required = false,
                                   default = nil)
  if valid_21626416 != nil:
    section.add "X-Amz-Credential", valid_21626416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626417: Call_ListDeliverabilityTestReports_21626405;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Show a list of the predictive inbox placement tests that you've performed, regardless of their statuses. For predictive inbox placement tests that are complete, you can use the <code>GetDeliverabilityTestReport</code> operation to view the results.
  ## 
  let valid = call_21626417.validator(path, query, header, formData, body, _)
  let scheme = call_21626417.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626417.makeUrl(scheme.get, call_21626417.host, call_21626417.base,
                               call_21626417.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626417, uri, valid, _)

proc call*(call_21626418: Call_ListDeliverabilityTestReports_21626405;
          PageSize: int = 0; NextToken: string = ""): Recallable =
  ## listDeliverabilityTestReports
  ## Show a list of the predictive inbox placement tests that you've performed, regardless of their statuses. For predictive inbox placement tests that are complete, you can use the <code>GetDeliverabilityTestReport</code> operation to view the results.
  ##   PageSize: int
  ##           : <p>The number of results to show in a single call to <code>ListDeliverabilityTestReports</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.</p> <p>The value you specify has to be at least 0, and can be no more than 1000.</p>
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>ListDeliverabilityTestReports</code> to indicate the position in the list of predictive inbox placement tests.
  var query_21626419 = newJObject()
  add(query_21626419, "PageSize", newJInt(PageSize))
  add(query_21626419, "NextToken", newJString(NextToken))
  result = call_21626418.call(nil, query_21626419, nil, nil, nil)

var listDeliverabilityTestReports* = Call_ListDeliverabilityTestReports_21626405(
    name: "listDeliverabilityTestReports", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v2/email/deliverability-dashboard/test-reports",
    validator: validate_ListDeliverabilityTestReports_21626406, base: "/",
    makeUrl: url_ListDeliverabilityTestReports_21626407,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomainDeliverabilityCampaigns_21626420 = ref object of OpenApiRestCall_21625435
proc url_ListDomainDeliverabilityCampaigns_21626422(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "SubscribedDomain" in path,
        "`SubscribedDomain` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/v2/email/deliverability-dashboard/domains/"),
               (kind: VariableSegment, value: "SubscribedDomain"),
               (kind: ConstantSegment, value: "/campaigns#StartDate&EndDate")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDomainDeliverabilityCampaigns_21626421(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieve deliverability data for all the campaigns that used a specific domain to send email during a specified time range. This data is available for a domain only if you enabled the Deliverability dashboard for the domain.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   SubscribedDomain: JString (required)
  ##                   : The domain to obtain deliverability data for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `SubscribedDomain` field"
  var valid_21626423 = path.getOrDefault("SubscribedDomain")
  valid_21626423 = validateParameter(valid_21626423, JString, required = true,
                                   default = nil)
  if valid_21626423 != nil:
    section.add "SubscribedDomain", valid_21626423
  result.add "path", section
  ## parameters in `query` object:
  ##   EndDate: JString (required)
  ##          : The last day, in Unix time format, that you want to obtain deliverability data for. This value has to be less than or equal to 30 days after the value of the <code>StartDate</code> parameter.
  ##   PageSize: JInt
  ##           : The maximum number of results to include in response to a single call to the <code>ListDomainDeliverabilityCampaigns</code> operation. If the number of results is larger than the number that you specify in this parameter, the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   NextToken: JString
  ##            : A token that’s returned from a previous call to the <code>ListDomainDeliverabilityCampaigns</code> operation. This token indicates the position of a campaign in the list of campaigns.
  ##   StartDate: JString (required)
  ##            : The first day, in Unix time format, that you want to obtain deliverability data for.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `EndDate` field"
  var valid_21626424 = query.getOrDefault("EndDate")
  valid_21626424 = validateParameter(valid_21626424, JString, required = true,
                                   default = nil)
  if valid_21626424 != nil:
    section.add "EndDate", valid_21626424
  var valid_21626425 = query.getOrDefault("PageSize")
  valid_21626425 = validateParameter(valid_21626425, JInt, required = false,
                                   default = nil)
  if valid_21626425 != nil:
    section.add "PageSize", valid_21626425
  var valid_21626426 = query.getOrDefault("NextToken")
  valid_21626426 = validateParameter(valid_21626426, JString, required = false,
                                   default = nil)
  if valid_21626426 != nil:
    section.add "NextToken", valid_21626426
  var valid_21626427 = query.getOrDefault("StartDate")
  valid_21626427 = validateParameter(valid_21626427, JString, required = true,
                                   default = nil)
  if valid_21626427 != nil:
    section.add "StartDate", valid_21626427
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626428 = header.getOrDefault("X-Amz-Date")
  valid_21626428 = validateParameter(valid_21626428, JString, required = false,
                                   default = nil)
  if valid_21626428 != nil:
    section.add "X-Amz-Date", valid_21626428
  var valid_21626429 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626429 = validateParameter(valid_21626429, JString, required = false,
                                   default = nil)
  if valid_21626429 != nil:
    section.add "X-Amz-Security-Token", valid_21626429
  var valid_21626430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626430 = validateParameter(valid_21626430, JString, required = false,
                                   default = nil)
  if valid_21626430 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626430
  var valid_21626431 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626431 = validateParameter(valid_21626431, JString, required = false,
                                   default = nil)
  if valid_21626431 != nil:
    section.add "X-Amz-Algorithm", valid_21626431
  var valid_21626432 = header.getOrDefault("X-Amz-Signature")
  valid_21626432 = validateParameter(valid_21626432, JString, required = false,
                                   default = nil)
  if valid_21626432 != nil:
    section.add "X-Amz-Signature", valid_21626432
  var valid_21626433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626433 = validateParameter(valid_21626433, JString, required = false,
                                   default = nil)
  if valid_21626433 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626433
  var valid_21626434 = header.getOrDefault("X-Amz-Credential")
  valid_21626434 = validateParameter(valid_21626434, JString, required = false,
                                   default = nil)
  if valid_21626434 != nil:
    section.add "X-Amz-Credential", valid_21626434
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626435: Call_ListDomainDeliverabilityCampaigns_21626420;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve deliverability data for all the campaigns that used a specific domain to send email during a specified time range. This data is available for a domain only if you enabled the Deliverability dashboard for the domain.
  ## 
  let valid = call_21626435.validator(path, query, header, formData, body, _)
  let scheme = call_21626435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626435.makeUrl(scheme.get, call_21626435.host, call_21626435.base,
                               call_21626435.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626435, uri, valid, _)

proc call*(call_21626436: Call_ListDomainDeliverabilityCampaigns_21626420;
          EndDate: string; SubscribedDomain: string; StartDate: string;
          PageSize: int = 0; NextToken: string = ""): Recallable =
  ## listDomainDeliverabilityCampaigns
  ## Retrieve deliverability data for all the campaigns that used a specific domain to send email during a specified time range. This data is available for a domain only if you enabled the Deliverability dashboard for the domain.
  ##   EndDate: string (required)
  ##          : The last day, in Unix time format, that you want to obtain deliverability data for. This value has to be less than or equal to 30 days after the value of the <code>StartDate</code> parameter.
  ##   PageSize: int
  ##           : The maximum number of results to include in response to a single call to the <code>ListDomainDeliverabilityCampaigns</code> operation. If the number of results is larger than the number that you specify in this parameter, the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   NextToken: string
  ##            : A token that’s returned from a previous call to the <code>ListDomainDeliverabilityCampaigns</code> operation. This token indicates the position of a campaign in the list of campaigns.
  ##   SubscribedDomain: string (required)
  ##                   : The domain to obtain deliverability data for.
  ##   StartDate: string (required)
  ##            : The first day, in Unix time format, that you want to obtain deliverability data for.
  var path_21626437 = newJObject()
  var query_21626438 = newJObject()
  add(query_21626438, "EndDate", newJString(EndDate))
  add(query_21626438, "PageSize", newJInt(PageSize))
  add(query_21626438, "NextToken", newJString(NextToken))
  add(path_21626437, "SubscribedDomain", newJString(SubscribedDomain))
  add(query_21626438, "StartDate", newJString(StartDate))
  result = call_21626436.call(path_21626437, query_21626438, nil, nil, nil)

var listDomainDeliverabilityCampaigns* = Call_ListDomainDeliverabilityCampaigns_21626420(
    name: "listDomainDeliverabilityCampaigns", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v2/email/deliverability-dashboard/domains/{SubscribedDomain}/campaigns#StartDate&EndDate",
    validator: validate_ListDomainDeliverabilityCampaigns_21626421, base: "/",
    makeUrl: url_ListDomainDeliverabilityCampaigns_21626422,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutSuppressedDestination_21626457 = ref object of OpenApiRestCall_21625435
proc url_PutSuppressedDestination_21626459(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutSuppressedDestination_21626458(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Adds an email address to the suppression list for your account.
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
  var valid_21626460 = header.getOrDefault("X-Amz-Date")
  valid_21626460 = validateParameter(valid_21626460, JString, required = false,
                                   default = nil)
  if valid_21626460 != nil:
    section.add "X-Amz-Date", valid_21626460
  var valid_21626461 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626461 = validateParameter(valid_21626461, JString, required = false,
                                   default = nil)
  if valid_21626461 != nil:
    section.add "X-Amz-Security-Token", valid_21626461
  var valid_21626462 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626462 = validateParameter(valid_21626462, JString, required = false,
                                   default = nil)
  if valid_21626462 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626462
  var valid_21626463 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626463 = validateParameter(valid_21626463, JString, required = false,
                                   default = nil)
  if valid_21626463 != nil:
    section.add "X-Amz-Algorithm", valid_21626463
  var valid_21626464 = header.getOrDefault("X-Amz-Signature")
  valid_21626464 = validateParameter(valid_21626464, JString, required = false,
                                   default = nil)
  if valid_21626464 != nil:
    section.add "X-Amz-Signature", valid_21626464
  var valid_21626465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626465 = validateParameter(valid_21626465, JString, required = false,
                                   default = nil)
  if valid_21626465 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626465
  var valid_21626466 = header.getOrDefault("X-Amz-Credential")
  valid_21626466 = validateParameter(valid_21626466, JString, required = false,
                                   default = nil)
  if valid_21626466 != nil:
    section.add "X-Amz-Credential", valid_21626466
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

proc call*(call_21626468: Call_PutSuppressedDestination_21626457;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds an email address to the suppression list for your account.
  ## 
  let valid = call_21626468.validator(path, query, header, formData, body, _)
  let scheme = call_21626468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626468.makeUrl(scheme.get, call_21626468.host, call_21626468.base,
                               call_21626468.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626468, uri, valid, _)

proc call*(call_21626469: Call_PutSuppressedDestination_21626457; body: JsonNode): Recallable =
  ## putSuppressedDestination
  ## Adds an email address to the suppression list for your account.
  ##   body: JObject (required)
  var body_21626470 = newJObject()
  if body != nil:
    body_21626470 = body
  result = call_21626469.call(nil, nil, nil, nil, body_21626470)

var putSuppressedDestination* = Call_PutSuppressedDestination_21626457(
    name: "putSuppressedDestination", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v2/email/suppression/addresses",
    validator: validate_PutSuppressedDestination_21626458, base: "/",
    makeUrl: url_PutSuppressedDestination_21626459,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSuppressedDestinations_21626439 = ref object of OpenApiRestCall_21625435
proc url_ListSuppressedDestinations_21626441(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSuppressedDestinations_21626440(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a list of email addresses that are on the suppression list for your account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Reason: JArray
  ##         : The factors that caused the email address to be added to .
  ##   EndDate: JString
  ##          : Used to filter the list of suppressed email destinations so that it only includes addresses that were added to the list before a specific date. The date that you specify should be in Unix time format.
  ##   PageSize: JInt
  ##           : The number of results to show in a single call to <code>ListSuppressedDestinations</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   NextToken: JString
  ##            : A token returned from a previous call to <code>ListSuppressedDestinations</code> to indicate the position in the list of suppressed email addresses.
  ##   StartDate: JString
  ##            : Used to filter the list of suppressed email destinations so that it only includes addresses that were added to the list after a specific date. The date that you specify should be in Unix time format.
  section = newJObject()
  var valid_21626442 = query.getOrDefault("Reason")
  valid_21626442 = validateParameter(valid_21626442, JArray, required = false,
                                   default = nil)
  if valid_21626442 != nil:
    section.add "Reason", valid_21626442
  var valid_21626443 = query.getOrDefault("EndDate")
  valid_21626443 = validateParameter(valid_21626443, JString, required = false,
                                   default = nil)
  if valid_21626443 != nil:
    section.add "EndDate", valid_21626443
  var valid_21626444 = query.getOrDefault("PageSize")
  valid_21626444 = validateParameter(valid_21626444, JInt, required = false,
                                   default = nil)
  if valid_21626444 != nil:
    section.add "PageSize", valid_21626444
  var valid_21626445 = query.getOrDefault("NextToken")
  valid_21626445 = validateParameter(valid_21626445, JString, required = false,
                                   default = nil)
  if valid_21626445 != nil:
    section.add "NextToken", valid_21626445
  var valid_21626446 = query.getOrDefault("StartDate")
  valid_21626446 = validateParameter(valid_21626446, JString, required = false,
                                   default = nil)
  if valid_21626446 != nil:
    section.add "StartDate", valid_21626446
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626447 = header.getOrDefault("X-Amz-Date")
  valid_21626447 = validateParameter(valid_21626447, JString, required = false,
                                   default = nil)
  if valid_21626447 != nil:
    section.add "X-Amz-Date", valid_21626447
  var valid_21626448 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626448 = validateParameter(valid_21626448, JString, required = false,
                                   default = nil)
  if valid_21626448 != nil:
    section.add "X-Amz-Security-Token", valid_21626448
  var valid_21626449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626449 = validateParameter(valid_21626449, JString, required = false,
                                   default = nil)
  if valid_21626449 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626449
  var valid_21626450 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626450 = validateParameter(valid_21626450, JString, required = false,
                                   default = nil)
  if valid_21626450 != nil:
    section.add "X-Amz-Algorithm", valid_21626450
  var valid_21626451 = header.getOrDefault("X-Amz-Signature")
  valid_21626451 = validateParameter(valid_21626451, JString, required = false,
                                   default = nil)
  if valid_21626451 != nil:
    section.add "X-Amz-Signature", valid_21626451
  var valid_21626452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626452 = validateParameter(valid_21626452, JString, required = false,
                                   default = nil)
  if valid_21626452 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626452
  var valid_21626453 = header.getOrDefault("X-Amz-Credential")
  valid_21626453 = validateParameter(valid_21626453, JString, required = false,
                                   default = nil)
  if valid_21626453 != nil:
    section.add "X-Amz-Credential", valid_21626453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626454: Call_ListSuppressedDestinations_21626439;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of email addresses that are on the suppression list for your account.
  ## 
  let valid = call_21626454.validator(path, query, header, formData, body, _)
  let scheme = call_21626454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626454.makeUrl(scheme.get, call_21626454.host, call_21626454.base,
                               call_21626454.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626454, uri, valid, _)

proc call*(call_21626455: Call_ListSuppressedDestinations_21626439;
          Reason: JsonNode = nil; EndDate: string = ""; PageSize: int = 0;
          NextToken: string = ""; StartDate: string = ""): Recallable =
  ## listSuppressedDestinations
  ## Retrieves a list of email addresses that are on the suppression list for your account.
  ##   Reason: JArray
  ##         : The factors that caused the email address to be added to .
  ##   EndDate: string
  ##          : Used to filter the list of suppressed email destinations so that it only includes addresses that were added to the list before a specific date. The date that you specify should be in Unix time format.
  ##   PageSize: int
  ##           : The number of results to show in a single call to <code>ListSuppressedDestinations</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>ListSuppressedDestinations</code> to indicate the position in the list of suppressed email addresses.
  ##   StartDate: string
  ##            : Used to filter the list of suppressed email destinations so that it only includes addresses that were added to the list after a specific date. The date that you specify should be in Unix time format.
  var query_21626456 = newJObject()
  if Reason != nil:
    query_21626456.add "Reason", Reason
  add(query_21626456, "EndDate", newJString(EndDate))
  add(query_21626456, "PageSize", newJInt(PageSize))
  add(query_21626456, "NextToken", newJString(NextToken))
  add(query_21626456, "StartDate", newJString(StartDate))
  result = call_21626455.call(nil, query_21626456, nil, nil, nil)

var listSuppressedDestinations* = Call_ListSuppressedDestinations_21626439(
    name: "listSuppressedDestinations", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v2/email/suppression/addresses",
    validator: validate_ListSuppressedDestinations_21626440, base: "/",
    makeUrl: url_ListSuppressedDestinations_21626441,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21626471 = ref object of OpenApiRestCall_21625435
proc url_ListTagsForResource_21626473(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_21626472(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieve a list of the tags (keys and values) that are associated with a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource. Each tag consists of a required <i>tag key</i> and an optional associated <i>tag value</i>. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.
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
  var valid_21626474 = query.getOrDefault("ResourceArn")
  valid_21626474 = validateParameter(valid_21626474, JString, required = true,
                                   default = nil)
  if valid_21626474 != nil:
    section.add "ResourceArn", valid_21626474
  result.add "query", section
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

proc call*(call_21626482: Call_ListTagsForResource_21626471; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve a list of the tags (keys and values) that are associated with a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource. Each tag consists of a required <i>tag key</i> and an optional associated <i>tag value</i>. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.
  ## 
  let valid = call_21626482.validator(path, query, header, formData, body, _)
  let scheme = call_21626482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626482.makeUrl(scheme.get, call_21626482.host, call_21626482.base,
                               call_21626482.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626482, uri, valid, _)

proc call*(call_21626483: Call_ListTagsForResource_21626471; ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieve a list of the tags (keys and values) that are associated with a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource. Each tag consists of a required <i>tag key</i> and an optional associated <i>tag value</i>. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to retrieve tag information for.
  var query_21626484 = newJObject()
  add(query_21626484, "ResourceArn", newJString(ResourceArn))
  result = call_21626483.call(nil, query_21626484, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_21626471(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v2/email/tags#ResourceArn",
    validator: validate_ListTagsForResource_21626472, base: "/",
    makeUrl: url_ListTagsForResource_21626473,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAccountDedicatedIpWarmupAttributes_21626485 = ref object of OpenApiRestCall_21625435
proc url_PutAccountDedicatedIpWarmupAttributes_21626487(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutAccountDedicatedIpWarmupAttributes_21626486(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626488 = header.getOrDefault("X-Amz-Date")
  valid_21626488 = validateParameter(valid_21626488, JString, required = false,
                                   default = nil)
  if valid_21626488 != nil:
    section.add "X-Amz-Date", valid_21626488
  var valid_21626489 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626489 = validateParameter(valid_21626489, JString, required = false,
                                   default = nil)
  if valid_21626489 != nil:
    section.add "X-Amz-Security-Token", valid_21626489
  var valid_21626490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626490 = validateParameter(valid_21626490, JString, required = false,
                                   default = nil)
  if valid_21626490 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626490
  var valid_21626491 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626491 = validateParameter(valid_21626491, JString, required = false,
                                   default = nil)
  if valid_21626491 != nil:
    section.add "X-Amz-Algorithm", valid_21626491
  var valid_21626492 = header.getOrDefault("X-Amz-Signature")
  valid_21626492 = validateParameter(valid_21626492, JString, required = false,
                                   default = nil)
  if valid_21626492 != nil:
    section.add "X-Amz-Signature", valid_21626492
  var valid_21626493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626493 = validateParameter(valid_21626493, JString, required = false,
                                   default = nil)
  if valid_21626493 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626493
  var valid_21626494 = header.getOrDefault("X-Amz-Credential")
  valid_21626494 = validateParameter(valid_21626494, JString, required = false,
                                   default = nil)
  if valid_21626494 != nil:
    section.add "X-Amz-Credential", valid_21626494
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

proc call*(call_21626496: Call_PutAccountDedicatedIpWarmupAttributes_21626485;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Enable or disable the automatic warm-up feature for dedicated IP addresses.
  ## 
  let valid = call_21626496.validator(path, query, header, formData, body, _)
  let scheme = call_21626496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626496.makeUrl(scheme.get, call_21626496.host, call_21626496.base,
                               call_21626496.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626496, uri, valid, _)

proc call*(call_21626497: Call_PutAccountDedicatedIpWarmupAttributes_21626485;
          body: JsonNode): Recallable =
  ## putAccountDedicatedIpWarmupAttributes
  ## Enable or disable the automatic warm-up feature for dedicated IP addresses.
  ##   body: JObject (required)
  var body_21626498 = newJObject()
  if body != nil:
    body_21626498 = body
  result = call_21626497.call(nil, nil, nil, nil, body_21626498)

var putAccountDedicatedIpWarmupAttributes* = Call_PutAccountDedicatedIpWarmupAttributes_21626485(
    name: "putAccountDedicatedIpWarmupAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v2/email/account/dedicated-ips/warmup",
    validator: validate_PutAccountDedicatedIpWarmupAttributes_21626486, base: "/",
    makeUrl: url_PutAccountDedicatedIpWarmupAttributes_21626487,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAccountSendingAttributes_21626499 = ref object of OpenApiRestCall_21625435
proc url_PutAccountSendingAttributes_21626501(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutAccountSendingAttributes_21626500(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Enable or disable the ability of your account to send email.
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
  var valid_21626502 = header.getOrDefault("X-Amz-Date")
  valid_21626502 = validateParameter(valid_21626502, JString, required = false,
                                   default = nil)
  if valid_21626502 != nil:
    section.add "X-Amz-Date", valid_21626502
  var valid_21626503 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626503 = validateParameter(valid_21626503, JString, required = false,
                                   default = nil)
  if valid_21626503 != nil:
    section.add "X-Amz-Security-Token", valid_21626503
  var valid_21626504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626504 = validateParameter(valid_21626504, JString, required = false,
                                   default = nil)
  if valid_21626504 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626504
  var valid_21626505 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626505 = validateParameter(valid_21626505, JString, required = false,
                                   default = nil)
  if valid_21626505 != nil:
    section.add "X-Amz-Algorithm", valid_21626505
  var valid_21626506 = header.getOrDefault("X-Amz-Signature")
  valid_21626506 = validateParameter(valid_21626506, JString, required = false,
                                   default = nil)
  if valid_21626506 != nil:
    section.add "X-Amz-Signature", valid_21626506
  var valid_21626507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626507 = validateParameter(valid_21626507, JString, required = false,
                                   default = nil)
  if valid_21626507 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626507
  var valid_21626508 = header.getOrDefault("X-Amz-Credential")
  valid_21626508 = validateParameter(valid_21626508, JString, required = false,
                                   default = nil)
  if valid_21626508 != nil:
    section.add "X-Amz-Credential", valid_21626508
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

proc call*(call_21626510: Call_PutAccountSendingAttributes_21626499;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Enable or disable the ability of your account to send email.
  ## 
  let valid = call_21626510.validator(path, query, header, formData, body, _)
  let scheme = call_21626510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626510.makeUrl(scheme.get, call_21626510.host, call_21626510.base,
                               call_21626510.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626510, uri, valid, _)

proc call*(call_21626511: Call_PutAccountSendingAttributes_21626499; body: JsonNode): Recallable =
  ## putAccountSendingAttributes
  ## Enable or disable the ability of your account to send email.
  ##   body: JObject (required)
  var body_21626512 = newJObject()
  if body != nil:
    body_21626512 = body
  result = call_21626511.call(nil, nil, nil, nil, body_21626512)

var putAccountSendingAttributes* = Call_PutAccountSendingAttributes_21626499(
    name: "putAccountSendingAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v2/email/account/sending",
    validator: validate_PutAccountSendingAttributes_21626500, base: "/",
    makeUrl: url_PutAccountSendingAttributes_21626501,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAccountSuppressionAttributes_21626513 = ref object of OpenApiRestCall_21625435
proc url_PutAccountSuppressionAttributes_21626515(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutAccountSuppressionAttributes_21626514(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Change the settings for the account-level suppression list.
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
  var valid_21626516 = header.getOrDefault("X-Amz-Date")
  valid_21626516 = validateParameter(valid_21626516, JString, required = false,
                                   default = nil)
  if valid_21626516 != nil:
    section.add "X-Amz-Date", valid_21626516
  var valid_21626517 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626517 = validateParameter(valid_21626517, JString, required = false,
                                   default = nil)
  if valid_21626517 != nil:
    section.add "X-Amz-Security-Token", valid_21626517
  var valid_21626518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626518 = validateParameter(valid_21626518, JString, required = false,
                                   default = nil)
  if valid_21626518 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626518
  var valid_21626519 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626519 = validateParameter(valid_21626519, JString, required = false,
                                   default = nil)
  if valid_21626519 != nil:
    section.add "X-Amz-Algorithm", valid_21626519
  var valid_21626520 = header.getOrDefault("X-Amz-Signature")
  valid_21626520 = validateParameter(valid_21626520, JString, required = false,
                                   default = nil)
  if valid_21626520 != nil:
    section.add "X-Amz-Signature", valid_21626520
  var valid_21626521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626521 = validateParameter(valid_21626521, JString, required = false,
                                   default = nil)
  if valid_21626521 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626521
  var valid_21626522 = header.getOrDefault("X-Amz-Credential")
  valid_21626522 = validateParameter(valid_21626522, JString, required = false,
                                   default = nil)
  if valid_21626522 != nil:
    section.add "X-Amz-Credential", valid_21626522
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

proc call*(call_21626524: Call_PutAccountSuppressionAttributes_21626513;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Change the settings for the account-level suppression list.
  ## 
  let valid = call_21626524.validator(path, query, header, formData, body, _)
  let scheme = call_21626524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626524.makeUrl(scheme.get, call_21626524.host, call_21626524.base,
                               call_21626524.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626524, uri, valid, _)

proc call*(call_21626525: Call_PutAccountSuppressionAttributes_21626513;
          body: JsonNode): Recallable =
  ## putAccountSuppressionAttributes
  ## Change the settings for the account-level suppression list.
  ##   body: JObject (required)
  var body_21626526 = newJObject()
  if body != nil:
    body_21626526 = body
  result = call_21626525.call(nil, nil, nil, nil, body_21626526)

var putAccountSuppressionAttributes* = Call_PutAccountSuppressionAttributes_21626513(
    name: "putAccountSuppressionAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v2/email/account/suppression",
    validator: validate_PutAccountSuppressionAttributes_21626514, base: "/",
    makeUrl: url_PutAccountSuppressionAttributes_21626515,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetDeliveryOptions_21626527 = ref object of OpenApiRestCall_21625435
proc url_PutConfigurationSetDeliveryOptions_21626529(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/delivery-options")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutConfigurationSetDeliveryOptions_21626528(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Associate a configuration set with a dedicated IP pool. You can use dedicated IP pools to create groups of dedicated IP addresses for sending specific types of email.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_21626530 = path.getOrDefault("ConfigurationSetName")
  valid_21626530 = validateParameter(valid_21626530, JString, required = true,
                                   default = nil)
  if valid_21626530 != nil:
    section.add "ConfigurationSetName", valid_21626530
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
  var valid_21626531 = header.getOrDefault("X-Amz-Date")
  valid_21626531 = validateParameter(valid_21626531, JString, required = false,
                                   default = nil)
  if valid_21626531 != nil:
    section.add "X-Amz-Date", valid_21626531
  var valid_21626532 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626532 = validateParameter(valid_21626532, JString, required = false,
                                   default = nil)
  if valid_21626532 != nil:
    section.add "X-Amz-Security-Token", valid_21626532
  var valid_21626533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626533 = validateParameter(valid_21626533, JString, required = false,
                                   default = nil)
  if valid_21626533 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626533
  var valid_21626534 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626534 = validateParameter(valid_21626534, JString, required = false,
                                   default = nil)
  if valid_21626534 != nil:
    section.add "X-Amz-Algorithm", valid_21626534
  var valid_21626535 = header.getOrDefault("X-Amz-Signature")
  valid_21626535 = validateParameter(valid_21626535, JString, required = false,
                                   default = nil)
  if valid_21626535 != nil:
    section.add "X-Amz-Signature", valid_21626535
  var valid_21626536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626536 = validateParameter(valid_21626536, JString, required = false,
                                   default = nil)
  if valid_21626536 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626536
  var valid_21626537 = header.getOrDefault("X-Amz-Credential")
  valid_21626537 = validateParameter(valid_21626537, JString, required = false,
                                   default = nil)
  if valid_21626537 != nil:
    section.add "X-Amz-Credential", valid_21626537
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

proc call*(call_21626539: Call_PutConfigurationSetDeliveryOptions_21626527;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associate a configuration set with a dedicated IP pool. You can use dedicated IP pools to create groups of dedicated IP addresses for sending specific types of email.
  ## 
  let valid = call_21626539.validator(path, query, header, formData, body, _)
  let scheme = call_21626539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626539.makeUrl(scheme.get, call_21626539.host, call_21626539.base,
                               call_21626539.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626539, uri, valid, _)

proc call*(call_21626540: Call_PutConfigurationSetDeliveryOptions_21626527;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetDeliveryOptions
  ## Associate a configuration set with a dedicated IP pool. You can use dedicated IP pools to create groups of dedicated IP addresses for sending specific types of email.
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_21626541 = newJObject()
  var body_21626542 = newJObject()
  add(path_21626541, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_21626542 = body
  result = call_21626540.call(path_21626541, nil, nil, nil, body_21626542)

var putConfigurationSetDeliveryOptions* = Call_PutConfigurationSetDeliveryOptions_21626527(
    name: "putConfigurationSetDeliveryOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v2/email/configuration-sets/{ConfigurationSetName}/delivery-options",
    validator: validate_PutConfigurationSetDeliveryOptions_21626528, base: "/",
    makeUrl: url_PutConfigurationSetDeliveryOptions_21626529,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetReputationOptions_21626543 = ref object of OpenApiRestCall_21625435
proc url_PutConfigurationSetReputationOptions_21626545(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/reputation-options")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutConfigurationSetReputationOptions_21626544(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Enable or disable collection of reputation metrics for emails that you send using a particular configuration set in a specific AWS Region.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_21626546 = path.getOrDefault("ConfigurationSetName")
  valid_21626546 = validateParameter(valid_21626546, JString, required = true,
                                   default = nil)
  if valid_21626546 != nil:
    section.add "ConfigurationSetName", valid_21626546
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
  var valid_21626547 = header.getOrDefault("X-Amz-Date")
  valid_21626547 = validateParameter(valid_21626547, JString, required = false,
                                   default = nil)
  if valid_21626547 != nil:
    section.add "X-Amz-Date", valid_21626547
  var valid_21626548 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626548 = validateParameter(valid_21626548, JString, required = false,
                                   default = nil)
  if valid_21626548 != nil:
    section.add "X-Amz-Security-Token", valid_21626548
  var valid_21626549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626549 = validateParameter(valid_21626549, JString, required = false,
                                   default = nil)
  if valid_21626549 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626549
  var valid_21626550 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626550 = validateParameter(valid_21626550, JString, required = false,
                                   default = nil)
  if valid_21626550 != nil:
    section.add "X-Amz-Algorithm", valid_21626550
  var valid_21626551 = header.getOrDefault("X-Amz-Signature")
  valid_21626551 = validateParameter(valid_21626551, JString, required = false,
                                   default = nil)
  if valid_21626551 != nil:
    section.add "X-Amz-Signature", valid_21626551
  var valid_21626552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626552 = validateParameter(valid_21626552, JString, required = false,
                                   default = nil)
  if valid_21626552 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626552
  var valid_21626553 = header.getOrDefault("X-Amz-Credential")
  valid_21626553 = validateParameter(valid_21626553, JString, required = false,
                                   default = nil)
  if valid_21626553 != nil:
    section.add "X-Amz-Credential", valid_21626553
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

proc call*(call_21626555: Call_PutConfigurationSetReputationOptions_21626543;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Enable or disable collection of reputation metrics for emails that you send using a particular configuration set in a specific AWS Region.
  ## 
  let valid = call_21626555.validator(path, query, header, formData, body, _)
  let scheme = call_21626555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626555.makeUrl(scheme.get, call_21626555.host, call_21626555.base,
                               call_21626555.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626555, uri, valid, _)

proc call*(call_21626556: Call_PutConfigurationSetReputationOptions_21626543;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetReputationOptions
  ## Enable or disable collection of reputation metrics for emails that you send using a particular configuration set in a specific AWS Region.
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_21626557 = newJObject()
  var body_21626558 = newJObject()
  add(path_21626557, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_21626558 = body
  result = call_21626556.call(path_21626557, nil, nil, nil, body_21626558)

var putConfigurationSetReputationOptions* = Call_PutConfigurationSetReputationOptions_21626543(
    name: "putConfigurationSetReputationOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v2/email/configuration-sets/{ConfigurationSetName}/reputation-options",
    validator: validate_PutConfigurationSetReputationOptions_21626544, base: "/",
    makeUrl: url_PutConfigurationSetReputationOptions_21626545,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetSendingOptions_21626559 = ref object of OpenApiRestCall_21625435
proc url_PutConfigurationSetSendingOptions_21626561(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/sending")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutConfigurationSetSendingOptions_21626560(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Enable or disable email sending for messages that use a particular configuration set in a specific AWS Region.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_21626562 = path.getOrDefault("ConfigurationSetName")
  valid_21626562 = validateParameter(valid_21626562, JString, required = true,
                                   default = nil)
  if valid_21626562 != nil:
    section.add "ConfigurationSetName", valid_21626562
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
  var valid_21626563 = header.getOrDefault("X-Amz-Date")
  valid_21626563 = validateParameter(valid_21626563, JString, required = false,
                                   default = nil)
  if valid_21626563 != nil:
    section.add "X-Amz-Date", valid_21626563
  var valid_21626564 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626564 = validateParameter(valid_21626564, JString, required = false,
                                   default = nil)
  if valid_21626564 != nil:
    section.add "X-Amz-Security-Token", valid_21626564
  var valid_21626565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626565 = validateParameter(valid_21626565, JString, required = false,
                                   default = nil)
  if valid_21626565 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626565
  var valid_21626566 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626566 = validateParameter(valid_21626566, JString, required = false,
                                   default = nil)
  if valid_21626566 != nil:
    section.add "X-Amz-Algorithm", valid_21626566
  var valid_21626567 = header.getOrDefault("X-Amz-Signature")
  valid_21626567 = validateParameter(valid_21626567, JString, required = false,
                                   default = nil)
  if valid_21626567 != nil:
    section.add "X-Amz-Signature", valid_21626567
  var valid_21626568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626568 = validateParameter(valid_21626568, JString, required = false,
                                   default = nil)
  if valid_21626568 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626568
  var valid_21626569 = header.getOrDefault("X-Amz-Credential")
  valid_21626569 = validateParameter(valid_21626569, JString, required = false,
                                   default = nil)
  if valid_21626569 != nil:
    section.add "X-Amz-Credential", valid_21626569
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

proc call*(call_21626571: Call_PutConfigurationSetSendingOptions_21626559;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Enable or disable email sending for messages that use a particular configuration set in a specific AWS Region.
  ## 
  let valid = call_21626571.validator(path, query, header, formData, body, _)
  let scheme = call_21626571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626571.makeUrl(scheme.get, call_21626571.host, call_21626571.base,
                               call_21626571.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626571, uri, valid, _)

proc call*(call_21626572: Call_PutConfigurationSetSendingOptions_21626559;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetSendingOptions
  ## Enable or disable email sending for messages that use a particular configuration set in a specific AWS Region.
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_21626573 = newJObject()
  var body_21626574 = newJObject()
  add(path_21626573, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_21626574 = body
  result = call_21626572.call(path_21626573, nil, nil, nil, body_21626574)

var putConfigurationSetSendingOptions* = Call_PutConfigurationSetSendingOptions_21626559(
    name: "putConfigurationSetSendingOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v2/email/configuration-sets/{ConfigurationSetName}/sending",
    validator: validate_PutConfigurationSetSendingOptions_21626560, base: "/",
    makeUrl: url_PutConfigurationSetSendingOptions_21626561,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetSuppressionOptions_21626575 = ref object of OpenApiRestCall_21625435
proc url_PutConfigurationSetSuppressionOptions_21626577(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/suppression-options")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutConfigurationSetSuppressionOptions_21626576(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Specify the account suppression list preferences for a configuration set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_21626578 = path.getOrDefault("ConfigurationSetName")
  valid_21626578 = validateParameter(valid_21626578, JString, required = true,
                                   default = nil)
  if valid_21626578 != nil:
    section.add "ConfigurationSetName", valid_21626578
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
  var valid_21626579 = header.getOrDefault("X-Amz-Date")
  valid_21626579 = validateParameter(valid_21626579, JString, required = false,
                                   default = nil)
  if valid_21626579 != nil:
    section.add "X-Amz-Date", valid_21626579
  var valid_21626580 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626580 = validateParameter(valid_21626580, JString, required = false,
                                   default = nil)
  if valid_21626580 != nil:
    section.add "X-Amz-Security-Token", valid_21626580
  var valid_21626581 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626581 = validateParameter(valid_21626581, JString, required = false,
                                   default = nil)
  if valid_21626581 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626581
  var valid_21626582 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626582 = validateParameter(valid_21626582, JString, required = false,
                                   default = nil)
  if valid_21626582 != nil:
    section.add "X-Amz-Algorithm", valid_21626582
  var valid_21626583 = header.getOrDefault("X-Amz-Signature")
  valid_21626583 = validateParameter(valid_21626583, JString, required = false,
                                   default = nil)
  if valid_21626583 != nil:
    section.add "X-Amz-Signature", valid_21626583
  var valid_21626584 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626584 = validateParameter(valid_21626584, JString, required = false,
                                   default = nil)
  if valid_21626584 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626584
  var valid_21626585 = header.getOrDefault("X-Amz-Credential")
  valid_21626585 = validateParameter(valid_21626585, JString, required = false,
                                   default = nil)
  if valid_21626585 != nil:
    section.add "X-Amz-Credential", valid_21626585
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

proc call*(call_21626587: Call_PutConfigurationSetSuppressionOptions_21626575;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Specify the account suppression list preferences for a configuration set.
  ## 
  let valid = call_21626587.validator(path, query, header, formData, body, _)
  let scheme = call_21626587.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626587.makeUrl(scheme.get, call_21626587.host, call_21626587.base,
                               call_21626587.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626587, uri, valid, _)

proc call*(call_21626588: Call_PutConfigurationSetSuppressionOptions_21626575;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetSuppressionOptions
  ## Specify the account suppression list preferences for a configuration set.
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_21626589 = newJObject()
  var body_21626590 = newJObject()
  add(path_21626589, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_21626590 = body
  result = call_21626588.call(path_21626589, nil, nil, nil, body_21626590)

var putConfigurationSetSuppressionOptions* = Call_PutConfigurationSetSuppressionOptions_21626575(
    name: "putConfigurationSetSuppressionOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v2/email/configuration-sets/{ConfigurationSetName}/suppression-options",
    validator: validate_PutConfigurationSetSuppressionOptions_21626576, base: "/",
    makeUrl: url_PutConfigurationSetSuppressionOptions_21626577,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetTrackingOptions_21626591 = ref object of OpenApiRestCall_21625435
proc url_PutConfigurationSetTrackingOptions_21626593(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/tracking-options")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutConfigurationSetTrackingOptions_21626592(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Specify a custom domain to use for open and click tracking elements in email that you send.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_21626594 = path.getOrDefault("ConfigurationSetName")
  valid_21626594 = validateParameter(valid_21626594, JString, required = true,
                                   default = nil)
  if valid_21626594 != nil:
    section.add "ConfigurationSetName", valid_21626594
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
  var valid_21626595 = header.getOrDefault("X-Amz-Date")
  valid_21626595 = validateParameter(valid_21626595, JString, required = false,
                                   default = nil)
  if valid_21626595 != nil:
    section.add "X-Amz-Date", valid_21626595
  var valid_21626596 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626596 = validateParameter(valid_21626596, JString, required = false,
                                   default = nil)
  if valid_21626596 != nil:
    section.add "X-Amz-Security-Token", valid_21626596
  var valid_21626597 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626597 = validateParameter(valid_21626597, JString, required = false,
                                   default = nil)
  if valid_21626597 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626597
  var valid_21626598 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626598 = validateParameter(valid_21626598, JString, required = false,
                                   default = nil)
  if valid_21626598 != nil:
    section.add "X-Amz-Algorithm", valid_21626598
  var valid_21626599 = header.getOrDefault("X-Amz-Signature")
  valid_21626599 = validateParameter(valid_21626599, JString, required = false,
                                   default = nil)
  if valid_21626599 != nil:
    section.add "X-Amz-Signature", valid_21626599
  var valid_21626600 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626600 = validateParameter(valid_21626600, JString, required = false,
                                   default = nil)
  if valid_21626600 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626600
  var valid_21626601 = header.getOrDefault("X-Amz-Credential")
  valid_21626601 = validateParameter(valid_21626601, JString, required = false,
                                   default = nil)
  if valid_21626601 != nil:
    section.add "X-Amz-Credential", valid_21626601
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

proc call*(call_21626603: Call_PutConfigurationSetTrackingOptions_21626591;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Specify a custom domain to use for open and click tracking elements in email that you send.
  ## 
  let valid = call_21626603.validator(path, query, header, formData, body, _)
  let scheme = call_21626603.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626603.makeUrl(scheme.get, call_21626603.host, call_21626603.base,
                               call_21626603.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626603, uri, valid, _)

proc call*(call_21626604: Call_PutConfigurationSetTrackingOptions_21626591;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetTrackingOptions
  ## Specify a custom domain to use for open and click tracking elements in email that you send.
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_21626605 = newJObject()
  var body_21626606 = newJObject()
  add(path_21626605, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_21626606 = body
  result = call_21626604.call(path_21626605, nil, nil, nil, body_21626606)

var putConfigurationSetTrackingOptions* = Call_PutConfigurationSetTrackingOptions_21626591(
    name: "putConfigurationSetTrackingOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v2/email/configuration-sets/{ConfigurationSetName}/tracking-options",
    validator: validate_PutConfigurationSetTrackingOptions_21626592, base: "/",
    makeUrl: url_PutConfigurationSetTrackingOptions_21626593,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDedicatedIpInPool_21626607 = ref object of OpenApiRestCall_21625435
proc url_PutDedicatedIpInPool_21626609(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IP" in path, "`IP` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/dedicated-ips/"),
               (kind: VariableSegment, value: "IP"),
               (kind: ConstantSegment, value: "/pool")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutDedicatedIpInPool_21626608(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Move a dedicated IP address to an existing dedicated IP pool.</p> <note> <p>The dedicated IP address that you specify must already exist, and must be associated with your AWS account. </p> <p>The dedicated IP pool you specify must already exist. You can create a new pool by using the <code>CreateDedicatedIpPool</code> operation.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IP: JString (required)
  ##     : An IPv4 address.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `IP` field"
  var valid_21626610 = path.getOrDefault("IP")
  valid_21626610 = validateParameter(valid_21626610, JString, required = true,
                                   default = nil)
  if valid_21626610 != nil:
    section.add "IP", valid_21626610
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
  var valid_21626611 = header.getOrDefault("X-Amz-Date")
  valid_21626611 = validateParameter(valid_21626611, JString, required = false,
                                   default = nil)
  if valid_21626611 != nil:
    section.add "X-Amz-Date", valid_21626611
  var valid_21626612 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626612 = validateParameter(valid_21626612, JString, required = false,
                                   default = nil)
  if valid_21626612 != nil:
    section.add "X-Amz-Security-Token", valid_21626612
  var valid_21626613 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626613 = validateParameter(valid_21626613, JString, required = false,
                                   default = nil)
  if valid_21626613 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626613
  var valid_21626614 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626614 = validateParameter(valid_21626614, JString, required = false,
                                   default = nil)
  if valid_21626614 != nil:
    section.add "X-Amz-Algorithm", valid_21626614
  var valid_21626615 = header.getOrDefault("X-Amz-Signature")
  valid_21626615 = validateParameter(valid_21626615, JString, required = false,
                                   default = nil)
  if valid_21626615 != nil:
    section.add "X-Amz-Signature", valid_21626615
  var valid_21626616 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626616 = validateParameter(valid_21626616, JString, required = false,
                                   default = nil)
  if valid_21626616 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626616
  var valid_21626617 = header.getOrDefault("X-Amz-Credential")
  valid_21626617 = validateParameter(valid_21626617, JString, required = false,
                                   default = nil)
  if valid_21626617 != nil:
    section.add "X-Amz-Credential", valid_21626617
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

proc call*(call_21626619: Call_PutDedicatedIpInPool_21626607; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Move a dedicated IP address to an existing dedicated IP pool.</p> <note> <p>The dedicated IP address that you specify must already exist, and must be associated with your AWS account. </p> <p>The dedicated IP pool you specify must already exist. You can create a new pool by using the <code>CreateDedicatedIpPool</code> operation.</p> </note>
  ## 
  let valid = call_21626619.validator(path, query, header, formData, body, _)
  let scheme = call_21626619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626619.makeUrl(scheme.get, call_21626619.host, call_21626619.base,
                               call_21626619.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626619, uri, valid, _)

proc call*(call_21626620: Call_PutDedicatedIpInPool_21626607; IP: string;
          body: JsonNode): Recallable =
  ## putDedicatedIpInPool
  ## <p>Move a dedicated IP address to an existing dedicated IP pool.</p> <note> <p>The dedicated IP address that you specify must already exist, and must be associated with your AWS account. </p> <p>The dedicated IP pool you specify must already exist. You can create a new pool by using the <code>CreateDedicatedIpPool</code> operation.</p> </note>
  ##   IP: string (required)
  ##     : An IPv4 address.
  ##   body: JObject (required)
  var path_21626621 = newJObject()
  var body_21626622 = newJObject()
  add(path_21626621, "IP", newJString(IP))
  if body != nil:
    body_21626622 = body
  result = call_21626620.call(path_21626621, nil, nil, nil, body_21626622)

var putDedicatedIpInPool* = Call_PutDedicatedIpInPool_21626607(
    name: "putDedicatedIpInPool", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v2/email/dedicated-ips/{IP}/pool",
    validator: validate_PutDedicatedIpInPool_21626608, base: "/",
    makeUrl: url_PutDedicatedIpInPool_21626609,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDedicatedIpWarmupAttributes_21626623 = ref object of OpenApiRestCall_21625435
proc url_PutDedicatedIpWarmupAttributes_21626625(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IP" in path, "`IP` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/dedicated-ips/"),
               (kind: VariableSegment, value: "IP"),
               (kind: ConstantSegment, value: "/warmup")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutDedicatedIpWarmupAttributes_21626624(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p/>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IP: JString (required)
  ##     : An IPv4 address.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `IP` field"
  var valid_21626626 = path.getOrDefault("IP")
  valid_21626626 = validateParameter(valid_21626626, JString, required = true,
                                   default = nil)
  if valid_21626626 != nil:
    section.add "IP", valid_21626626
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
  var valid_21626627 = header.getOrDefault("X-Amz-Date")
  valid_21626627 = validateParameter(valid_21626627, JString, required = false,
                                   default = nil)
  if valid_21626627 != nil:
    section.add "X-Amz-Date", valid_21626627
  var valid_21626628 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626628 = validateParameter(valid_21626628, JString, required = false,
                                   default = nil)
  if valid_21626628 != nil:
    section.add "X-Amz-Security-Token", valid_21626628
  var valid_21626629 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626629 = validateParameter(valid_21626629, JString, required = false,
                                   default = nil)
  if valid_21626629 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626629
  var valid_21626630 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626630 = validateParameter(valid_21626630, JString, required = false,
                                   default = nil)
  if valid_21626630 != nil:
    section.add "X-Amz-Algorithm", valid_21626630
  var valid_21626631 = header.getOrDefault("X-Amz-Signature")
  valid_21626631 = validateParameter(valid_21626631, JString, required = false,
                                   default = nil)
  if valid_21626631 != nil:
    section.add "X-Amz-Signature", valid_21626631
  var valid_21626632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626632 = validateParameter(valid_21626632, JString, required = false,
                                   default = nil)
  if valid_21626632 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626632
  var valid_21626633 = header.getOrDefault("X-Amz-Credential")
  valid_21626633 = validateParameter(valid_21626633, JString, required = false,
                                   default = nil)
  if valid_21626633 != nil:
    section.add "X-Amz-Credential", valid_21626633
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

proc call*(call_21626635: Call_PutDedicatedIpWarmupAttributes_21626623;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p/>
  ## 
  let valid = call_21626635.validator(path, query, header, formData, body, _)
  let scheme = call_21626635.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626635.makeUrl(scheme.get, call_21626635.host, call_21626635.base,
                               call_21626635.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626635, uri, valid, _)

proc call*(call_21626636: Call_PutDedicatedIpWarmupAttributes_21626623; IP: string;
          body: JsonNode): Recallable =
  ## putDedicatedIpWarmupAttributes
  ## <p/>
  ##   IP: string (required)
  ##     : An IPv4 address.
  ##   body: JObject (required)
  var path_21626637 = newJObject()
  var body_21626638 = newJObject()
  add(path_21626637, "IP", newJString(IP))
  if body != nil:
    body_21626638 = body
  result = call_21626636.call(path_21626637, nil, nil, nil, body_21626638)

var putDedicatedIpWarmupAttributes* = Call_PutDedicatedIpWarmupAttributes_21626623(
    name: "putDedicatedIpWarmupAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v2/email/dedicated-ips/{IP}/warmup",
    validator: validate_PutDedicatedIpWarmupAttributes_21626624, base: "/",
    makeUrl: url_PutDedicatedIpWarmupAttributes_21626625,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEmailIdentityDkimAttributes_21626639 = ref object of OpenApiRestCall_21625435
proc url_PutEmailIdentityDkimAttributes_21626641(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "EmailIdentity" in path, "`EmailIdentity` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/identities/"),
               (kind: VariableSegment, value: "EmailIdentity"),
               (kind: ConstantSegment, value: "/dkim")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutEmailIdentityDkimAttributes_21626640(path: JsonNode;
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
  var valid_21626642 = path.getOrDefault("EmailIdentity")
  valid_21626642 = validateParameter(valid_21626642, JString, required = true,
                                   default = nil)
  if valid_21626642 != nil:
    section.add "EmailIdentity", valid_21626642
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
  var valid_21626643 = header.getOrDefault("X-Amz-Date")
  valid_21626643 = validateParameter(valid_21626643, JString, required = false,
                                   default = nil)
  if valid_21626643 != nil:
    section.add "X-Amz-Date", valid_21626643
  var valid_21626644 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626644 = validateParameter(valid_21626644, JString, required = false,
                                   default = nil)
  if valid_21626644 != nil:
    section.add "X-Amz-Security-Token", valid_21626644
  var valid_21626645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626645 = validateParameter(valid_21626645, JString, required = false,
                                   default = nil)
  if valid_21626645 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626645
  var valid_21626646 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626646 = validateParameter(valid_21626646, JString, required = false,
                                   default = nil)
  if valid_21626646 != nil:
    section.add "X-Amz-Algorithm", valid_21626646
  var valid_21626647 = header.getOrDefault("X-Amz-Signature")
  valid_21626647 = validateParameter(valid_21626647, JString, required = false,
                                   default = nil)
  if valid_21626647 != nil:
    section.add "X-Amz-Signature", valid_21626647
  var valid_21626648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626648 = validateParameter(valid_21626648, JString, required = false,
                                   default = nil)
  if valid_21626648 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626648
  var valid_21626649 = header.getOrDefault("X-Amz-Credential")
  valid_21626649 = validateParameter(valid_21626649, JString, required = false,
                                   default = nil)
  if valid_21626649 != nil:
    section.add "X-Amz-Credential", valid_21626649
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

proc call*(call_21626651: Call_PutEmailIdentityDkimAttributes_21626639;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Used to enable or disable DKIM authentication for an email identity.
  ## 
  let valid = call_21626651.validator(path, query, header, formData, body, _)
  let scheme = call_21626651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626651.makeUrl(scheme.get, call_21626651.host, call_21626651.base,
                               call_21626651.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626651, uri, valid, _)

proc call*(call_21626652: Call_PutEmailIdentityDkimAttributes_21626639;
          EmailIdentity: string; body: JsonNode): Recallable =
  ## putEmailIdentityDkimAttributes
  ## Used to enable or disable DKIM authentication for an email identity.
  ##   EmailIdentity: string (required)
  ##                : The email identity that you want to change the DKIM settings for.
  ##   body: JObject (required)
  var path_21626653 = newJObject()
  var body_21626654 = newJObject()
  add(path_21626653, "EmailIdentity", newJString(EmailIdentity))
  if body != nil:
    body_21626654 = body
  result = call_21626652.call(path_21626653, nil, nil, nil, body_21626654)

var putEmailIdentityDkimAttributes* = Call_PutEmailIdentityDkimAttributes_21626639(
    name: "putEmailIdentityDkimAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v2/email/identities/{EmailIdentity}/dkim",
    validator: validate_PutEmailIdentityDkimAttributes_21626640, base: "/",
    makeUrl: url_PutEmailIdentityDkimAttributes_21626641,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEmailIdentityDkimSigningAttributes_21626655 = ref object of OpenApiRestCall_21625435
proc url_PutEmailIdentityDkimSigningAttributes_21626657(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "EmailIdentity" in path, "`EmailIdentity` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/identities/"),
               (kind: VariableSegment, value: "EmailIdentity"),
               (kind: ConstantSegment, value: "/dkim/signing")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutEmailIdentityDkimSigningAttributes_21626656(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Used to configure or change the DKIM authentication settings for an email domain identity. You can use this operation to do any of the following:</p> <ul> <li> <p>Update the signing attributes for an identity that uses Bring Your Own DKIM (BYODKIM).</p> </li> <li> <p>Change from using no DKIM authentication to using Easy DKIM.</p> </li> <li> <p>Change from using no DKIM authentication to using BYODKIM.</p> </li> <li> <p>Change from using Easy DKIM to using BYODKIM.</p> </li> <li> <p>Change from using BYODKIM to using Easy DKIM.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EmailIdentity: JString (required)
  ##                : The email identity that you want to configure DKIM for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `EmailIdentity` field"
  var valid_21626658 = path.getOrDefault("EmailIdentity")
  valid_21626658 = validateParameter(valid_21626658, JString, required = true,
                                   default = nil)
  if valid_21626658 != nil:
    section.add "EmailIdentity", valid_21626658
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
  var valid_21626659 = header.getOrDefault("X-Amz-Date")
  valid_21626659 = validateParameter(valid_21626659, JString, required = false,
                                   default = nil)
  if valid_21626659 != nil:
    section.add "X-Amz-Date", valid_21626659
  var valid_21626660 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626660 = validateParameter(valid_21626660, JString, required = false,
                                   default = nil)
  if valid_21626660 != nil:
    section.add "X-Amz-Security-Token", valid_21626660
  var valid_21626661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626661 = validateParameter(valid_21626661, JString, required = false,
                                   default = nil)
  if valid_21626661 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626661
  var valid_21626662 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626662 = validateParameter(valid_21626662, JString, required = false,
                                   default = nil)
  if valid_21626662 != nil:
    section.add "X-Amz-Algorithm", valid_21626662
  var valid_21626663 = header.getOrDefault("X-Amz-Signature")
  valid_21626663 = validateParameter(valid_21626663, JString, required = false,
                                   default = nil)
  if valid_21626663 != nil:
    section.add "X-Amz-Signature", valid_21626663
  var valid_21626664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626664 = validateParameter(valid_21626664, JString, required = false,
                                   default = nil)
  if valid_21626664 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626664
  var valid_21626665 = header.getOrDefault("X-Amz-Credential")
  valid_21626665 = validateParameter(valid_21626665, JString, required = false,
                                   default = nil)
  if valid_21626665 != nil:
    section.add "X-Amz-Credential", valid_21626665
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

proc call*(call_21626667: Call_PutEmailIdentityDkimSigningAttributes_21626655;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Used to configure or change the DKIM authentication settings for an email domain identity. You can use this operation to do any of the following:</p> <ul> <li> <p>Update the signing attributes for an identity that uses Bring Your Own DKIM (BYODKIM).</p> </li> <li> <p>Change from using no DKIM authentication to using Easy DKIM.</p> </li> <li> <p>Change from using no DKIM authentication to using BYODKIM.</p> </li> <li> <p>Change from using Easy DKIM to using BYODKIM.</p> </li> <li> <p>Change from using BYODKIM to using Easy DKIM.</p> </li> </ul>
  ## 
  let valid = call_21626667.validator(path, query, header, formData, body, _)
  let scheme = call_21626667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626667.makeUrl(scheme.get, call_21626667.host, call_21626667.base,
                               call_21626667.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626667, uri, valid, _)

proc call*(call_21626668: Call_PutEmailIdentityDkimSigningAttributes_21626655;
          EmailIdentity: string; body: JsonNode): Recallable =
  ## putEmailIdentityDkimSigningAttributes
  ## <p>Used to configure or change the DKIM authentication settings for an email domain identity. You can use this operation to do any of the following:</p> <ul> <li> <p>Update the signing attributes for an identity that uses Bring Your Own DKIM (BYODKIM).</p> </li> <li> <p>Change from using no DKIM authentication to using Easy DKIM.</p> </li> <li> <p>Change from using no DKIM authentication to using BYODKIM.</p> </li> <li> <p>Change from using Easy DKIM to using BYODKIM.</p> </li> <li> <p>Change from using BYODKIM to using Easy DKIM.</p> </li> </ul>
  ##   EmailIdentity: string (required)
  ##                : The email identity that you want to configure DKIM for.
  ##   body: JObject (required)
  var path_21626669 = newJObject()
  var body_21626670 = newJObject()
  add(path_21626669, "EmailIdentity", newJString(EmailIdentity))
  if body != nil:
    body_21626670 = body
  result = call_21626668.call(path_21626669, nil, nil, nil, body_21626670)

var putEmailIdentityDkimSigningAttributes* = Call_PutEmailIdentityDkimSigningAttributes_21626655(
    name: "putEmailIdentityDkimSigningAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v1/email/identities/{EmailIdentity}/dkim/signing",
    validator: validate_PutEmailIdentityDkimSigningAttributes_21626656, base: "/",
    makeUrl: url_PutEmailIdentityDkimSigningAttributes_21626657,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEmailIdentityFeedbackAttributes_21626671 = ref object of OpenApiRestCall_21625435
proc url_PutEmailIdentityFeedbackAttributes_21626673(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "EmailIdentity" in path, "`EmailIdentity` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/identities/"),
               (kind: VariableSegment, value: "EmailIdentity"),
               (kind: ConstantSegment, value: "/feedback")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutEmailIdentityFeedbackAttributes_21626672(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Used to enable or disable feedback forwarding for an identity. This setting determines what happens when an identity is used to send an email that results in a bounce or complaint event.</p> <p>If the value is <code>true</code>, you receive email notifications when bounce or complaint events occur. These notifications are sent to the address that you specified in the <code>Return-Path</code> header of the original email.</p> <p>You're required to have a method of tracking bounces and complaints. If you haven't set up another mechanism for receiving bounce or complaint notifications (for example, by setting up an event destination), you receive an email notification when these events occur (even if this setting is disabled).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EmailIdentity: JString (required)
  ##                : The email identity that you want to configure bounce and complaint feedback forwarding for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `EmailIdentity` field"
  var valid_21626674 = path.getOrDefault("EmailIdentity")
  valid_21626674 = validateParameter(valid_21626674, JString, required = true,
                                   default = nil)
  if valid_21626674 != nil:
    section.add "EmailIdentity", valid_21626674
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
  var valid_21626675 = header.getOrDefault("X-Amz-Date")
  valid_21626675 = validateParameter(valid_21626675, JString, required = false,
                                   default = nil)
  if valid_21626675 != nil:
    section.add "X-Amz-Date", valid_21626675
  var valid_21626676 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626676 = validateParameter(valid_21626676, JString, required = false,
                                   default = nil)
  if valid_21626676 != nil:
    section.add "X-Amz-Security-Token", valid_21626676
  var valid_21626677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626677 = validateParameter(valid_21626677, JString, required = false,
                                   default = nil)
  if valid_21626677 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626677
  var valid_21626678 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626678 = validateParameter(valid_21626678, JString, required = false,
                                   default = nil)
  if valid_21626678 != nil:
    section.add "X-Amz-Algorithm", valid_21626678
  var valid_21626679 = header.getOrDefault("X-Amz-Signature")
  valid_21626679 = validateParameter(valid_21626679, JString, required = false,
                                   default = nil)
  if valid_21626679 != nil:
    section.add "X-Amz-Signature", valid_21626679
  var valid_21626680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626680 = validateParameter(valid_21626680, JString, required = false,
                                   default = nil)
  if valid_21626680 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626680
  var valid_21626681 = header.getOrDefault("X-Amz-Credential")
  valid_21626681 = validateParameter(valid_21626681, JString, required = false,
                                   default = nil)
  if valid_21626681 != nil:
    section.add "X-Amz-Credential", valid_21626681
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

proc call*(call_21626683: Call_PutEmailIdentityFeedbackAttributes_21626671;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Used to enable or disable feedback forwarding for an identity. This setting determines what happens when an identity is used to send an email that results in a bounce or complaint event.</p> <p>If the value is <code>true</code>, you receive email notifications when bounce or complaint events occur. These notifications are sent to the address that you specified in the <code>Return-Path</code> header of the original email.</p> <p>You're required to have a method of tracking bounces and complaints. If you haven't set up another mechanism for receiving bounce or complaint notifications (for example, by setting up an event destination), you receive an email notification when these events occur (even if this setting is disabled).</p>
  ## 
  let valid = call_21626683.validator(path, query, header, formData, body, _)
  let scheme = call_21626683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626683.makeUrl(scheme.get, call_21626683.host, call_21626683.base,
                               call_21626683.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626683, uri, valid, _)

proc call*(call_21626684: Call_PutEmailIdentityFeedbackAttributes_21626671;
          EmailIdentity: string; body: JsonNode): Recallable =
  ## putEmailIdentityFeedbackAttributes
  ## <p>Used to enable or disable feedback forwarding for an identity. This setting determines what happens when an identity is used to send an email that results in a bounce or complaint event.</p> <p>If the value is <code>true</code>, you receive email notifications when bounce or complaint events occur. These notifications are sent to the address that you specified in the <code>Return-Path</code> header of the original email.</p> <p>You're required to have a method of tracking bounces and complaints. If you haven't set up another mechanism for receiving bounce or complaint notifications (for example, by setting up an event destination), you receive an email notification when these events occur (even if this setting is disabled).</p>
  ##   EmailIdentity: string (required)
  ##                : The email identity that you want to configure bounce and complaint feedback forwarding for.
  ##   body: JObject (required)
  var path_21626685 = newJObject()
  var body_21626686 = newJObject()
  add(path_21626685, "EmailIdentity", newJString(EmailIdentity))
  if body != nil:
    body_21626686 = body
  result = call_21626684.call(path_21626685, nil, nil, nil, body_21626686)

var putEmailIdentityFeedbackAttributes* = Call_PutEmailIdentityFeedbackAttributes_21626671(
    name: "putEmailIdentityFeedbackAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v2/email/identities/{EmailIdentity}/feedback",
    validator: validate_PutEmailIdentityFeedbackAttributes_21626672, base: "/",
    makeUrl: url_PutEmailIdentityFeedbackAttributes_21626673,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEmailIdentityMailFromAttributes_21626687 = ref object of OpenApiRestCall_21625435
proc url_PutEmailIdentityMailFromAttributes_21626689(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "EmailIdentity" in path, "`EmailIdentity` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/identities/"),
               (kind: VariableSegment, value: "EmailIdentity"),
               (kind: ConstantSegment, value: "/mail-from")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutEmailIdentityMailFromAttributes_21626688(path: JsonNode;
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
  var valid_21626690 = path.getOrDefault("EmailIdentity")
  valid_21626690 = validateParameter(valid_21626690, JString, required = true,
                                   default = nil)
  if valid_21626690 != nil:
    section.add "EmailIdentity", valid_21626690
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
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626699: Call_PutEmailIdentityMailFromAttributes_21626687;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Used to enable or disable the custom Mail-From domain configuration for an email identity.
  ## 
  let valid = call_21626699.validator(path, query, header, formData, body, _)
  let scheme = call_21626699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626699.makeUrl(scheme.get, call_21626699.host, call_21626699.base,
                               call_21626699.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626699, uri, valid, _)

proc call*(call_21626700: Call_PutEmailIdentityMailFromAttributes_21626687;
          EmailIdentity: string; body: JsonNode): Recallable =
  ## putEmailIdentityMailFromAttributes
  ## Used to enable or disable the custom Mail-From domain configuration for an email identity.
  ##   EmailIdentity: string (required)
  ##                : The verified email identity that you want to set up the custom MAIL FROM domain for.
  ##   body: JObject (required)
  var path_21626701 = newJObject()
  var body_21626702 = newJObject()
  add(path_21626701, "EmailIdentity", newJString(EmailIdentity))
  if body != nil:
    body_21626702 = body
  result = call_21626700.call(path_21626701, nil, nil, nil, body_21626702)

var putEmailIdentityMailFromAttributes* = Call_PutEmailIdentityMailFromAttributes_21626687(
    name: "putEmailIdentityMailFromAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v2/email/identities/{EmailIdentity}/mail-from",
    validator: validate_PutEmailIdentityMailFromAttributes_21626688, base: "/",
    makeUrl: url_PutEmailIdentityMailFromAttributes_21626689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendEmail_21626703 = ref object of OpenApiRestCall_21625435
proc url_SendEmail_21626705(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendEmail_21626704(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Sends an email message. You can use the Amazon SES API v2 to send two types of messages:</p> <ul> <li> <p> <b>Simple</b> – A standard email message. When you create this type of message, you specify the sender, the recipient, and the message body, and Amazon SES assembles the message for you.</p> </li> <li> <p> <b>Raw</b> – A raw, MIME-formatted email message. When you send this type of email, you have to specify all of the message headers, as well as the message body. You can use this message type to send messages that contain attachments. The message that you specify has to be a valid MIME message.</p> </li> </ul>
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
  var valid_21626706 = header.getOrDefault("X-Amz-Date")
  valid_21626706 = validateParameter(valid_21626706, JString, required = false,
                                   default = nil)
  if valid_21626706 != nil:
    section.add "X-Amz-Date", valid_21626706
  var valid_21626707 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626707 = validateParameter(valid_21626707, JString, required = false,
                                   default = nil)
  if valid_21626707 != nil:
    section.add "X-Amz-Security-Token", valid_21626707
  var valid_21626708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626708 = validateParameter(valid_21626708, JString, required = false,
                                   default = nil)
  if valid_21626708 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626708
  var valid_21626709 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626709 = validateParameter(valid_21626709, JString, required = false,
                                   default = nil)
  if valid_21626709 != nil:
    section.add "X-Amz-Algorithm", valid_21626709
  var valid_21626710 = header.getOrDefault("X-Amz-Signature")
  valid_21626710 = validateParameter(valid_21626710, JString, required = false,
                                   default = nil)
  if valid_21626710 != nil:
    section.add "X-Amz-Signature", valid_21626710
  var valid_21626711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626711 = validateParameter(valid_21626711, JString, required = false,
                                   default = nil)
  if valid_21626711 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626711
  var valid_21626712 = header.getOrDefault("X-Amz-Credential")
  valid_21626712 = validateParameter(valid_21626712, JString, required = false,
                                   default = nil)
  if valid_21626712 != nil:
    section.add "X-Amz-Credential", valid_21626712
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

proc call*(call_21626714: Call_SendEmail_21626703; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sends an email message. You can use the Amazon SES API v2 to send two types of messages:</p> <ul> <li> <p> <b>Simple</b> – A standard email message. When you create this type of message, you specify the sender, the recipient, and the message body, and Amazon SES assembles the message for you.</p> </li> <li> <p> <b>Raw</b> – A raw, MIME-formatted email message. When you send this type of email, you have to specify all of the message headers, as well as the message body. You can use this message type to send messages that contain attachments. The message that you specify has to be a valid MIME message.</p> </li> </ul>
  ## 
  let valid = call_21626714.validator(path, query, header, formData, body, _)
  let scheme = call_21626714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626714.makeUrl(scheme.get, call_21626714.host, call_21626714.base,
                               call_21626714.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626714, uri, valid, _)

proc call*(call_21626715: Call_SendEmail_21626703; body: JsonNode): Recallable =
  ## sendEmail
  ## <p>Sends an email message. You can use the Amazon SES API v2 to send two types of messages:</p> <ul> <li> <p> <b>Simple</b> – A standard email message. When you create this type of message, you specify the sender, the recipient, and the message body, and Amazon SES assembles the message for you.</p> </li> <li> <p> <b>Raw</b> – A raw, MIME-formatted email message. When you send this type of email, you have to specify all of the message headers, as well as the message body. You can use this message type to send messages that contain attachments. The message that you specify has to be a valid MIME message.</p> </li> </ul>
  ##   body: JObject (required)
  var body_21626716 = newJObject()
  if body != nil:
    body_21626716 = body
  result = call_21626715.call(nil, nil, nil, nil, body_21626716)

var sendEmail* = Call_SendEmail_21626703(name: "sendEmail",
                                      meth: HttpMethod.HttpPost,
                                      host: "email.amazonaws.com",
                                      route: "/v2/email/outbound-emails",
                                      validator: validate_SendEmail_21626704,
                                      base: "/", makeUrl: url_SendEmail_21626705,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21626717 = ref object of OpenApiRestCall_21625435
proc url_TagResource_21626719(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_21626718(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Add one or more tags (keys and values) to a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource. Tags can help you categorize and manage resources in different ways, such as by purpose, owner, environment, or other criteria. A resource can have as many as 50 tags.</p> <p>Each tag consists of a required <i>tag key</i> and an associated <i>tag value</i>, both of which you define. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.</p>
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
  var valid_21626720 = header.getOrDefault("X-Amz-Date")
  valid_21626720 = validateParameter(valid_21626720, JString, required = false,
                                   default = nil)
  if valid_21626720 != nil:
    section.add "X-Amz-Date", valid_21626720
  var valid_21626721 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626721 = validateParameter(valid_21626721, JString, required = false,
                                   default = nil)
  if valid_21626721 != nil:
    section.add "X-Amz-Security-Token", valid_21626721
  var valid_21626722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626722 = validateParameter(valid_21626722, JString, required = false,
                                   default = nil)
  if valid_21626722 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626722
  var valid_21626723 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626723 = validateParameter(valid_21626723, JString, required = false,
                                   default = nil)
  if valid_21626723 != nil:
    section.add "X-Amz-Algorithm", valid_21626723
  var valid_21626724 = header.getOrDefault("X-Amz-Signature")
  valid_21626724 = validateParameter(valid_21626724, JString, required = false,
                                   default = nil)
  if valid_21626724 != nil:
    section.add "X-Amz-Signature", valid_21626724
  var valid_21626725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626725 = validateParameter(valid_21626725, JString, required = false,
                                   default = nil)
  if valid_21626725 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626725
  var valid_21626726 = header.getOrDefault("X-Amz-Credential")
  valid_21626726 = validateParameter(valid_21626726, JString, required = false,
                                   default = nil)
  if valid_21626726 != nil:
    section.add "X-Amz-Credential", valid_21626726
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

proc call*(call_21626728: Call_TagResource_21626717; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Add one or more tags (keys and values) to a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource. Tags can help you categorize and manage resources in different ways, such as by purpose, owner, environment, or other criteria. A resource can have as many as 50 tags.</p> <p>Each tag consists of a required <i>tag key</i> and an associated <i>tag value</i>, both of which you define. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.</p>
  ## 
  let valid = call_21626728.validator(path, query, header, formData, body, _)
  let scheme = call_21626728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626728.makeUrl(scheme.get, call_21626728.host, call_21626728.base,
                               call_21626728.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626728, uri, valid, _)

proc call*(call_21626729: Call_TagResource_21626717; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Add one or more tags (keys and values) to a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource. Tags can help you categorize and manage resources in different ways, such as by purpose, owner, environment, or other criteria. A resource can have as many as 50 tags.</p> <p>Each tag consists of a required <i>tag key</i> and an associated <i>tag value</i>, both of which you define. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.</p>
  ##   body: JObject (required)
  var body_21626730 = newJObject()
  if body != nil:
    body_21626730 = body
  result = call_21626729.call(nil, nil, nil, nil, body_21626730)

var tagResource* = Call_TagResource_21626717(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "email.amazonaws.com", route: "/v2/email/tags",
    validator: validate_TagResource_21626718, base: "/", makeUrl: url_TagResource_21626719,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21626731 = ref object of OpenApiRestCall_21625435
proc url_UntagResource_21626733(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_21626732(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Remove one or more tags (keys and values) from a specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to remove one or more tags from.
  ##   TagKeys: JArray (required)
  ##          : <p>The tags (tag keys) that you want to remove from the resource. When you specify a tag key, the action removes both that key and its associated tag value.</p> <p>To remove more than one tag from the resource, append the <code>TagKeys</code> parameter and argument for each additional tag to remove, separated by an ampersand. For example: 
  ## <code>/v2/email/tags?ResourceArn=ResourceArn&amp;TagKeys=Key1&amp;TagKeys=Key2</code> </p>
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceArn` field"
  var valid_21626734 = query.getOrDefault("ResourceArn")
  valid_21626734 = validateParameter(valid_21626734, JString, required = true,
                                   default = nil)
  if valid_21626734 != nil:
    section.add "ResourceArn", valid_21626734
  var valid_21626735 = query.getOrDefault("TagKeys")
  valid_21626735 = validateParameter(valid_21626735, JArray, required = true,
                                   default = nil)
  if valid_21626735 != nil:
    section.add "TagKeys", valid_21626735
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626736 = header.getOrDefault("X-Amz-Date")
  valid_21626736 = validateParameter(valid_21626736, JString, required = false,
                                   default = nil)
  if valid_21626736 != nil:
    section.add "X-Amz-Date", valid_21626736
  var valid_21626737 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626737 = validateParameter(valid_21626737, JString, required = false,
                                   default = nil)
  if valid_21626737 != nil:
    section.add "X-Amz-Security-Token", valid_21626737
  var valid_21626738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626738 = validateParameter(valid_21626738, JString, required = false,
                                   default = nil)
  if valid_21626738 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626738
  var valid_21626739 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626739 = validateParameter(valid_21626739, JString, required = false,
                                   default = nil)
  if valid_21626739 != nil:
    section.add "X-Amz-Algorithm", valid_21626739
  var valid_21626740 = header.getOrDefault("X-Amz-Signature")
  valid_21626740 = validateParameter(valid_21626740, JString, required = false,
                                   default = nil)
  if valid_21626740 != nil:
    section.add "X-Amz-Signature", valid_21626740
  var valid_21626741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626741 = validateParameter(valid_21626741, JString, required = false,
                                   default = nil)
  if valid_21626741 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626741
  var valid_21626742 = header.getOrDefault("X-Amz-Credential")
  valid_21626742 = validateParameter(valid_21626742, JString, required = false,
                                   default = nil)
  if valid_21626742 != nil:
    section.add "X-Amz-Credential", valid_21626742
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626743: Call_UntagResource_21626731; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Remove one or more tags (keys and values) from a specified resource.
  ## 
  let valid = call_21626743.validator(path, query, header, formData, body, _)
  let scheme = call_21626743.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626743.makeUrl(scheme.get, call_21626743.host, call_21626743.base,
                               call_21626743.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626743, uri, valid, _)

proc call*(call_21626744: Call_UntagResource_21626731; ResourceArn: string;
          TagKeys: JsonNode): Recallable =
  ## untagResource
  ## Remove one or more tags (keys and values) from a specified resource.
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to remove one or more tags from.
  ##   TagKeys: JArray (required)
  ##          : <p>The tags (tag keys) that you want to remove from the resource. When you specify a tag key, the action removes both that key and its associated tag value.</p> <p>To remove more than one tag from the resource, append the <code>TagKeys</code> parameter and argument for each additional tag to remove, separated by an ampersand. For example: 
  ## <code>/v2/email/tags?ResourceArn=ResourceArn&amp;TagKeys=Key1&amp;TagKeys=Key2</code> </p>
  var query_21626745 = newJObject()
  add(query_21626745, "ResourceArn", newJString(ResourceArn))
  if TagKeys != nil:
    query_21626745.add "TagKeys", TagKeys
  result = call_21626744.call(nil, query_21626745, nil, nil, nil)

var untagResource* = Call_UntagResource_21626731(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "email.amazonaws.com",
    route: "/v2/email/tags#ResourceArn&TagKeys",
    validator: validate_UntagResource_21626732, base: "/",
    makeUrl: url_UntagResource_21626733, schemes: {Scheme.Https, Scheme.Http})
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