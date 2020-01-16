
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Price List Service
## version: 2017-10-15
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>AWS Price List Service API (AWS Price List Service) is a centralized and convenient way to programmatically query Amazon Web Services for services, products, and pricing information. The AWS Price List Service uses standardized product attributes such as <code>Location</code>, <code>Storage Class</code>, and <code>Operating System</code>, and provides prices at the SKU level. You can use the AWS Price List Service to build cost control and scenario planning tools, reconcile billing data, forecast future spend for budgeting purposes, and provide cost benefit analysis that compare your internal workloads with AWS.</p> <p>Use <code>GetServices</code> without a service code to retrieve the service codes for all AWS services, then <code>GetServices</code> with a service code to retreive the attribute names for that service. After you have the service code and attribute names, you can use <code>GetAttributeValues</code> to see what values are available for an attribute. With the service code and an attribute name and value, you can use <code>GetProducts</code> to find specific products that you're interested in, such as an <code>AmazonEC2</code> instance, with a <code>Provisioned IOPS</code> <code>volumeType</code>.</p> <p>Service Endpoint</p> <p>AWS Price List Service API provides the following two endpoints:</p> <ul> <li> <p>https://api.pricing.us-east-1.amazonaws.com</p> </li> <li> <p>https://api.pricing.ap-south-1.amazonaws.com</p> </li> </ul>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/pricing/
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

  OpenApiRestCall_605580 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605580](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605580): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "api.pricing.ap-northeast-1.amazonaws.com", "ap-southeast-1": "api.pricing.ap-southeast-1.amazonaws.com",
                           "us-west-2": "api.pricing.us-west-2.amazonaws.com",
                           "eu-west-2": "api.pricing.eu-west-2.amazonaws.com", "ap-northeast-3": "api.pricing.ap-northeast-3.amazonaws.com", "eu-central-1": "api.pricing.eu-central-1.amazonaws.com",
                           "us-east-2": "api.pricing.us-east-2.amazonaws.com",
                           "us-east-1": "api.pricing.us-east-1.amazonaws.com", "cn-northwest-1": "api.pricing.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "api.pricing.ap-south-1.amazonaws.com", "eu-north-1": "api.pricing.eu-north-1.amazonaws.com", "ap-northeast-2": "api.pricing.ap-northeast-2.amazonaws.com",
                           "us-west-1": "api.pricing.us-west-1.amazonaws.com", "us-gov-east-1": "api.pricing.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "api.pricing.eu-west-3.amazonaws.com", "cn-north-1": "api.pricing.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "api.pricing.sa-east-1.amazonaws.com",
                           "eu-west-1": "api.pricing.eu-west-1.amazonaws.com", "us-gov-west-1": "api.pricing.us-gov-west-1.amazonaws.com", "ap-southeast-2": "api.pricing.ap-southeast-2.amazonaws.com", "ca-central-1": "api.pricing.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "api.pricing.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "api.pricing.ap-southeast-1.amazonaws.com",
      "us-west-2": "api.pricing.us-west-2.amazonaws.com",
      "eu-west-2": "api.pricing.eu-west-2.amazonaws.com",
      "ap-northeast-3": "api.pricing.ap-northeast-3.amazonaws.com",
      "eu-central-1": "api.pricing.eu-central-1.amazonaws.com",
      "us-east-2": "api.pricing.us-east-2.amazonaws.com",
      "us-east-1": "api.pricing.us-east-1.amazonaws.com",
      "cn-northwest-1": "api.pricing.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "api.pricing.ap-south-1.amazonaws.com",
      "eu-north-1": "api.pricing.eu-north-1.amazonaws.com",
      "ap-northeast-2": "api.pricing.ap-northeast-2.amazonaws.com",
      "us-west-1": "api.pricing.us-west-1.amazonaws.com",
      "us-gov-east-1": "api.pricing.us-gov-east-1.amazonaws.com",
      "eu-west-3": "api.pricing.eu-west-3.amazonaws.com",
      "cn-north-1": "api.pricing.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "api.pricing.sa-east-1.amazonaws.com",
      "eu-west-1": "api.pricing.eu-west-1.amazonaws.com",
      "us-gov-west-1": "api.pricing.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "api.pricing.ap-southeast-2.amazonaws.com",
      "ca-central-1": "api.pricing.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "pricing"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_DescribeServices_605918 = ref object of OpenApiRestCall_605580
