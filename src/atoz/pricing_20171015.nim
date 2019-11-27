
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

  OpenApiRestCall_599359 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599359](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599359): Option[Scheme] {.used.} =
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
  Call_DescribeServices_599696 = ref object of OpenApiRestCall_599359
proc url_DescribeServices_599698(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeServices_599697(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns the metadata for one service or a list of the metadata for all services. Use this without a service code to get the service codes for all services. Use it with a service code, such as <code>AmazonEC2</code>, to get information specific to that service, such as the attribute names available for that service. For example, some of the attribute names available for EC2 are <code>volumeType</code>, <code>maxIopsVolume</code>, <code>operation</code>, <code>locationType</code>, and <code>instanceCapacity10xlarge</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_599810 = query.getOrDefault("NextToken")
  valid_599810 = validateParameter(valid_599810, JString, required = false,
                                 default = nil)
  if valid_599810 != nil:
    section.add "NextToken", valid_599810
  var valid_599811 = query.getOrDefault("MaxResults")
  valid_599811 = validateParameter(valid_599811, JString, required = false,
                                 default = nil)
  if valid_599811 != nil:
    section.add "MaxResults", valid_599811
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599812 = header.getOrDefault("X-Amz-Date")
  valid_599812 = validateParameter(valid_599812, JString, required = false,
                                 default = nil)
  if valid_599812 != nil:
    section.add "X-Amz-Date", valid_599812
  var valid_599813 = header.getOrDefault("X-Amz-Security-Token")
  valid_599813 = validateParameter(valid_599813, JString, required = false,
                                 default = nil)
  if valid_599813 != nil:
    section.add "X-Amz-Security-Token", valid_599813
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599827 = header.getOrDefault("X-Amz-Target")
  valid_599827 = validateParameter(valid_599827, JString, required = true, default = newJString(
      "AWSPriceListService.DescribeServices"))
  if valid_599827 != nil:
    section.add "X-Amz-Target", valid_599827
  var valid_599828 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599828 = validateParameter(valid_599828, JString, required = false,
                                 default = nil)
  if valid_599828 != nil:
    section.add "X-Amz-Content-Sha256", valid_599828
  var valid_599829 = header.getOrDefault("X-Amz-Algorithm")
  valid_599829 = validateParameter(valid_599829, JString, required = false,
                                 default = nil)
  if valid_599829 != nil:
    section.add "X-Amz-Algorithm", valid_599829
  var valid_599830 = header.getOrDefault("X-Amz-Signature")
  valid_599830 = validateParameter(valid_599830, JString, required = false,
                                 default = nil)
  if valid_599830 != nil:
    section.add "X-Amz-Signature", valid_599830
  var valid_599831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599831 = validateParameter(valid_599831, JString, required = false,
                                 default = nil)
  if valid_599831 != nil:
    section.add "X-Amz-SignedHeaders", valid_599831
  var valid_599832 = header.getOrDefault("X-Amz-Credential")
  valid_599832 = validateParameter(valid_599832, JString, required = false,
                                 default = nil)
  if valid_599832 != nil:
    section.add "X-Amz-Credential", valid_599832
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599856: Call_DescribeServices_599696; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the metadata for one service or a list of the metadata for all services. Use this without a service code to get the service codes for all services. Use it with a service code, such as <code>AmazonEC2</code>, to get information specific to that service, such as the attribute names available for that service. For example, some of the attribute names available for EC2 are <code>volumeType</code>, <code>maxIopsVolume</code>, <code>operation</code>, <code>locationType</code>, and <code>instanceCapacity10xlarge</code>.
  ## 
  let valid = call_599856.validator(path, query, header, formData, body)
  let scheme = call_599856.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599856.url(scheme.get, call_599856.host, call_599856.base,
                         call_599856.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599856, url, valid)

proc call*(call_599927: Call_DescribeServices_599696; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeServices
  ## Returns the metadata for one service or a list of the metadata for all services. Use this without a service code to get the service codes for all services. Use it with a service code, such as <code>AmazonEC2</code>, to get information specific to that service, such as the attribute names available for that service. For example, some of the attribute names available for EC2 are <code>volumeType</code>, <code>maxIopsVolume</code>, <code>operation</code>, <code>locationType</code>, and <code>instanceCapacity10xlarge</code>.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_599928 = newJObject()
  var body_599930 = newJObject()
  add(query_599928, "NextToken", newJString(NextToken))
  if body != nil:
    body_599930 = body
  add(query_599928, "MaxResults", newJString(MaxResults))
  result = call_599927.call(nil, query_599928, nil, nil, body_599930)

var describeServices* = Call_DescribeServices_599696(name: "describeServices",
    meth: HttpMethod.HttpPost, host: "api.pricing.amazonaws.com",
    route: "/#X-Amz-Target=AWSPriceListService.DescribeServices",
    validator: validate_DescribeServices_599697, base: "/",
    url: url_DescribeServices_599698, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAttributeValues_599969 = ref object of OpenApiRestCall_599359
proc url_GetAttributeValues_599971(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAttributeValues_599970(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns a list of attribute values. Attibutes are similar to the details in a Price List API offer file. For a list of available attributes, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/reading-an-offer.html#pps-defs">Offer File Definitions</a> in the <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/billing-what-is.html">AWS Billing and Cost Management User Guide</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_599972 = query.getOrDefault("NextToken")
  valid_599972 = validateParameter(valid_599972, JString, required = false,
                                 default = nil)
  if valid_599972 != nil:
    section.add "NextToken", valid_599972
  var valid_599973 = query.getOrDefault("MaxResults")
  valid_599973 = validateParameter(valid_599973, JString, required = false,
                                 default = nil)
  if valid_599973 != nil:
    section.add "MaxResults", valid_599973
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599974 = header.getOrDefault("X-Amz-Date")
  valid_599974 = validateParameter(valid_599974, JString, required = false,
                                 default = nil)
  if valid_599974 != nil:
    section.add "X-Amz-Date", valid_599974
  var valid_599975 = header.getOrDefault("X-Amz-Security-Token")
  valid_599975 = validateParameter(valid_599975, JString, required = false,
                                 default = nil)
  if valid_599975 != nil:
    section.add "X-Amz-Security-Token", valid_599975
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599976 = header.getOrDefault("X-Amz-Target")
  valid_599976 = validateParameter(valid_599976, JString, required = true, default = newJString(
      "AWSPriceListService.GetAttributeValues"))
  if valid_599976 != nil:
    section.add "X-Amz-Target", valid_599976
  var valid_599977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599977 = validateParameter(valid_599977, JString, required = false,
                                 default = nil)
  if valid_599977 != nil:
    section.add "X-Amz-Content-Sha256", valid_599977
  var valid_599978 = header.getOrDefault("X-Amz-Algorithm")
  valid_599978 = validateParameter(valid_599978, JString, required = false,
                                 default = nil)
  if valid_599978 != nil:
    section.add "X-Amz-Algorithm", valid_599978
  var valid_599979 = header.getOrDefault("X-Amz-Signature")
  valid_599979 = validateParameter(valid_599979, JString, required = false,
                                 default = nil)
  if valid_599979 != nil:
    section.add "X-Amz-Signature", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-SignedHeaders", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Credential")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Credential", valid_599981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599983: Call_GetAttributeValues_599969; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of attribute values. Attibutes are similar to the details in a Price List API offer file. For a list of available attributes, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/reading-an-offer.html#pps-defs">Offer File Definitions</a> in the <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/billing-what-is.html">AWS Billing and Cost Management User Guide</a>.
  ## 
  let valid = call_599983.validator(path, query, header, formData, body)
  let scheme = call_599983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599983.url(scheme.get, call_599983.host, call_599983.base,
                         call_599983.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599983, url, valid)

proc call*(call_599984: Call_GetAttributeValues_599969; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getAttributeValues
  ## Returns a list of attribute values. Attibutes are similar to the details in a Price List API offer file. For a list of available attributes, see <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/reading-an-offer.html#pps-defs">Offer File Definitions</a> in the <a href="http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/billing-what-is.html">AWS Billing and Cost Management User Guide</a>.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_599985 = newJObject()
  var body_599986 = newJObject()
  add(query_599985, "NextToken", newJString(NextToken))
  if body != nil:
    body_599986 = body
  add(query_599985, "MaxResults", newJString(MaxResults))
  result = call_599984.call(nil, query_599985, nil, nil, body_599986)

var getAttributeValues* = Call_GetAttributeValues_599969(
    name: "getAttributeValues", meth: HttpMethod.HttpPost,
    host: "api.pricing.amazonaws.com",
    route: "/#X-Amz-Target=AWSPriceListService.GetAttributeValues",
    validator: validate_GetAttributeValues_599970, base: "/",
    url: url_GetAttributeValues_599971, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProducts_599987 = ref object of OpenApiRestCall_599359
proc url_GetProducts_599989(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetProducts_599988(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of all products that match the filter criteria.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_599990 = query.getOrDefault("NextToken")
  valid_599990 = validateParameter(valid_599990, JString, required = false,
                                 default = nil)
  if valid_599990 != nil:
    section.add "NextToken", valid_599990
  var valid_599991 = query.getOrDefault("MaxResults")
  valid_599991 = validateParameter(valid_599991, JString, required = false,
                                 default = nil)
  if valid_599991 != nil:
    section.add "MaxResults", valid_599991
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599992 = header.getOrDefault("X-Amz-Date")
  valid_599992 = validateParameter(valid_599992, JString, required = false,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-Date", valid_599992
  var valid_599993 = header.getOrDefault("X-Amz-Security-Token")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-Security-Token", valid_599993
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599994 = header.getOrDefault("X-Amz-Target")
  valid_599994 = validateParameter(valid_599994, JString, required = true, default = newJString(
      "AWSPriceListService.GetProducts"))
  if valid_599994 != nil:
    section.add "X-Amz-Target", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Content-Sha256", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Algorithm")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Algorithm", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Signature")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Signature", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-SignedHeaders", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Credential")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Credential", valid_599999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600001: Call_GetProducts_599987; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all products that match the filter criteria.
  ## 
  let valid = call_600001.validator(path, query, header, formData, body)
  let scheme = call_600001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600001.url(scheme.get, call_600001.host, call_600001.base,
                         call_600001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600001, url, valid)

proc call*(call_600002: Call_GetProducts_599987; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## getProducts
  ## Returns a list of all products that match the filter criteria.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600003 = newJObject()
  var body_600004 = newJObject()
  add(query_600003, "NextToken", newJString(NextToken))
  if body != nil:
    body_600004 = body
  add(query_600003, "MaxResults", newJString(MaxResults))
  result = call_600002.call(nil, query_600003, nil, nil, body_600004)

var getProducts* = Call_GetProducts_599987(name: "getProducts",
                                        meth: HttpMethod.HttpPost,
                                        host: "api.pricing.amazonaws.com", route: "/#X-Amz-Target=AWSPriceListService.GetProducts",
                                        validator: validate_GetProducts_599988,
                                        base: "/", url: url_GetProducts_599989,
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