proc url_DescribeServices_605920(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeServices_605919(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns the metadata for one service or a list of the metadata for all services. Use this without a service code to get the service codes for all services. Use it with a service code, such as <code>AmazonEC2</code>, to get information specific to that service, such as the attribute names available for that service. For example, some of the attribute names available for EC2 are <code>volumeType</code>, <code>maxIopsVolume</code>, <code>operation</code>, <code>locationType</code>, and <code>instanceCapacity10xlarge</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606032 = query.getOrDefault("MaxResults")
  valid_606032 = validateParameter(valid_606032, JString, required = false,
                                 default = nil)
  if valid_606032 != nil:
    section.add "MaxResults", valid_606032
  var valid_606033 = query.getOrDefault("NextToken")
  valid_606033 = validateParameter(valid_606033, JString, required = false,
                                 default = nil)
  if valid_606033 != nil:
    section.add "NextToken", valid_606033
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606047 = header.getOrDefault("X-Amz-Target")
  valid_606047 = validateParameter(valid_606047, JString, required = true, default = newJString(
      "AWSPriceListService.DescribeServices"))
  if valid_606047 != nil:
    section.add "X-Amz-Target", valid_606047
  var valid_606048 = header.getOrDefault("X-Amz-Signature")
  valid_606048 = validateParameter(valid_606048, JString, required = false,
                                 default = nil)
  if valid_606048 != nil:
    section.add "X-Amz-Signature", valid_606048
  var valid_606049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606049 = validateParameter(valid_606049, JString, required = false,
                                 default = nil)
  if valid_606049 != nil:
    section.add "X-Amz-Content-Sha256", valid_606049
  var valid_606050 = header.getOrDefault("X-Amz-Date")
  valid_606050 = validateParameter(valid_606050, JString, required = false,
                                 default = nil)
  if valid_606050 != nil:
    section.add "X-Amz-Date", valid_606050
  var valid_606051 = header.getOrDefault("X-Amz-Credential")
  valid_606051 = validateParameter(valid_606051, JString, required = false,
                                 default = nil)
  if valid_606051 != nil:
    section.add "X-Amz-Credential", valid_606051
  var valid_606052 = header.getOrDefault("X-Amz-Security-Token")
  valid_606052 = validateParameter(valid_606052, JString, required = false,
                                 default = nil)
  if valid_606052 != nil:
    section.add "X-Amz-Security-Token", valid_606052
  var valid_606053 = header.getOrDefault("X-Amz-Algorithm")
  valid_606053 = validateParameter(valid_606053, JString, required = false,
                                 default = nil)
  if valid_606053 != nil:
    section.add "X-Amz-Algorithm", valid_606053
  var valid_606054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606054 = validateParameter(valid_606054, JString, required = false,
                                 default = nil)
  if valid_606054 != nil:
    section.add "X-Amz-SignedHeaders", valid_606054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606078: Call_DescribeServices_605918; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the metadata for one service or a list of the metadata for all services. Use this without a service code to get the service codes for all services. Use it with a service code, such as <code>AmazonEC2</code>, to get information specific to that service, such as the attribute names available for that service. For example, some of the attribute names available for EC2 are <code>volumeType</code>, <code>maxIopsVolume</code>, <code>operation</code>, <code>locationType</code>, and <code>instanceCapacity10xlarge</code>.
  ## 
  let valid = call_606078.validator(path, query, header, formData, body)
  let scheme = call_606078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606078.url(scheme.get, call_606078.host, call_606078.base,
                         call_606078.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606078, url, valid)

proc call*(call_606149: Call_DescribeServices_605918; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeServices
  ## Returns the metadata for one service or a list of the metadata for all services. Use this without a service code to get the service codes for all services. Use it with a service code, such as <code>AmazonEC2</code>, to get information specific to that service, such as the attribute names available for that service. For example, some of the attribute names available for EC2 are <code>volumeType</code>, <code>maxIopsVolume</code>, <code>operation</code>, <code>locationType</code>, and <code>instanceCapacity10xlarge</code>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606150 = newJObject()
  var body_606152 = newJObject()
  add(query_606150, "MaxResults", newJString(MaxResults))
  add(query_606150, "NextToken", newJString(NextToken))
  if body != nil:
    body_606152 = body
  result = call_606149.call(nil, query_606150, nil, nil, body_606152)

var describeServices* = Call_DescribeServices_605918(name: "describeServices",
    meth: HttpMethod.HttpPost, host: "api.pricing.amazonaws.com",
    route: "/#X-Amz-Target=AWSPriceListService.DescribeServices",
    validator: validate_DescribeServices_605919, base: "/",
    url: url_DescribeServices_605920, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAttributeValues_606191 = ref object of OpenApiRestCall_605580
proc url_GetAttributeValues_606193(protocol: Scheme; host: string; base: string;
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

proc validate_GetAttributeValues_606192(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns a list of attribute values. Attibutes are similar to the details in a Price List API offer file. For a list of available attributes, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/reading-an-offer.html#pps-defs">Offer File Definitions</a> in the <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/billing-what-is.html">AWS Billing and Cost Management User Guide</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606194 = query.getOrDefault("MaxResults")
  valid_606194 = validateParameter(valid_606194, JString, required = false,
                                 default = nil)
  if valid_606194 != nil:
    section.add "MaxResults", valid_606194
  var valid_606195 = query.getOrDefault("NextToken")
  valid_606195 = validateParameter(valid_606195, JString, required = false,
                                 default = nil)
  if valid_606195 != nil:
    section.add "NextToken", valid_606195
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606196 = header.getOrDefault("X-Amz-Target")
  valid_606196 = validateParameter(valid_606196, JString, required = true, default = newJString(
      "AWSPriceListService.GetAttributeValues"))
  if valid_606196 != nil:
    section.add "X-Amz-Target", valid_606196
  var valid_606197 = header.getOrDefault("X-Amz-Signature")
  valid_606197 = validateParameter(valid_606197, JString, required = false,
                                 default = nil)
  if valid_606197 != nil:
    section.add "X-Amz-Signature", valid_606197
  var valid_606198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606198 = validateParameter(valid_606198, JString, required = false,
                                 default = nil)
  if valid_606198 != nil:
    section.add "X-Amz-Content-Sha256", valid_606198
  var valid_606199 = header.getOrDefault("X-Amz-Date")
  valid_606199 = validateParameter(valid_606199, JString, required = false,
                                 default = nil)
  if valid_606199 != nil:
    section.add "X-Amz-Date", valid_606199
  var valid_606200 = header.getOrDefault("X-Amz-Credential")
  valid_606200 = validateParameter(valid_606200, JString, required = false,
                                 default = nil)
  if valid_606200 != nil:
    section.add "X-Amz-Credential", valid_606200
  var valid_606201 = header.getOrDefault("X-Amz-Security-Token")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Security-Token", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Algorithm")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Algorithm", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-SignedHeaders", valid_606203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606205: Call_GetAttributeValues_606191; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of attribute values. Attibutes are similar to the details in a Price List API offer file. For a list of available attributes, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/reading-an-offer.html#pps-defs">Offer File Definitions</a> in the <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/billing-what-is.html">AWS Billing and Cost Management User Guide</a>.
  ## 
  let valid = call_606205.validator(path, query, header, formData, body)
  let scheme = call_606205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606205.url(scheme.get, call_606205.host, call_606205.base,
                         call_606205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606205, url, valid)

proc call*(call_606206: Call_GetAttributeValues_606191; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getAttributeValues
  ## Returns a list of attribute values. Attibutes are similar to the details in a Price List API offer file. For a list of available attributes, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/reading-an-offer.html#pps-defs">Offer File Definitions</a> in the <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/billing-what-is.html">AWS Billing and Cost Management User Guide</a>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606207 = newJObject()
  var body_606208 = newJObject()
  add(query_606207, "MaxResults", newJString(MaxResults))
  add(query_606207, "NextToken", newJString(NextToken))
  if body != nil:
    body_606208 = body
  result = call_606206.call(nil, query_606207, nil, nil, body_606208)

var getAttributeValues* = Call_GetAttributeValues_606191(
    name: "getAttributeValues", meth: HttpMethod.HttpPost,
    host: "api.pricing.amazonaws.com",
    route: "/#X-Amz-Target=AWSPriceListService.GetAttributeValues",
    validator: validate_GetAttributeValues_606192, base: "/",
    url: url_GetAttributeValues_606193, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProducts_606209 = ref object of OpenApiRestCall_605580
proc url_GetProducts_606211(protocol: Scheme; host: string; base: string;
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

proc validate_GetProducts_606210(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of all products that match the filter criteria.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606212 = query.getOrDefault("MaxResults")
  valid_606212 = validateParameter(valid_606212, JString, required = false,
                                 default = nil)
  if valid_606212 != nil:
    section.add "MaxResults", valid_606212
  var valid_606213 = query.getOrDefault("NextToken")
  valid_606213 = validateParameter(valid_606213, JString, required = false,
                                 default = nil)
  if valid_606213 != nil:
    section.add "NextToken", valid_606213
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606214 = header.getOrDefault("X-Amz-Target")
  valid_606214 = validateParameter(valid_606214, JString, required = true, default = newJString(
      "AWSPriceListService.GetProducts"))
  if valid_606214 != nil:
    section.add "X-Amz-Target", valid_606214
  var valid_606215 = header.getOrDefault("X-Amz-Signature")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-Signature", valid_606215
  var valid_606216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Content-Sha256", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Date")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Date", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Credential")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Credential", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Security-Token")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Security-Token", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Algorithm")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Algorithm", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-SignedHeaders", valid_606221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606223: Call_GetProducts_606209; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all products that match the filter criteria.
  ## 
  let valid = call_606223.validator(path, query, header, formData, body)
  let scheme = call_606223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606223.url(scheme.get, call_606223.host, call_606223.base,
                         call_606223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606223, url, valid)

proc call*(call_606224: Call_GetProducts_606209; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getProducts
  ## Returns a list of all products that match the filter criteria.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606225 = newJObject()
  var body_606226 = newJObject()
  add(query_606225, "MaxResults", newJString(MaxResults))
  add(query_606225, "NextToken", newJString(NextToken))
  if body != nil:
    body_606226 = body
  result = call_606224.call(nil, query_606225, nil, nil, body_606226)

var getProducts* = Call_GetProducts_606209(name: "getProducts",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.pricing.amazonaws.com", route: "/#X-Amz-Target=AWSPriceListService.GetProducts",
                                        validator: validate_GetProducts_606210,
                                        base: "/", url: url_GetProducts_606211,
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
  result = newRecallable(call, url, headers, $input.getOrDefault("body"))
  result.atozSign(input.getOrDefault("query"), SHA256)
