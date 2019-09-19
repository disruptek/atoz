
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon CloudFront
## version: 2019-03-26
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon CloudFront</fullname> <p>This is the <i>Amazon CloudFront API Reference</i>. This guide is for developers who need detailed information about CloudFront API actions, data types, and errors. For detailed information about CloudFront features, see the <i>Amazon CloudFront Developer Guide</i>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/cloudfront/
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

  OpenApiRestCall_772597 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772597](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772597): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"cn-northwest-1": "cloudfront.cn-northwest-1.amazonaws.com.cn", "cn-north-1": "cloudfront.cn-north-1.amazonaws.com.cn"}.toTable, Scheme.Https: {
      "cn-northwest-1": "cloudfront.cn-northwest-1.amazonaws.com.cn",
      "cn-north-1": "cloudfront.cn-north-1.amazonaws.com.cn"}.toTable}.toTable
const
  awsServiceName = "cloudfront"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateCloudFrontOriginAccessIdentity20190326_773190 = ref object of OpenApiRestCall_772597
proc url_CreateCloudFrontOriginAccessIdentity20190326_773192(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateCloudFrontOriginAccessIdentity20190326_773191(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
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
  var valid_773193 = header.getOrDefault("X-Amz-Date")
  valid_773193 = validateParameter(valid_773193, JString, required = false,
                                 default = nil)
  if valid_773193 != nil:
    section.add "X-Amz-Date", valid_773193
  var valid_773194 = header.getOrDefault("X-Amz-Security-Token")
  valid_773194 = validateParameter(valid_773194, JString, required = false,
                                 default = nil)
  if valid_773194 != nil:
    section.add "X-Amz-Security-Token", valid_773194
  var valid_773195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773195 = validateParameter(valid_773195, JString, required = false,
                                 default = nil)
  if valid_773195 != nil:
    section.add "X-Amz-Content-Sha256", valid_773195
  var valid_773196 = header.getOrDefault("X-Amz-Algorithm")
  valid_773196 = validateParameter(valid_773196, JString, required = false,
                                 default = nil)
  if valid_773196 != nil:
    section.add "X-Amz-Algorithm", valid_773196
  var valid_773197 = header.getOrDefault("X-Amz-Signature")
  valid_773197 = validateParameter(valid_773197, JString, required = false,
                                 default = nil)
  if valid_773197 != nil:
    section.add "X-Amz-Signature", valid_773197
  var valid_773198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773198 = validateParameter(valid_773198, JString, required = false,
                                 default = nil)
  if valid_773198 != nil:
    section.add "X-Amz-SignedHeaders", valid_773198
  var valid_773199 = header.getOrDefault("X-Amz-Credential")
  valid_773199 = validateParameter(valid_773199, JString, required = false,
                                 default = nil)
  if valid_773199 != nil:
    section.add "X-Amz-Credential", valid_773199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773201: Call_CreateCloudFrontOriginAccessIdentity20190326_773190;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
  ## 
  let valid = call_773201.validator(path, query, header, formData, body)
  let scheme = call_773201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773201.url(scheme.get, call_773201.host, call_773201.base,
                         call_773201.route, valid.getOrDefault("path"))
  result = hook(call_773201, url, valid)

proc call*(call_773202: Call_CreateCloudFrontOriginAccessIdentity20190326_773190;
          body: JsonNode): Recallable =
  ## createCloudFrontOriginAccessIdentity20190326
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
  ##   body: JObject (required)
  var body_773203 = newJObject()
  if body != nil:
    body_773203 = body
  result = call_773202.call(nil, nil, nil, nil, body_773203)

var createCloudFrontOriginAccessIdentity20190326* = Call_CreateCloudFrontOriginAccessIdentity20190326_773190(
    name: "createCloudFrontOriginAccessIdentity20190326",
    meth: HttpMethod.HttpPost, host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/origin-access-identity/cloudfront",
    validator: validate_CreateCloudFrontOriginAccessIdentity20190326_773191,
    base: "/", url: url_CreateCloudFrontOriginAccessIdentity20190326_773192,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCloudFrontOriginAccessIdentities20190326_772933 = ref object of OpenApiRestCall_772597
proc url_ListCloudFrontOriginAccessIdentities20190326_772935(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListCloudFrontOriginAccessIdentities20190326_772934(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists origin access identities.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this when paginating results to indicate where to begin in your list of origin access identities. The results include identities in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last identity on that page).
  ##   MaxItems: JString
  ##           : The maximum number of origin access identities you want in the response body. 
  section = newJObject()
  var valid_773047 = query.getOrDefault("Marker")
  valid_773047 = validateParameter(valid_773047, JString, required = false,
                                 default = nil)
  if valid_773047 != nil:
    section.add "Marker", valid_773047
  var valid_773048 = query.getOrDefault("MaxItems")
  valid_773048 = validateParameter(valid_773048, JString, required = false,
                                 default = nil)
  if valid_773048 != nil:
    section.add "MaxItems", valid_773048
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
  var valid_773049 = header.getOrDefault("X-Amz-Date")
  valid_773049 = validateParameter(valid_773049, JString, required = false,
                                 default = nil)
  if valid_773049 != nil:
    section.add "X-Amz-Date", valid_773049
  var valid_773050 = header.getOrDefault("X-Amz-Security-Token")
  valid_773050 = validateParameter(valid_773050, JString, required = false,
                                 default = nil)
  if valid_773050 != nil:
    section.add "X-Amz-Security-Token", valid_773050
  var valid_773051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773051 = validateParameter(valid_773051, JString, required = false,
                                 default = nil)
  if valid_773051 != nil:
    section.add "X-Amz-Content-Sha256", valid_773051
  var valid_773052 = header.getOrDefault("X-Amz-Algorithm")
  valid_773052 = validateParameter(valid_773052, JString, required = false,
                                 default = nil)
  if valid_773052 != nil:
    section.add "X-Amz-Algorithm", valid_773052
  var valid_773053 = header.getOrDefault("X-Amz-Signature")
  valid_773053 = validateParameter(valid_773053, JString, required = false,
                                 default = nil)
  if valid_773053 != nil:
    section.add "X-Amz-Signature", valid_773053
  var valid_773054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773054 = validateParameter(valid_773054, JString, required = false,
                                 default = nil)
  if valid_773054 != nil:
    section.add "X-Amz-SignedHeaders", valid_773054
  var valid_773055 = header.getOrDefault("X-Amz-Credential")
  valid_773055 = validateParameter(valid_773055, JString, required = false,
                                 default = nil)
  if valid_773055 != nil:
    section.add "X-Amz-Credential", valid_773055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773078: Call_ListCloudFrontOriginAccessIdentities20190326_772933;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists origin access identities.
  ## 
  let valid = call_773078.validator(path, query, header, formData, body)
  let scheme = call_773078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773078.url(scheme.get, call_773078.host, call_773078.base,
                         call_773078.route, valid.getOrDefault("path"))
  result = hook(call_773078, url, valid)

proc call*(call_773149: Call_ListCloudFrontOriginAccessIdentities20190326_772933;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listCloudFrontOriginAccessIdentities20190326
  ## Lists origin access identities.
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of origin access identities. The results include identities in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last identity on that page).
  ##   MaxItems: string
  ##           : The maximum number of origin access identities you want in the response body. 
  var query_773150 = newJObject()
  add(query_773150, "Marker", newJString(Marker))
  add(query_773150, "MaxItems", newJString(MaxItems))
  result = call_773149.call(nil, query_773150, nil, nil, nil)

var listCloudFrontOriginAccessIdentities20190326* = Call_ListCloudFrontOriginAccessIdentities20190326_772933(
    name: "listCloudFrontOriginAccessIdentities20190326",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/origin-access-identity/cloudfront",
    validator: validate_ListCloudFrontOriginAccessIdentities20190326_772934,
    base: "/", url: url_ListCloudFrontOriginAccessIdentities20190326_772935,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDistribution20190326_773219 = ref object of OpenApiRestCall_772597
proc url_CreateDistribution20190326_773221(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateDistribution20190326_773220(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new web distribution. You create a CloudFront distribution to tell CloudFront where you want content to be delivered from, and the details about how to track and manage content delivery. Send a <code>POST</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.</p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_UpdateDistribution.html">UpdateDistribution</a>, follow the steps included in the documentation to get the current configuration and then make your updates. This helps to make sure that you include all of the required fields. To view a summary, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important>
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
  var valid_773222 = header.getOrDefault("X-Amz-Date")
  valid_773222 = validateParameter(valid_773222, JString, required = false,
                                 default = nil)
  if valid_773222 != nil:
    section.add "X-Amz-Date", valid_773222
  var valid_773223 = header.getOrDefault("X-Amz-Security-Token")
  valid_773223 = validateParameter(valid_773223, JString, required = false,
                                 default = nil)
  if valid_773223 != nil:
    section.add "X-Amz-Security-Token", valid_773223
  var valid_773224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773224 = validateParameter(valid_773224, JString, required = false,
                                 default = nil)
  if valid_773224 != nil:
    section.add "X-Amz-Content-Sha256", valid_773224
  var valid_773225 = header.getOrDefault("X-Amz-Algorithm")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "X-Amz-Algorithm", valid_773225
  var valid_773226 = header.getOrDefault("X-Amz-Signature")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "X-Amz-Signature", valid_773226
  var valid_773227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "X-Amz-SignedHeaders", valid_773227
  var valid_773228 = header.getOrDefault("X-Amz-Credential")
  valid_773228 = validateParameter(valid_773228, JString, required = false,
                                 default = nil)
  if valid_773228 != nil:
    section.add "X-Amz-Credential", valid_773228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773230: Call_CreateDistribution20190326_773219; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new web distribution. You create a CloudFront distribution to tell CloudFront where you want content to be delivered from, and the details about how to track and manage content delivery. Send a <code>POST</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.</p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_UpdateDistribution.html">UpdateDistribution</a>, follow the steps included in the documentation to get the current configuration and then make your updates. This helps to make sure that you include all of the required fields. To view a summary, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important>
  ## 
  let valid = call_773230.validator(path, query, header, formData, body)
  let scheme = call_773230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773230.url(scheme.get, call_773230.host, call_773230.base,
                         call_773230.route, valid.getOrDefault("path"))
  result = hook(call_773230, url, valid)

proc call*(call_773231: Call_CreateDistribution20190326_773219; body: JsonNode): Recallable =
  ## createDistribution20190326
  ## <p>Creates a new web distribution. You create a CloudFront distribution to tell CloudFront where you want content to be delivered from, and the details about how to track and manage content delivery. Send a <code>POST</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.</p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_UpdateDistribution.html">UpdateDistribution</a>, follow the steps included in the documentation to get the current configuration and then make your updates. This helps to make sure that you include all of the required fields. To view a summary, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important>
  ##   body: JObject (required)
  var body_773232 = newJObject()
  if body != nil:
    body_773232 = body
  result = call_773231.call(nil, nil, nil, nil, body_773232)

var createDistribution20190326* = Call_CreateDistribution20190326_773219(
    name: "createDistribution20190326", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/distribution",
    validator: validate_CreateDistribution20190326_773220, base: "/",
    url: url_CreateDistribution20190326_773221,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDistributions20190326_773204 = ref object of OpenApiRestCall_772597
proc url_ListDistributions20190326_773206(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDistributions20190326_773205(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List CloudFront distributions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this when paginating results to indicate where to begin in your list of distributions. The results include distributions in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last distribution on that page).
  ##   MaxItems: JString
  ##           : The maximum number of distributions you want in the response body.
  section = newJObject()
  var valid_773207 = query.getOrDefault("Marker")
  valid_773207 = validateParameter(valid_773207, JString, required = false,
                                 default = nil)
  if valid_773207 != nil:
    section.add "Marker", valid_773207
  var valid_773208 = query.getOrDefault("MaxItems")
  valid_773208 = validateParameter(valid_773208, JString, required = false,
                                 default = nil)
  if valid_773208 != nil:
    section.add "MaxItems", valid_773208
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
  var valid_773209 = header.getOrDefault("X-Amz-Date")
  valid_773209 = validateParameter(valid_773209, JString, required = false,
                                 default = nil)
  if valid_773209 != nil:
    section.add "X-Amz-Date", valid_773209
  var valid_773210 = header.getOrDefault("X-Amz-Security-Token")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "X-Amz-Security-Token", valid_773210
  var valid_773211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-Content-Sha256", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-Algorithm")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-Algorithm", valid_773212
  var valid_773213 = header.getOrDefault("X-Amz-Signature")
  valid_773213 = validateParameter(valid_773213, JString, required = false,
                                 default = nil)
  if valid_773213 != nil:
    section.add "X-Amz-Signature", valid_773213
  var valid_773214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773214 = validateParameter(valid_773214, JString, required = false,
                                 default = nil)
  if valid_773214 != nil:
    section.add "X-Amz-SignedHeaders", valid_773214
  var valid_773215 = header.getOrDefault("X-Amz-Credential")
  valid_773215 = validateParameter(valid_773215, JString, required = false,
                                 default = nil)
  if valid_773215 != nil:
    section.add "X-Amz-Credential", valid_773215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773216: Call_ListDistributions20190326_773204; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List CloudFront distributions.
  ## 
  let valid = call_773216.validator(path, query, header, formData, body)
  let scheme = call_773216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773216.url(scheme.get, call_773216.host, call_773216.base,
                         call_773216.route, valid.getOrDefault("path"))
  result = hook(call_773216, url, valid)

proc call*(call_773217: Call_ListDistributions20190326_773204; Marker: string = "";
          MaxItems: string = ""): Recallable =
  ## listDistributions20190326
  ## List CloudFront distributions.
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of distributions. The results include distributions in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last distribution on that page).
  ##   MaxItems: string
  ##           : The maximum number of distributions you want in the response body.
  var query_773218 = newJObject()
  add(query_773218, "Marker", newJString(Marker))
  add(query_773218, "MaxItems", newJString(MaxItems))
  result = call_773217.call(nil, query_773218, nil, nil, nil)

var listDistributions20190326* = Call_ListDistributions20190326_773204(
    name: "listDistributions20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/distribution",
    validator: validate_ListDistributions20190326_773205, base: "/",
    url: url_ListDistributions20190326_773206,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDistributionWithTags20190326_773233 = ref object of OpenApiRestCall_772597
proc url_CreateDistributionWithTags20190326_773235(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateDistributionWithTags20190326_773234(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new distribution with tags.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   WithTags: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `WithTags` field"
  var valid_773236 = query.getOrDefault("WithTags")
  valid_773236 = validateParameter(valid_773236, JBool, required = true, default = nil)
  if valid_773236 != nil:
    section.add "WithTags", valid_773236
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
  var valid_773237 = header.getOrDefault("X-Amz-Date")
  valid_773237 = validateParameter(valid_773237, JString, required = false,
                                 default = nil)
  if valid_773237 != nil:
    section.add "X-Amz-Date", valid_773237
  var valid_773238 = header.getOrDefault("X-Amz-Security-Token")
  valid_773238 = validateParameter(valid_773238, JString, required = false,
                                 default = nil)
  if valid_773238 != nil:
    section.add "X-Amz-Security-Token", valid_773238
  var valid_773239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773239 = validateParameter(valid_773239, JString, required = false,
                                 default = nil)
  if valid_773239 != nil:
    section.add "X-Amz-Content-Sha256", valid_773239
  var valid_773240 = header.getOrDefault("X-Amz-Algorithm")
  valid_773240 = validateParameter(valid_773240, JString, required = false,
                                 default = nil)
  if valid_773240 != nil:
    section.add "X-Amz-Algorithm", valid_773240
  var valid_773241 = header.getOrDefault("X-Amz-Signature")
  valid_773241 = validateParameter(valid_773241, JString, required = false,
                                 default = nil)
  if valid_773241 != nil:
    section.add "X-Amz-Signature", valid_773241
  var valid_773242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773242 = validateParameter(valid_773242, JString, required = false,
                                 default = nil)
  if valid_773242 != nil:
    section.add "X-Amz-SignedHeaders", valid_773242
  var valid_773243 = header.getOrDefault("X-Amz-Credential")
  valid_773243 = validateParameter(valid_773243, JString, required = false,
                                 default = nil)
  if valid_773243 != nil:
    section.add "X-Amz-Credential", valid_773243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773245: Call_CreateDistributionWithTags20190326_773233;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a new distribution with tags.
  ## 
  let valid = call_773245.validator(path, query, header, formData, body)
  let scheme = call_773245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773245.url(scheme.get, call_773245.host, call_773245.base,
                         call_773245.route, valid.getOrDefault("path"))
  result = hook(call_773245, url, valid)

proc call*(call_773246: Call_CreateDistributionWithTags20190326_773233;
          WithTags: bool; body: JsonNode): Recallable =
  ## createDistributionWithTags20190326
  ## Create a new distribution with tags.
  ##   WithTags: bool (required)
  ##   body: JObject (required)
  var query_773247 = newJObject()
  var body_773248 = newJObject()
  add(query_773247, "WithTags", newJBool(WithTags))
  if body != nil:
    body_773248 = body
  result = call_773246.call(nil, query_773247, nil, nil, body_773248)

var createDistributionWithTags20190326* = Call_CreateDistributionWithTags20190326_773233(
    name: "createDistributionWithTags20190326", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/distribution#WithTags",
    validator: validate_CreateDistributionWithTags20190326_773234, base: "/",
    url: url_CreateDistributionWithTags20190326_773235,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFieldLevelEncryptionConfig20190326_773264 = ref object of OpenApiRestCall_772597
proc url_CreateFieldLevelEncryptionConfig20190326_773266(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateFieldLevelEncryptionConfig20190326_773265(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new field-level encryption configuration.
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
  var valid_773267 = header.getOrDefault("X-Amz-Date")
  valid_773267 = validateParameter(valid_773267, JString, required = false,
                                 default = nil)
  if valid_773267 != nil:
    section.add "X-Amz-Date", valid_773267
  var valid_773268 = header.getOrDefault("X-Amz-Security-Token")
  valid_773268 = validateParameter(valid_773268, JString, required = false,
                                 default = nil)
  if valid_773268 != nil:
    section.add "X-Amz-Security-Token", valid_773268
  var valid_773269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "X-Amz-Content-Sha256", valid_773269
  var valid_773270 = header.getOrDefault("X-Amz-Algorithm")
  valid_773270 = validateParameter(valid_773270, JString, required = false,
                                 default = nil)
  if valid_773270 != nil:
    section.add "X-Amz-Algorithm", valid_773270
  var valid_773271 = header.getOrDefault("X-Amz-Signature")
  valid_773271 = validateParameter(valid_773271, JString, required = false,
                                 default = nil)
  if valid_773271 != nil:
    section.add "X-Amz-Signature", valid_773271
  var valid_773272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773272 = validateParameter(valid_773272, JString, required = false,
                                 default = nil)
  if valid_773272 != nil:
    section.add "X-Amz-SignedHeaders", valid_773272
  var valid_773273 = header.getOrDefault("X-Amz-Credential")
  valid_773273 = validateParameter(valid_773273, JString, required = false,
                                 default = nil)
  if valid_773273 != nil:
    section.add "X-Amz-Credential", valid_773273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773275: Call_CreateFieldLevelEncryptionConfig20190326_773264;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a new field-level encryption configuration.
  ## 
  let valid = call_773275.validator(path, query, header, formData, body)
  let scheme = call_773275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773275.url(scheme.get, call_773275.host, call_773275.base,
                         call_773275.route, valid.getOrDefault("path"))
  result = hook(call_773275, url, valid)

proc call*(call_773276: Call_CreateFieldLevelEncryptionConfig20190326_773264;
          body: JsonNode): Recallable =
  ## createFieldLevelEncryptionConfig20190326
  ## Create a new field-level encryption configuration.
  ##   body: JObject (required)
  var body_773277 = newJObject()
  if body != nil:
    body_773277 = body
  result = call_773276.call(nil, nil, nil, nil, body_773277)

var createFieldLevelEncryptionConfig20190326* = Call_CreateFieldLevelEncryptionConfig20190326_773264(
    name: "createFieldLevelEncryptionConfig20190326", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/field-level-encryption",
    validator: validate_CreateFieldLevelEncryptionConfig20190326_773265,
    base: "/", url: url_CreateFieldLevelEncryptionConfig20190326_773266,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFieldLevelEncryptionConfigs20190326_773249 = ref object of OpenApiRestCall_772597
proc url_ListFieldLevelEncryptionConfigs20190326_773251(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListFieldLevelEncryptionConfigs20190326_773250(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List all field-level encryption configurations that have been created in CloudFront for this account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this when paginating results to indicate where to begin in your list of configurations. The results include configurations in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last configuration on that page). 
  ##   MaxItems: JString
  ##           : The maximum number of field-level encryption configurations you want in the response body. 
  section = newJObject()
  var valid_773252 = query.getOrDefault("Marker")
  valid_773252 = validateParameter(valid_773252, JString, required = false,
                                 default = nil)
  if valid_773252 != nil:
    section.add "Marker", valid_773252
  var valid_773253 = query.getOrDefault("MaxItems")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "MaxItems", valid_773253
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
  var valid_773254 = header.getOrDefault("X-Amz-Date")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "X-Amz-Date", valid_773254
  var valid_773255 = header.getOrDefault("X-Amz-Security-Token")
  valid_773255 = validateParameter(valid_773255, JString, required = false,
                                 default = nil)
  if valid_773255 != nil:
    section.add "X-Amz-Security-Token", valid_773255
  var valid_773256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "X-Amz-Content-Sha256", valid_773256
  var valid_773257 = header.getOrDefault("X-Amz-Algorithm")
  valid_773257 = validateParameter(valid_773257, JString, required = false,
                                 default = nil)
  if valid_773257 != nil:
    section.add "X-Amz-Algorithm", valid_773257
  var valid_773258 = header.getOrDefault("X-Amz-Signature")
  valid_773258 = validateParameter(valid_773258, JString, required = false,
                                 default = nil)
  if valid_773258 != nil:
    section.add "X-Amz-Signature", valid_773258
  var valid_773259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773259 = validateParameter(valid_773259, JString, required = false,
                                 default = nil)
  if valid_773259 != nil:
    section.add "X-Amz-SignedHeaders", valid_773259
  var valid_773260 = header.getOrDefault("X-Amz-Credential")
  valid_773260 = validateParameter(valid_773260, JString, required = false,
                                 default = nil)
  if valid_773260 != nil:
    section.add "X-Amz-Credential", valid_773260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773261: Call_ListFieldLevelEncryptionConfigs20190326_773249;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## List all field-level encryption configurations that have been created in CloudFront for this account.
  ## 
  let valid = call_773261.validator(path, query, header, formData, body)
  let scheme = call_773261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773261.url(scheme.get, call_773261.host, call_773261.base,
                         call_773261.route, valid.getOrDefault("path"))
  result = hook(call_773261, url, valid)

proc call*(call_773262: Call_ListFieldLevelEncryptionConfigs20190326_773249;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listFieldLevelEncryptionConfigs20190326
  ## List all field-level encryption configurations that have been created in CloudFront for this account.
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of configurations. The results include configurations in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last configuration on that page). 
  ##   MaxItems: string
  ##           : The maximum number of field-level encryption configurations you want in the response body. 
  var query_773263 = newJObject()
  add(query_773263, "Marker", newJString(Marker))
  add(query_773263, "MaxItems", newJString(MaxItems))
  result = call_773262.call(nil, query_773263, nil, nil, nil)

var listFieldLevelEncryptionConfigs20190326* = Call_ListFieldLevelEncryptionConfigs20190326_773249(
    name: "listFieldLevelEncryptionConfigs20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/field-level-encryption",
    validator: validate_ListFieldLevelEncryptionConfigs20190326_773250, base: "/",
    url: url_ListFieldLevelEncryptionConfigs20190326_773251,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFieldLevelEncryptionProfile20190326_773293 = ref object of OpenApiRestCall_772597
proc url_CreateFieldLevelEncryptionProfile20190326_773295(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateFieldLevelEncryptionProfile20190326_773294(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a field-level encryption profile.
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
  var valid_773296 = header.getOrDefault("X-Amz-Date")
  valid_773296 = validateParameter(valid_773296, JString, required = false,
                                 default = nil)
  if valid_773296 != nil:
    section.add "X-Amz-Date", valid_773296
  var valid_773297 = header.getOrDefault("X-Amz-Security-Token")
  valid_773297 = validateParameter(valid_773297, JString, required = false,
                                 default = nil)
  if valid_773297 != nil:
    section.add "X-Amz-Security-Token", valid_773297
  var valid_773298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773298 = validateParameter(valid_773298, JString, required = false,
                                 default = nil)
  if valid_773298 != nil:
    section.add "X-Amz-Content-Sha256", valid_773298
  var valid_773299 = header.getOrDefault("X-Amz-Algorithm")
  valid_773299 = validateParameter(valid_773299, JString, required = false,
                                 default = nil)
  if valid_773299 != nil:
    section.add "X-Amz-Algorithm", valid_773299
  var valid_773300 = header.getOrDefault("X-Amz-Signature")
  valid_773300 = validateParameter(valid_773300, JString, required = false,
                                 default = nil)
  if valid_773300 != nil:
    section.add "X-Amz-Signature", valid_773300
  var valid_773301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773301 = validateParameter(valid_773301, JString, required = false,
                                 default = nil)
  if valid_773301 != nil:
    section.add "X-Amz-SignedHeaders", valid_773301
  var valid_773302 = header.getOrDefault("X-Amz-Credential")
  valid_773302 = validateParameter(valid_773302, JString, required = false,
                                 default = nil)
  if valid_773302 != nil:
    section.add "X-Amz-Credential", valid_773302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773304: Call_CreateFieldLevelEncryptionProfile20190326_773293;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a field-level encryption profile.
  ## 
  let valid = call_773304.validator(path, query, header, formData, body)
  let scheme = call_773304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773304.url(scheme.get, call_773304.host, call_773304.base,
                         call_773304.route, valid.getOrDefault("path"))
  result = hook(call_773304, url, valid)

proc call*(call_773305: Call_CreateFieldLevelEncryptionProfile20190326_773293;
          body: JsonNode): Recallable =
  ## createFieldLevelEncryptionProfile20190326
  ## Create a field-level encryption profile.
  ##   body: JObject (required)
  var body_773306 = newJObject()
  if body != nil:
    body_773306 = body
  result = call_773305.call(nil, nil, nil, nil, body_773306)

var createFieldLevelEncryptionProfile20190326* = Call_CreateFieldLevelEncryptionProfile20190326_773293(
    name: "createFieldLevelEncryptionProfile20190326", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/field-level-encryption-profile",
    validator: validate_CreateFieldLevelEncryptionProfile20190326_773294,
    base: "/", url: url_CreateFieldLevelEncryptionProfile20190326_773295,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFieldLevelEncryptionProfiles20190326_773278 = ref object of OpenApiRestCall_772597
proc url_ListFieldLevelEncryptionProfiles20190326_773280(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListFieldLevelEncryptionProfiles20190326_773279(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Request a list of field-level encryption profiles that have been created in CloudFront for this account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this when paginating results to indicate where to begin in your list of profiles. The results include profiles in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last profile on that page). 
  ##   MaxItems: JString
  ##           : The maximum number of field-level encryption profiles you want in the response body. 
  section = newJObject()
  var valid_773281 = query.getOrDefault("Marker")
  valid_773281 = validateParameter(valid_773281, JString, required = false,
                                 default = nil)
  if valid_773281 != nil:
    section.add "Marker", valid_773281
  var valid_773282 = query.getOrDefault("MaxItems")
  valid_773282 = validateParameter(valid_773282, JString, required = false,
                                 default = nil)
  if valid_773282 != nil:
    section.add "MaxItems", valid_773282
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
  var valid_773283 = header.getOrDefault("X-Amz-Date")
  valid_773283 = validateParameter(valid_773283, JString, required = false,
                                 default = nil)
  if valid_773283 != nil:
    section.add "X-Amz-Date", valid_773283
  var valid_773284 = header.getOrDefault("X-Amz-Security-Token")
  valid_773284 = validateParameter(valid_773284, JString, required = false,
                                 default = nil)
  if valid_773284 != nil:
    section.add "X-Amz-Security-Token", valid_773284
  var valid_773285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773285 = validateParameter(valid_773285, JString, required = false,
                                 default = nil)
  if valid_773285 != nil:
    section.add "X-Amz-Content-Sha256", valid_773285
  var valid_773286 = header.getOrDefault("X-Amz-Algorithm")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "X-Amz-Algorithm", valid_773286
  var valid_773287 = header.getOrDefault("X-Amz-Signature")
  valid_773287 = validateParameter(valid_773287, JString, required = false,
                                 default = nil)
  if valid_773287 != nil:
    section.add "X-Amz-Signature", valid_773287
  var valid_773288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773288 = validateParameter(valid_773288, JString, required = false,
                                 default = nil)
  if valid_773288 != nil:
    section.add "X-Amz-SignedHeaders", valid_773288
  var valid_773289 = header.getOrDefault("X-Amz-Credential")
  valid_773289 = validateParameter(valid_773289, JString, required = false,
                                 default = nil)
  if valid_773289 != nil:
    section.add "X-Amz-Credential", valid_773289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773290: Call_ListFieldLevelEncryptionProfiles20190326_773278;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Request a list of field-level encryption profiles that have been created in CloudFront for this account.
  ## 
  let valid = call_773290.validator(path, query, header, formData, body)
  let scheme = call_773290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773290.url(scheme.get, call_773290.host, call_773290.base,
                         call_773290.route, valid.getOrDefault("path"))
  result = hook(call_773290, url, valid)

proc call*(call_773291: Call_ListFieldLevelEncryptionProfiles20190326_773278;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listFieldLevelEncryptionProfiles20190326
  ## Request a list of field-level encryption profiles that have been created in CloudFront for this account.
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of profiles. The results include profiles in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last profile on that page). 
  ##   MaxItems: string
  ##           : The maximum number of field-level encryption profiles you want in the response body. 
  var query_773292 = newJObject()
  add(query_773292, "Marker", newJString(Marker))
  add(query_773292, "MaxItems", newJString(MaxItems))
  result = call_773291.call(nil, query_773292, nil, nil, nil)

var listFieldLevelEncryptionProfiles20190326* = Call_ListFieldLevelEncryptionProfiles20190326_773278(
    name: "listFieldLevelEncryptionProfiles20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/field-level-encryption-profile",
    validator: validate_ListFieldLevelEncryptionProfiles20190326_773279,
    base: "/", url: url_ListFieldLevelEncryptionProfiles20190326_773280,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInvalidation20190326_773338 = ref object of OpenApiRestCall_772597
proc url_CreateInvalidation20190326_773340(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path, "`DistributionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-03-26/distribution/"),
               (kind: VariableSegment, value: "DistributionId"),
               (kind: ConstantSegment, value: "/invalidation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_CreateInvalidation20190326_773339(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new invalidation. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DistributionId: JString (required)
  ##                 : The distribution's id.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DistributionId` field"
  var valid_773341 = path.getOrDefault("DistributionId")
  valid_773341 = validateParameter(valid_773341, JString, required = true,
                                 default = nil)
  if valid_773341 != nil:
    section.add "DistributionId", valid_773341
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
  var valid_773342 = header.getOrDefault("X-Amz-Date")
  valid_773342 = validateParameter(valid_773342, JString, required = false,
                                 default = nil)
  if valid_773342 != nil:
    section.add "X-Amz-Date", valid_773342
  var valid_773343 = header.getOrDefault("X-Amz-Security-Token")
  valid_773343 = validateParameter(valid_773343, JString, required = false,
                                 default = nil)
  if valid_773343 != nil:
    section.add "X-Amz-Security-Token", valid_773343
  var valid_773344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773344 = validateParameter(valid_773344, JString, required = false,
                                 default = nil)
  if valid_773344 != nil:
    section.add "X-Amz-Content-Sha256", valid_773344
  var valid_773345 = header.getOrDefault("X-Amz-Algorithm")
  valid_773345 = validateParameter(valid_773345, JString, required = false,
                                 default = nil)
  if valid_773345 != nil:
    section.add "X-Amz-Algorithm", valid_773345
  var valid_773346 = header.getOrDefault("X-Amz-Signature")
  valid_773346 = validateParameter(valid_773346, JString, required = false,
                                 default = nil)
  if valid_773346 != nil:
    section.add "X-Amz-Signature", valid_773346
  var valid_773347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773347 = validateParameter(valid_773347, JString, required = false,
                                 default = nil)
  if valid_773347 != nil:
    section.add "X-Amz-SignedHeaders", valid_773347
  var valid_773348 = header.getOrDefault("X-Amz-Credential")
  valid_773348 = validateParameter(valid_773348, JString, required = false,
                                 default = nil)
  if valid_773348 != nil:
    section.add "X-Amz-Credential", valid_773348
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773350: Call_CreateInvalidation20190326_773338; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new invalidation. 
  ## 
  let valid = call_773350.validator(path, query, header, formData, body)
  let scheme = call_773350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773350.url(scheme.get, call_773350.host, call_773350.base,
                         call_773350.route, valid.getOrDefault("path"))
  result = hook(call_773350, url, valid)

proc call*(call_773351: Call_CreateInvalidation20190326_773338; body: JsonNode;
          DistributionId: string): Recallable =
  ## createInvalidation20190326
  ## Create a new invalidation. 
  ##   body: JObject (required)
  ##   DistributionId: string (required)
  ##                 : The distribution's id.
  var path_773352 = newJObject()
  var body_773353 = newJObject()
  if body != nil:
    body_773353 = body
  add(path_773352, "DistributionId", newJString(DistributionId))
  result = call_773351.call(path_773352, nil, nil, nil, body_773353)

var createInvalidation20190326* = Call_CreateInvalidation20190326_773338(
    name: "createInvalidation20190326", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/distribution/{DistributionId}/invalidation",
    validator: validate_CreateInvalidation20190326_773339, base: "/",
    url: url_CreateInvalidation20190326_773340,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvalidations20190326_773307 = ref object of OpenApiRestCall_772597
proc url_ListInvalidations20190326_773309(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path, "`DistributionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-03-26/distribution/"),
               (kind: VariableSegment, value: "DistributionId"),
               (kind: ConstantSegment, value: "/invalidation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListInvalidations20190326_773308(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists invalidation batches. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DistributionId: JString (required)
  ##                 : The distribution's ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DistributionId` field"
  var valid_773324 = path.getOrDefault("DistributionId")
  valid_773324 = validateParameter(valid_773324, JString, required = true,
                                 default = nil)
  if valid_773324 != nil:
    section.add "DistributionId", valid_773324
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this parameter when paginating results to indicate where to begin in your list of invalidation batches. Because the results are returned in decreasing order from most recent to oldest, the most recent results are on the first page, the second page will contain earlier results, and so on. To get the next page of results, set <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response. This value is the same as the ID of the last invalidation batch on that page. 
  ##   MaxItems: JString
  ##           : The maximum number of invalidation batches that you want in the response body.
  section = newJObject()
  var valid_773325 = query.getOrDefault("Marker")
  valid_773325 = validateParameter(valid_773325, JString, required = false,
                                 default = nil)
  if valid_773325 != nil:
    section.add "Marker", valid_773325
  var valid_773326 = query.getOrDefault("MaxItems")
  valid_773326 = validateParameter(valid_773326, JString, required = false,
                                 default = nil)
  if valid_773326 != nil:
    section.add "MaxItems", valid_773326
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
  var valid_773327 = header.getOrDefault("X-Amz-Date")
  valid_773327 = validateParameter(valid_773327, JString, required = false,
                                 default = nil)
  if valid_773327 != nil:
    section.add "X-Amz-Date", valid_773327
  var valid_773328 = header.getOrDefault("X-Amz-Security-Token")
  valid_773328 = validateParameter(valid_773328, JString, required = false,
                                 default = nil)
  if valid_773328 != nil:
    section.add "X-Amz-Security-Token", valid_773328
  var valid_773329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773329 = validateParameter(valid_773329, JString, required = false,
                                 default = nil)
  if valid_773329 != nil:
    section.add "X-Amz-Content-Sha256", valid_773329
  var valid_773330 = header.getOrDefault("X-Amz-Algorithm")
  valid_773330 = validateParameter(valid_773330, JString, required = false,
                                 default = nil)
  if valid_773330 != nil:
    section.add "X-Amz-Algorithm", valid_773330
  var valid_773331 = header.getOrDefault("X-Amz-Signature")
  valid_773331 = validateParameter(valid_773331, JString, required = false,
                                 default = nil)
  if valid_773331 != nil:
    section.add "X-Amz-Signature", valid_773331
  var valid_773332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773332 = validateParameter(valid_773332, JString, required = false,
                                 default = nil)
  if valid_773332 != nil:
    section.add "X-Amz-SignedHeaders", valid_773332
  var valid_773333 = header.getOrDefault("X-Amz-Credential")
  valid_773333 = validateParameter(valid_773333, JString, required = false,
                                 default = nil)
  if valid_773333 != nil:
    section.add "X-Amz-Credential", valid_773333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773334: Call_ListInvalidations20190326_773307; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists invalidation batches. 
  ## 
  let valid = call_773334.validator(path, query, header, formData, body)
  let scheme = call_773334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773334.url(scheme.get, call_773334.host, call_773334.base,
                         call_773334.route, valid.getOrDefault("path"))
  result = hook(call_773334, url, valid)

proc call*(call_773335: Call_ListInvalidations20190326_773307;
          DistributionId: string; Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listInvalidations20190326
  ## Lists invalidation batches. 
  ##   Marker: string
  ##         : Use this parameter when paginating results to indicate where to begin in your list of invalidation batches. Because the results are returned in decreasing order from most recent to oldest, the most recent results are on the first page, the second page will contain earlier results, and so on. To get the next page of results, set <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response. This value is the same as the ID of the last invalidation batch on that page. 
  ##   MaxItems: string
  ##           : The maximum number of invalidation batches that you want in the response body.
  ##   DistributionId: string (required)
  ##                 : The distribution's ID.
  var path_773336 = newJObject()
  var query_773337 = newJObject()
  add(query_773337, "Marker", newJString(Marker))
  add(query_773337, "MaxItems", newJString(MaxItems))
  add(path_773336, "DistributionId", newJString(DistributionId))
  result = call_773335.call(path_773336, query_773337, nil, nil, nil)

var listInvalidations20190326* = Call_ListInvalidations20190326_773307(
    name: "listInvalidations20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/distribution/{DistributionId}/invalidation",
    validator: validate_ListInvalidations20190326_773308, base: "/",
    url: url_ListInvalidations20190326_773309,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePublicKey20190326_773369 = ref object of OpenApiRestCall_772597
proc url_CreatePublicKey20190326_773371(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreatePublicKey20190326_773370(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Add a new public key to CloudFront to use, for example, for field-level encryption. You can add a maximum of 10 public keys with one AWS account.
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
  var valid_773372 = header.getOrDefault("X-Amz-Date")
  valid_773372 = validateParameter(valid_773372, JString, required = false,
                                 default = nil)
  if valid_773372 != nil:
    section.add "X-Amz-Date", valid_773372
  var valid_773373 = header.getOrDefault("X-Amz-Security-Token")
  valid_773373 = validateParameter(valid_773373, JString, required = false,
                                 default = nil)
  if valid_773373 != nil:
    section.add "X-Amz-Security-Token", valid_773373
  var valid_773374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "X-Amz-Content-Sha256", valid_773374
  var valid_773375 = header.getOrDefault("X-Amz-Algorithm")
  valid_773375 = validateParameter(valid_773375, JString, required = false,
                                 default = nil)
  if valid_773375 != nil:
    section.add "X-Amz-Algorithm", valid_773375
  var valid_773376 = header.getOrDefault("X-Amz-Signature")
  valid_773376 = validateParameter(valid_773376, JString, required = false,
                                 default = nil)
  if valid_773376 != nil:
    section.add "X-Amz-Signature", valid_773376
  var valid_773377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773377 = validateParameter(valid_773377, JString, required = false,
                                 default = nil)
  if valid_773377 != nil:
    section.add "X-Amz-SignedHeaders", valid_773377
  var valid_773378 = header.getOrDefault("X-Amz-Credential")
  valid_773378 = validateParameter(valid_773378, JString, required = false,
                                 default = nil)
  if valid_773378 != nil:
    section.add "X-Amz-Credential", valid_773378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773380: Call_CreatePublicKey20190326_773369; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add a new public key to CloudFront to use, for example, for field-level encryption. You can add a maximum of 10 public keys with one AWS account.
  ## 
  let valid = call_773380.validator(path, query, header, formData, body)
  let scheme = call_773380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773380.url(scheme.get, call_773380.host, call_773380.base,
                         call_773380.route, valid.getOrDefault("path"))
  result = hook(call_773380, url, valid)

proc call*(call_773381: Call_CreatePublicKey20190326_773369; body: JsonNode): Recallable =
  ## createPublicKey20190326
  ## Add a new public key to CloudFront to use, for example, for field-level encryption. You can add a maximum of 10 public keys with one AWS account.
  ##   body: JObject (required)
  var body_773382 = newJObject()
  if body != nil:
    body_773382 = body
  result = call_773381.call(nil, nil, nil, nil, body_773382)

var createPublicKey20190326* = Call_CreatePublicKey20190326_773369(
    name: "createPublicKey20190326", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/public-key",
    validator: validate_CreatePublicKey20190326_773370, base: "/",
    url: url_CreatePublicKey20190326_773371, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPublicKeys20190326_773354 = ref object of OpenApiRestCall_772597
proc url_ListPublicKeys20190326_773356(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListPublicKeys20190326_773355(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List all public keys that have been added to CloudFront for this account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this when paginating results to indicate where to begin in your list of public keys. The results include public keys in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last public key on that page). 
  ##   MaxItems: JString
  ##           : The maximum number of public keys you want in the response body. 
  section = newJObject()
  var valid_773357 = query.getOrDefault("Marker")
  valid_773357 = validateParameter(valid_773357, JString, required = false,
                                 default = nil)
  if valid_773357 != nil:
    section.add "Marker", valid_773357
  var valid_773358 = query.getOrDefault("MaxItems")
  valid_773358 = validateParameter(valid_773358, JString, required = false,
                                 default = nil)
  if valid_773358 != nil:
    section.add "MaxItems", valid_773358
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
  var valid_773359 = header.getOrDefault("X-Amz-Date")
  valid_773359 = validateParameter(valid_773359, JString, required = false,
                                 default = nil)
  if valid_773359 != nil:
    section.add "X-Amz-Date", valid_773359
  var valid_773360 = header.getOrDefault("X-Amz-Security-Token")
  valid_773360 = validateParameter(valid_773360, JString, required = false,
                                 default = nil)
  if valid_773360 != nil:
    section.add "X-Amz-Security-Token", valid_773360
  var valid_773361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773361 = validateParameter(valid_773361, JString, required = false,
                                 default = nil)
  if valid_773361 != nil:
    section.add "X-Amz-Content-Sha256", valid_773361
  var valid_773362 = header.getOrDefault("X-Amz-Algorithm")
  valid_773362 = validateParameter(valid_773362, JString, required = false,
                                 default = nil)
  if valid_773362 != nil:
    section.add "X-Amz-Algorithm", valid_773362
  var valid_773363 = header.getOrDefault("X-Amz-Signature")
  valid_773363 = validateParameter(valid_773363, JString, required = false,
                                 default = nil)
  if valid_773363 != nil:
    section.add "X-Amz-Signature", valid_773363
  var valid_773364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773364 = validateParameter(valid_773364, JString, required = false,
                                 default = nil)
  if valid_773364 != nil:
    section.add "X-Amz-SignedHeaders", valid_773364
  var valid_773365 = header.getOrDefault("X-Amz-Credential")
  valid_773365 = validateParameter(valid_773365, JString, required = false,
                                 default = nil)
  if valid_773365 != nil:
    section.add "X-Amz-Credential", valid_773365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773366: Call_ListPublicKeys20190326_773354; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all public keys that have been added to CloudFront for this account.
  ## 
  let valid = call_773366.validator(path, query, header, formData, body)
  let scheme = call_773366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773366.url(scheme.get, call_773366.host, call_773366.base,
                         call_773366.route, valid.getOrDefault("path"))
  result = hook(call_773366, url, valid)

proc call*(call_773367: Call_ListPublicKeys20190326_773354; Marker: string = "";
          MaxItems: string = ""): Recallable =
  ## listPublicKeys20190326
  ## List all public keys that have been added to CloudFront for this account.
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of public keys. The results include public keys in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last public key on that page). 
  ##   MaxItems: string
  ##           : The maximum number of public keys you want in the response body. 
  var query_773368 = newJObject()
  add(query_773368, "Marker", newJString(Marker))
  add(query_773368, "MaxItems", newJString(MaxItems))
  result = call_773367.call(nil, query_773368, nil, nil, nil)

var listPublicKeys20190326* = Call_ListPublicKeys20190326_773354(
    name: "listPublicKeys20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/public-key",
    validator: validate_ListPublicKeys20190326_773355, base: "/",
    url: url_ListPublicKeys20190326_773356, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamingDistribution20190326_773398 = ref object of OpenApiRestCall_772597
proc url_CreateStreamingDistribution20190326_773400(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateStreamingDistribution20190326_773399(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new RTMP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
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
  var valid_773401 = header.getOrDefault("X-Amz-Date")
  valid_773401 = validateParameter(valid_773401, JString, required = false,
                                 default = nil)
  if valid_773401 != nil:
    section.add "X-Amz-Date", valid_773401
  var valid_773402 = header.getOrDefault("X-Amz-Security-Token")
  valid_773402 = validateParameter(valid_773402, JString, required = false,
                                 default = nil)
  if valid_773402 != nil:
    section.add "X-Amz-Security-Token", valid_773402
  var valid_773403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773403 = validateParameter(valid_773403, JString, required = false,
                                 default = nil)
  if valid_773403 != nil:
    section.add "X-Amz-Content-Sha256", valid_773403
  var valid_773404 = header.getOrDefault("X-Amz-Algorithm")
  valid_773404 = validateParameter(valid_773404, JString, required = false,
                                 default = nil)
  if valid_773404 != nil:
    section.add "X-Amz-Algorithm", valid_773404
  var valid_773405 = header.getOrDefault("X-Amz-Signature")
  valid_773405 = validateParameter(valid_773405, JString, required = false,
                                 default = nil)
  if valid_773405 != nil:
    section.add "X-Amz-Signature", valid_773405
  var valid_773406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773406 = validateParameter(valid_773406, JString, required = false,
                                 default = nil)
  if valid_773406 != nil:
    section.add "X-Amz-SignedHeaders", valid_773406
  var valid_773407 = header.getOrDefault("X-Amz-Credential")
  valid_773407 = validateParameter(valid_773407, JString, required = false,
                                 default = nil)
  if valid_773407 != nil:
    section.add "X-Amz-Credential", valid_773407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773409: Call_CreateStreamingDistribution20190326_773398;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new RTMP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
  ## 
  let valid = call_773409.validator(path, query, header, formData, body)
  let scheme = call_773409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773409.url(scheme.get, call_773409.host, call_773409.base,
                         call_773409.route, valid.getOrDefault("path"))
  result = hook(call_773409, url, valid)

proc call*(call_773410: Call_CreateStreamingDistribution20190326_773398;
          body: JsonNode): Recallable =
  ## createStreamingDistribution20190326
  ## <p>Creates a new RTMP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
  ##   body: JObject (required)
  var body_773411 = newJObject()
  if body != nil:
    body_773411 = body
  result = call_773410.call(nil, nil, nil, nil, body_773411)

var createStreamingDistribution20190326* = Call_CreateStreamingDistribution20190326_773398(
    name: "createStreamingDistribution20190326", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/streaming-distribution",
    validator: validate_CreateStreamingDistribution20190326_773399, base: "/",
    url: url_CreateStreamingDistribution20190326_773400,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListStreamingDistributions20190326_773383 = ref object of OpenApiRestCall_772597
proc url_ListStreamingDistributions20190326_773385(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListStreamingDistributions20190326_773384(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List streaming distributions. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : The value that you provided for the <code>Marker</code> request parameter.
  ##   MaxItems: JString
  ##           : The value that you provided for the <code>MaxItems</code> request parameter.
  section = newJObject()
  var valid_773386 = query.getOrDefault("Marker")
  valid_773386 = validateParameter(valid_773386, JString, required = false,
                                 default = nil)
  if valid_773386 != nil:
    section.add "Marker", valid_773386
  var valid_773387 = query.getOrDefault("MaxItems")
  valid_773387 = validateParameter(valid_773387, JString, required = false,
                                 default = nil)
  if valid_773387 != nil:
    section.add "MaxItems", valid_773387
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
  var valid_773388 = header.getOrDefault("X-Amz-Date")
  valid_773388 = validateParameter(valid_773388, JString, required = false,
                                 default = nil)
  if valid_773388 != nil:
    section.add "X-Amz-Date", valid_773388
  var valid_773389 = header.getOrDefault("X-Amz-Security-Token")
  valid_773389 = validateParameter(valid_773389, JString, required = false,
                                 default = nil)
  if valid_773389 != nil:
    section.add "X-Amz-Security-Token", valid_773389
  var valid_773390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773390 = validateParameter(valid_773390, JString, required = false,
                                 default = nil)
  if valid_773390 != nil:
    section.add "X-Amz-Content-Sha256", valid_773390
  var valid_773391 = header.getOrDefault("X-Amz-Algorithm")
  valid_773391 = validateParameter(valid_773391, JString, required = false,
                                 default = nil)
  if valid_773391 != nil:
    section.add "X-Amz-Algorithm", valid_773391
  var valid_773392 = header.getOrDefault("X-Amz-Signature")
  valid_773392 = validateParameter(valid_773392, JString, required = false,
                                 default = nil)
  if valid_773392 != nil:
    section.add "X-Amz-Signature", valid_773392
  var valid_773393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773393 = validateParameter(valid_773393, JString, required = false,
                                 default = nil)
  if valid_773393 != nil:
    section.add "X-Amz-SignedHeaders", valid_773393
  var valid_773394 = header.getOrDefault("X-Amz-Credential")
  valid_773394 = validateParameter(valid_773394, JString, required = false,
                                 default = nil)
  if valid_773394 != nil:
    section.add "X-Amz-Credential", valid_773394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773395: Call_ListStreamingDistributions20190326_773383;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## List streaming distributions. 
  ## 
  let valid = call_773395.validator(path, query, header, formData, body)
  let scheme = call_773395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773395.url(scheme.get, call_773395.host, call_773395.base,
                         call_773395.route, valid.getOrDefault("path"))
  result = hook(call_773395, url, valid)

proc call*(call_773396: Call_ListStreamingDistributions20190326_773383;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listStreamingDistributions20190326
  ## List streaming distributions. 
  ##   Marker: string
  ##         : The value that you provided for the <code>Marker</code> request parameter.
  ##   MaxItems: string
  ##           : The value that you provided for the <code>MaxItems</code> request parameter.
  var query_773397 = newJObject()
  add(query_773397, "Marker", newJString(Marker))
  add(query_773397, "MaxItems", newJString(MaxItems))
  result = call_773396.call(nil, query_773397, nil, nil, nil)

var listStreamingDistributions20190326* = Call_ListStreamingDistributions20190326_773383(
    name: "listStreamingDistributions20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/streaming-distribution",
    validator: validate_ListStreamingDistributions20190326_773384, base: "/",
    url: url_ListStreamingDistributions20190326_773385,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamingDistributionWithTags20190326_773412 = ref object of OpenApiRestCall_772597
proc url_CreateStreamingDistributionWithTags20190326_773414(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateStreamingDistributionWithTags20190326_773413(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new streaming distribution with tags.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   WithTags: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `WithTags` field"
  var valid_773415 = query.getOrDefault("WithTags")
  valid_773415 = validateParameter(valid_773415, JBool, required = true, default = nil)
  if valid_773415 != nil:
    section.add "WithTags", valid_773415
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
  var valid_773416 = header.getOrDefault("X-Amz-Date")
  valid_773416 = validateParameter(valid_773416, JString, required = false,
                                 default = nil)
  if valid_773416 != nil:
    section.add "X-Amz-Date", valid_773416
  var valid_773417 = header.getOrDefault("X-Amz-Security-Token")
  valid_773417 = validateParameter(valid_773417, JString, required = false,
                                 default = nil)
  if valid_773417 != nil:
    section.add "X-Amz-Security-Token", valid_773417
  var valid_773418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773418 = validateParameter(valid_773418, JString, required = false,
                                 default = nil)
  if valid_773418 != nil:
    section.add "X-Amz-Content-Sha256", valid_773418
  var valid_773419 = header.getOrDefault("X-Amz-Algorithm")
  valid_773419 = validateParameter(valid_773419, JString, required = false,
                                 default = nil)
  if valid_773419 != nil:
    section.add "X-Amz-Algorithm", valid_773419
  var valid_773420 = header.getOrDefault("X-Amz-Signature")
  valid_773420 = validateParameter(valid_773420, JString, required = false,
                                 default = nil)
  if valid_773420 != nil:
    section.add "X-Amz-Signature", valid_773420
  var valid_773421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773421 = validateParameter(valid_773421, JString, required = false,
                                 default = nil)
  if valid_773421 != nil:
    section.add "X-Amz-SignedHeaders", valid_773421
  var valid_773422 = header.getOrDefault("X-Amz-Credential")
  valid_773422 = validateParameter(valid_773422, JString, required = false,
                                 default = nil)
  if valid_773422 != nil:
    section.add "X-Amz-Credential", valid_773422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773424: Call_CreateStreamingDistributionWithTags20190326_773412;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a new streaming distribution with tags.
  ## 
  let valid = call_773424.validator(path, query, header, formData, body)
  let scheme = call_773424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773424.url(scheme.get, call_773424.host, call_773424.base,
                         call_773424.route, valid.getOrDefault("path"))
  result = hook(call_773424, url, valid)

proc call*(call_773425: Call_CreateStreamingDistributionWithTags20190326_773412;
          WithTags: bool; body: JsonNode): Recallable =
  ## createStreamingDistributionWithTags20190326
  ## Create a new streaming distribution with tags.
  ##   WithTags: bool (required)
  ##   body: JObject (required)
  var query_773426 = newJObject()
  var body_773427 = newJObject()
  add(query_773426, "WithTags", newJBool(WithTags))
  if body != nil:
    body_773427 = body
  result = call_773425.call(nil, query_773426, nil, nil, body_773427)

var createStreamingDistributionWithTags20190326* = Call_CreateStreamingDistributionWithTags20190326_773412(
    name: "createStreamingDistributionWithTags20190326",
    meth: HttpMethod.HttpPost, host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/streaming-distribution#WithTags",
    validator: validate_CreateStreamingDistributionWithTags20190326_773413,
    base: "/", url: url_CreateStreamingDistributionWithTags20190326_773414,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFrontOriginAccessIdentity20190326_773428 = ref object of OpenApiRestCall_772597
proc url_GetCloudFrontOriginAccessIdentity20190326_773430(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetCloudFrontOriginAccessIdentity20190326_773429(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the information about an origin access identity. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identity's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_773431 = path.getOrDefault("Id")
  valid_773431 = validateParameter(valid_773431, JString, required = true,
                                 default = nil)
  if valid_773431 != nil:
    section.add "Id", valid_773431
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
  var valid_773432 = header.getOrDefault("X-Amz-Date")
  valid_773432 = validateParameter(valid_773432, JString, required = false,
                                 default = nil)
  if valid_773432 != nil:
    section.add "X-Amz-Date", valid_773432
  var valid_773433 = header.getOrDefault("X-Amz-Security-Token")
  valid_773433 = validateParameter(valid_773433, JString, required = false,
                                 default = nil)
  if valid_773433 != nil:
    section.add "X-Amz-Security-Token", valid_773433
  var valid_773434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773434 = validateParameter(valid_773434, JString, required = false,
                                 default = nil)
  if valid_773434 != nil:
    section.add "X-Amz-Content-Sha256", valid_773434
  var valid_773435 = header.getOrDefault("X-Amz-Algorithm")
  valid_773435 = validateParameter(valid_773435, JString, required = false,
                                 default = nil)
  if valid_773435 != nil:
    section.add "X-Amz-Algorithm", valid_773435
  var valid_773436 = header.getOrDefault("X-Amz-Signature")
  valid_773436 = validateParameter(valid_773436, JString, required = false,
                                 default = nil)
  if valid_773436 != nil:
    section.add "X-Amz-Signature", valid_773436
  var valid_773437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773437 = validateParameter(valid_773437, JString, required = false,
                                 default = nil)
  if valid_773437 != nil:
    section.add "X-Amz-SignedHeaders", valid_773437
  var valid_773438 = header.getOrDefault("X-Amz-Credential")
  valid_773438 = validateParameter(valid_773438, JString, required = false,
                                 default = nil)
  if valid_773438 != nil:
    section.add "X-Amz-Credential", valid_773438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773439: Call_GetCloudFrontOriginAccessIdentity20190326_773428;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the information about an origin access identity. 
  ## 
  let valid = call_773439.validator(path, query, header, formData, body)
  let scheme = call_773439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773439.url(scheme.get, call_773439.host, call_773439.base,
                         call_773439.route, valid.getOrDefault("path"))
  result = hook(call_773439, url, valid)

proc call*(call_773440: Call_GetCloudFrontOriginAccessIdentity20190326_773428;
          Id: string): Recallable =
  ## getCloudFrontOriginAccessIdentity20190326
  ## Get the information about an origin access identity. 
  ##   Id: string (required)
  ##     : The identity's ID.
  var path_773441 = newJObject()
  add(path_773441, "Id", newJString(Id))
  result = call_773440.call(path_773441, nil, nil, nil, nil)

var getCloudFrontOriginAccessIdentity20190326* = Call_GetCloudFrontOriginAccessIdentity20190326_773428(
    name: "getCloudFrontOriginAccessIdentity20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/origin-access-identity/cloudfront/{Id}",
    validator: validate_GetCloudFrontOriginAccessIdentity20190326_773429,
    base: "/", url: url_GetCloudFrontOriginAccessIdentity20190326_773430,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCloudFrontOriginAccessIdentity20190326_773442 = ref object of OpenApiRestCall_772597
proc url_DeleteCloudFrontOriginAccessIdentity20190326_773444(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteCloudFrontOriginAccessIdentity20190326_773443(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Delete an origin access identity. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The origin access identity's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_773445 = path.getOrDefault("Id")
  valid_773445 = validateParameter(valid_773445, JString, required = true,
                                 default = nil)
  if valid_773445 != nil:
    section.add "Id", valid_773445
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header you received from a previous <code>GET</code> or <code>PUT</code> request. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773446 = header.getOrDefault("X-Amz-Date")
  valid_773446 = validateParameter(valid_773446, JString, required = false,
                                 default = nil)
  if valid_773446 != nil:
    section.add "X-Amz-Date", valid_773446
  var valid_773447 = header.getOrDefault("X-Amz-Security-Token")
  valid_773447 = validateParameter(valid_773447, JString, required = false,
                                 default = nil)
  if valid_773447 != nil:
    section.add "X-Amz-Security-Token", valid_773447
  var valid_773448 = header.getOrDefault("If-Match")
  valid_773448 = validateParameter(valid_773448, JString, required = false,
                                 default = nil)
  if valid_773448 != nil:
    section.add "If-Match", valid_773448
  var valid_773449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773449 = validateParameter(valid_773449, JString, required = false,
                                 default = nil)
  if valid_773449 != nil:
    section.add "X-Amz-Content-Sha256", valid_773449
  var valid_773450 = header.getOrDefault("X-Amz-Algorithm")
  valid_773450 = validateParameter(valid_773450, JString, required = false,
                                 default = nil)
  if valid_773450 != nil:
    section.add "X-Amz-Algorithm", valid_773450
  var valid_773451 = header.getOrDefault("X-Amz-Signature")
  valid_773451 = validateParameter(valid_773451, JString, required = false,
                                 default = nil)
  if valid_773451 != nil:
    section.add "X-Amz-Signature", valid_773451
  var valid_773452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773452 = validateParameter(valid_773452, JString, required = false,
                                 default = nil)
  if valid_773452 != nil:
    section.add "X-Amz-SignedHeaders", valid_773452
  var valid_773453 = header.getOrDefault("X-Amz-Credential")
  valid_773453 = validateParameter(valid_773453, JString, required = false,
                                 default = nil)
  if valid_773453 != nil:
    section.add "X-Amz-Credential", valid_773453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773454: Call_DeleteCloudFrontOriginAccessIdentity20190326_773442;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Delete an origin access identity. 
  ## 
  let valid = call_773454.validator(path, query, header, formData, body)
  let scheme = call_773454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773454.url(scheme.get, call_773454.host, call_773454.base,
                         call_773454.route, valid.getOrDefault("path"))
  result = hook(call_773454, url, valid)

proc call*(call_773455: Call_DeleteCloudFrontOriginAccessIdentity20190326_773442;
          Id: string): Recallable =
  ## deleteCloudFrontOriginAccessIdentity20190326
  ## Delete an origin access identity. 
  ##   Id: string (required)
  ##     : The origin access identity's ID.
  var path_773456 = newJObject()
  add(path_773456, "Id", newJString(Id))
  result = call_773455.call(path_773456, nil, nil, nil, nil)

var deleteCloudFrontOriginAccessIdentity20190326* = Call_DeleteCloudFrontOriginAccessIdentity20190326_773442(
    name: "deleteCloudFrontOriginAccessIdentity20190326",
    meth: HttpMethod.HttpDelete, host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/origin-access-identity/cloudfront/{Id}",
    validator: validate_DeleteCloudFrontOriginAccessIdentity20190326_773443,
    base: "/", url: url_DeleteCloudFrontOriginAccessIdentity20190326_773444,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDistribution20190326_773457 = ref object of OpenApiRestCall_772597
proc url_GetDistribution20190326_773459(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-03-26/distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetDistribution20190326_773458(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the information about a distribution.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution's ID. If the ID is empty, an empty distribution configuration is returned.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_773460 = path.getOrDefault("Id")
  valid_773460 = validateParameter(valid_773460, JString, required = true,
                                 default = nil)
  if valid_773460 != nil:
    section.add "Id", valid_773460
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
  var valid_773461 = header.getOrDefault("X-Amz-Date")
  valid_773461 = validateParameter(valid_773461, JString, required = false,
                                 default = nil)
  if valid_773461 != nil:
    section.add "X-Amz-Date", valid_773461
  var valid_773462 = header.getOrDefault("X-Amz-Security-Token")
  valid_773462 = validateParameter(valid_773462, JString, required = false,
                                 default = nil)
  if valid_773462 != nil:
    section.add "X-Amz-Security-Token", valid_773462
  var valid_773463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773463 = validateParameter(valid_773463, JString, required = false,
                                 default = nil)
  if valid_773463 != nil:
    section.add "X-Amz-Content-Sha256", valid_773463
  var valid_773464 = header.getOrDefault("X-Amz-Algorithm")
  valid_773464 = validateParameter(valid_773464, JString, required = false,
                                 default = nil)
  if valid_773464 != nil:
    section.add "X-Amz-Algorithm", valid_773464
  var valid_773465 = header.getOrDefault("X-Amz-Signature")
  valid_773465 = validateParameter(valid_773465, JString, required = false,
                                 default = nil)
  if valid_773465 != nil:
    section.add "X-Amz-Signature", valid_773465
  var valid_773466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773466 = validateParameter(valid_773466, JString, required = false,
                                 default = nil)
  if valid_773466 != nil:
    section.add "X-Amz-SignedHeaders", valid_773466
  var valid_773467 = header.getOrDefault("X-Amz-Credential")
  valid_773467 = validateParameter(valid_773467, JString, required = false,
                                 default = nil)
  if valid_773467 != nil:
    section.add "X-Amz-Credential", valid_773467
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773468: Call_GetDistribution20190326_773457; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the information about a distribution.
  ## 
  let valid = call_773468.validator(path, query, header, formData, body)
  let scheme = call_773468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773468.url(scheme.get, call_773468.host, call_773468.base,
                         call_773468.route, valid.getOrDefault("path"))
  result = hook(call_773468, url, valid)

proc call*(call_773469: Call_GetDistribution20190326_773457; Id: string): Recallable =
  ## getDistribution20190326
  ## Get the information about a distribution.
  ##   Id: string (required)
  ##     : The distribution's ID. If the ID is empty, an empty distribution configuration is returned.
  var path_773470 = newJObject()
  add(path_773470, "Id", newJString(Id))
  result = call_773469.call(path_773470, nil, nil, nil, nil)

var getDistribution20190326* = Call_GetDistribution20190326_773457(
    name: "getDistribution20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/distribution/{Id}",
    validator: validate_GetDistribution20190326_773458, base: "/",
    url: url_GetDistribution20190326_773459, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDistribution20190326_773471 = ref object of OpenApiRestCall_772597
proc url_DeleteDistribution20190326_773473(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-03-26/distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteDistribution20190326_773472(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Delete a distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_773474 = path.getOrDefault("Id")
  valid_773474 = validateParameter(valid_773474, JString, required = true,
                                 default = nil)
  if valid_773474 != nil:
    section.add "Id", valid_773474
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when you disabled the distribution. For example: <code>E2QWRUHAPOMQZL</code>. 
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773475 = header.getOrDefault("X-Amz-Date")
  valid_773475 = validateParameter(valid_773475, JString, required = false,
                                 default = nil)
  if valid_773475 != nil:
    section.add "X-Amz-Date", valid_773475
  var valid_773476 = header.getOrDefault("X-Amz-Security-Token")
  valid_773476 = validateParameter(valid_773476, JString, required = false,
                                 default = nil)
  if valid_773476 != nil:
    section.add "X-Amz-Security-Token", valid_773476
  var valid_773477 = header.getOrDefault("If-Match")
  valid_773477 = validateParameter(valid_773477, JString, required = false,
                                 default = nil)
  if valid_773477 != nil:
    section.add "If-Match", valid_773477
  var valid_773478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773478 = validateParameter(valid_773478, JString, required = false,
                                 default = nil)
  if valid_773478 != nil:
    section.add "X-Amz-Content-Sha256", valid_773478
  var valid_773479 = header.getOrDefault("X-Amz-Algorithm")
  valid_773479 = validateParameter(valid_773479, JString, required = false,
                                 default = nil)
  if valid_773479 != nil:
    section.add "X-Amz-Algorithm", valid_773479
  var valid_773480 = header.getOrDefault("X-Amz-Signature")
  valid_773480 = validateParameter(valid_773480, JString, required = false,
                                 default = nil)
  if valid_773480 != nil:
    section.add "X-Amz-Signature", valid_773480
  var valid_773481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773481 = validateParameter(valid_773481, JString, required = false,
                                 default = nil)
  if valid_773481 != nil:
    section.add "X-Amz-SignedHeaders", valid_773481
  var valid_773482 = header.getOrDefault("X-Amz-Credential")
  valid_773482 = validateParameter(valid_773482, JString, required = false,
                                 default = nil)
  if valid_773482 != nil:
    section.add "X-Amz-Credential", valid_773482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773483: Call_DeleteDistribution20190326_773471; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a distribution. 
  ## 
  let valid = call_773483.validator(path, query, header, formData, body)
  let scheme = call_773483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773483.url(scheme.get, call_773483.host, call_773483.base,
                         call_773483.route, valid.getOrDefault("path"))
  result = hook(call_773483, url, valid)

proc call*(call_773484: Call_DeleteDistribution20190326_773471; Id: string): Recallable =
  ## deleteDistribution20190326
  ## Delete a distribution. 
  ##   Id: string (required)
  ##     : The distribution ID. 
  var path_773485 = newJObject()
  add(path_773485, "Id", newJString(Id))
  result = call_773484.call(path_773485, nil, nil, nil, nil)

var deleteDistribution20190326* = Call_DeleteDistribution20190326_773471(
    name: "deleteDistribution20190326", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/distribution/{Id}",
    validator: validate_DeleteDistribution20190326_773472, base: "/",
    url: url_DeleteDistribution20190326_773473,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFieldLevelEncryption20190326_773486 = ref object of OpenApiRestCall_772597
proc url_GetFieldLevelEncryption20190326_773488(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/field-level-encryption/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetFieldLevelEncryption20190326_773487(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the field-level encryption configuration information.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Request the ID for the field-level encryption configuration information.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_773489 = path.getOrDefault("Id")
  valid_773489 = validateParameter(valid_773489, JString, required = true,
                                 default = nil)
  if valid_773489 != nil:
    section.add "Id", valid_773489
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
  var valid_773490 = header.getOrDefault("X-Amz-Date")
  valid_773490 = validateParameter(valid_773490, JString, required = false,
                                 default = nil)
  if valid_773490 != nil:
    section.add "X-Amz-Date", valid_773490
  var valid_773491 = header.getOrDefault("X-Amz-Security-Token")
  valid_773491 = validateParameter(valid_773491, JString, required = false,
                                 default = nil)
  if valid_773491 != nil:
    section.add "X-Amz-Security-Token", valid_773491
  var valid_773492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773492 = validateParameter(valid_773492, JString, required = false,
                                 default = nil)
  if valid_773492 != nil:
    section.add "X-Amz-Content-Sha256", valid_773492
  var valid_773493 = header.getOrDefault("X-Amz-Algorithm")
  valid_773493 = validateParameter(valid_773493, JString, required = false,
                                 default = nil)
  if valid_773493 != nil:
    section.add "X-Amz-Algorithm", valid_773493
  var valid_773494 = header.getOrDefault("X-Amz-Signature")
  valid_773494 = validateParameter(valid_773494, JString, required = false,
                                 default = nil)
  if valid_773494 != nil:
    section.add "X-Amz-Signature", valid_773494
  var valid_773495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773495 = validateParameter(valid_773495, JString, required = false,
                                 default = nil)
  if valid_773495 != nil:
    section.add "X-Amz-SignedHeaders", valid_773495
  var valid_773496 = header.getOrDefault("X-Amz-Credential")
  valid_773496 = validateParameter(valid_773496, JString, required = false,
                                 default = nil)
  if valid_773496 != nil:
    section.add "X-Amz-Credential", valid_773496
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773497: Call_GetFieldLevelEncryption20190326_773486;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the field-level encryption configuration information.
  ## 
  let valid = call_773497.validator(path, query, header, formData, body)
  let scheme = call_773497.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773497.url(scheme.get, call_773497.host, call_773497.base,
                         call_773497.route, valid.getOrDefault("path"))
  result = hook(call_773497, url, valid)

proc call*(call_773498: Call_GetFieldLevelEncryption20190326_773486; Id: string): Recallable =
  ## getFieldLevelEncryption20190326
  ## Get the field-level encryption configuration information.
  ##   Id: string (required)
  ##     : Request the ID for the field-level encryption configuration information.
  var path_773499 = newJObject()
  add(path_773499, "Id", newJString(Id))
  result = call_773498.call(path_773499, nil, nil, nil, nil)

var getFieldLevelEncryption20190326* = Call_GetFieldLevelEncryption20190326_773486(
    name: "getFieldLevelEncryption20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/field-level-encryption/{Id}",
    validator: validate_GetFieldLevelEncryption20190326_773487, base: "/",
    url: url_GetFieldLevelEncryption20190326_773488,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFieldLevelEncryptionConfig20190326_773500 = ref object of OpenApiRestCall_772597
proc url_DeleteFieldLevelEncryptionConfig20190326_773502(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/field-level-encryption/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteFieldLevelEncryptionConfig20190326_773501(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Remove a field-level encryption configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the configuration you want to delete from CloudFront.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_773503 = path.getOrDefault("Id")
  valid_773503 = validateParameter(valid_773503, JString, required = true,
                                 default = nil)
  if valid_773503 != nil:
    section.add "Id", valid_773503
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the configuration identity to delete. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773504 = header.getOrDefault("X-Amz-Date")
  valid_773504 = validateParameter(valid_773504, JString, required = false,
                                 default = nil)
  if valid_773504 != nil:
    section.add "X-Amz-Date", valid_773504
  var valid_773505 = header.getOrDefault("X-Amz-Security-Token")
  valid_773505 = validateParameter(valid_773505, JString, required = false,
                                 default = nil)
  if valid_773505 != nil:
    section.add "X-Amz-Security-Token", valid_773505
  var valid_773506 = header.getOrDefault("If-Match")
  valid_773506 = validateParameter(valid_773506, JString, required = false,
                                 default = nil)
  if valid_773506 != nil:
    section.add "If-Match", valid_773506
  var valid_773507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773507 = validateParameter(valid_773507, JString, required = false,
                                 default = nil)
  if valid_773507 != nil:
    section.add "X-Amz-Content-Sha256", valid_773507
  var valid_773508 = header.getOrDefault("X-Amz-Algorithm")
  valid_773508 = validateParameter(valid_773508, JString, required = false,
                                 default = nil)
  if valid_773508 != nil:
    section.add "X-Amz-Algorithm", valid_773508
  var valid_773509 = header.getOrDefault("X-Amz-Signature")
  valid_773509 = validateParameter(valid_773509, JString, required = false,
                                 default = nil)
  if valid_773509 != nil:
    section.add "X-Amz-Signature", valid_773509
  var valid_773510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773510 = validateParameter(valid_773510, JString, required = false,
                                 default = nil)
  if valid_773510 != nil:
    section.add "X-Amz-SignedHeaders", valid_773510
  var valid_773511 = header.getOrDefault("X-Amz-Credential")
  valid_773511 = validateParameter(valid_773511, JString, required = false,
                                 default = nil)
  if valid_773511 != nil:
    section.add "X-Amz-Credential", valid_773511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773512: Call_DeleteFieldLevelEncryptionConfig20190326_773500;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Remove a field-level encryption configuration.
  ## 
  let valid = call_773512.validator(path, query, header, formData, body)
  let scheme = call_773512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773512.url(scheme.get, call_773512.host, call_773512.base,
                         call_773512.route, valid.getOrDefault("path"))
  result = hook(call_773512, url, valid)

proc call*(call_773513: Call_DeleteFieldLevelEncryptionConfig20190326_773500;
          Id: string): Recallable =
  ## deleteFieldLevelEncryptionConfig20190326
  ## Remove a field-level encryption configuration.
  ##   Id: string (required)
  ##     : The ID of the configuration you want to delete from CloudFront.
  var path_773514 = newJObject()
  add(path_773514, "Id", newJString(Id))
  result = call_773513.call(path_773514, nil, nil, nil, nil)

var deleteFieldLevelEncryptionConfig20190326* = Call_DeleteFieldLevelEncryptionConfig20190326_773500(
    name: "deleteFieldLevelEncryptionConfig20190326", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/field-level-encryption/{Id}",
    validator: validate_DeleteFieldLevelEncryptionConfig20190326_773501,
    base: "/", url: url_DeleteFieldLevelEncryptionConfig20190326_773502,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFieldLevelEncryptionProfile20190326_773515 = ref object of OpenApiRestCall_772597
proc url_GetFieldLevelEncryptionProfile20190326_773517(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/field-level-encryption-profile/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetFieldLevelEncryptionProfile20190326_773516(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the field-level encryption profile information.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Get the ID for the field-level encryption profile information.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_773518 = path.getOrDefault("Id")
  valid_773518 = validateParameter(valid_773518, JString, required = true,
                                 default = nil)
  if valid_773518 != nil:
    section.add "Id", valid_773518
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
  var valid_773519 = header.getOrDefault("X-Amz-Date")
  valid_773519 = validateParameter(valid_773519, JString, required = false,
                                 default = nil)
  if valid_773519 != nil:
    section.add "X-Amz-Date", valid_773519
  var valid_773520 = header.getOrDefault("X-Amz-Security-Token")
  valid_773520 = validateParameter(valid_773520, JString, required = false,
                                 default = nil)
  if valid_773520 != nil:
    section.add "X-Amz-Security-Token", valid_773520
  var valid_773521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773521 = validateParameter(valid_773521, JString, required = false,
                                 default = nil)
  if valid_773521 != nil:
    section.add "X-Amz-Content-Sha256", valid_773521
  var valid_773522 = header.getOrDefault("X-Amz-Algorithm")
  valid_773522 = validateParameter(valid_773522, JString, required = false,
                                 default = nil)
  if valid_773522 != nil:
    section.add "X-Amz-Algorithm", valid_773522
  var valid_773523 = header.getOrDefault("X-Amz-Signature")
  valid_773523 = validateParameter(valid_773523, JString, required = false,
                                 default = nil)
  if valid_773523 != nil:
    section.add "X-Amz-Signature", valid_773523
  var valid_773524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773524 = validateParameter(valid_773524, JString, required = false,
                                 default = nil)
  if valid_773524 != nil:
    section.add "X-Amz-SignedHeaders", valid_773524
  var valid_773525 = header.getOrDefault("X-Amz-Credential")
  valid_773525 = validateParameter(valid_773525, JString, required = false,
                                 default = nil)
  if valid_773525 != nil:
    section.add "X-Amz-Credential", valid_773525
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773526: Call_GetFieldLevelEncryptionProfile20190326_773515;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the field-level encryption profile information.
  ## 
  let valid = call_773526.validator(path, query, header, formData, body)
  let scheme = call_773526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773526.url(scheme.get, call_773526.host, call_773526.base,
                         call_773526.route, valid.getOrDefault("path"))
  result = hook(call_773526, url, valid)

proc call*(call_773527: Call_GetFieldLevelEncryptionProfile20190326_773515;
          Id: string): Recallable =
  ## getFieldLevelEncryptionProfile20190326
  ## Get the field-level encryption profile information.
  ##   Id: string (required)
  ##     : Get the ID for the field-level encryption profile information.
  var path_773528 = newJObject()
  add(path_773528, "Id", newJString(Id))
  result = call_773527.call(path_773528, nil, nil, nil, nil)

var getFieldLevelEncryptionProfile20190326* = Call_GetFieldLevelEncryptionProfile20190326_773515(
    name: "getFieldLevelEncryptionProfile20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/field-level-encryption-profile/{Id}",
    validator: validate_GetFieldLevelEncryptionProfile20190326_773516, base: "/",
    url: url_GetFieldLevelEncryptionProfile20190326_773517,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFieldLevelEncryptionProfile20190326_773529 = ref object of OpenApiRestCall_772597
proc url_DeleteFieldLevelEncryptionProfile20190326_773531(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/field-level-encryption-profile/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteFieldLevelEncryptionProfile20190326_773530(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Remove a field-level encryption profile.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Request the ID of the profile you want to delete from CloudFront.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_773532 = path.getOrDefault("Id")
  valid_773532 = validateParameter(valid_773532, JString, required = true,
                                 default = nil)
  if valid_773532 != nil:
    section.add "Id", valid_773532
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the profile to delete. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773533 = header.getOrDefault("X-Amz-Date")
  valid_773533 = validateParameter(valid_773533, JString, required = false,
                                 default = nil)
  if valid_773533 != nil:
    section.add "X-Amz-Date", valid_773533
  var valid_773534 = header.getOrDefault("X-Amz-Security-Token")
  valid_773534 = validateParameter(valid_773534, JString, required = false,
                                 default = nil)
  if valid_773534 != nil:
    section.add "X-Amz-Security-Token", valid_773534
  var valid_773535 = header.getOrDefault("If-Match")
  valid_773535 = validateParameter(valid_773535, JString, required = false,
                                 default = nil)
  if valid_773535 != nil:
    section.add "If-Match", valid_773535
  var valid_773536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773536 = validateParameter(valid_773536, JString, required = false,
                                 default = nil)
  if valid_773536 != nil:
    section.add "X-Amz-Content-Sha256", valid_773536
  var valid_773537 = header.getOrDefault("X-Amz-Algorithm")
  valid_773537 = validateParameter(valid_773537, JString, required = false,
                                 default = nil)
  if valid_773537 != nil:
    section.add "X-Amz-Algorithm", valid_773537
  var valid_773538 = header.getOrDefault("X-Amz-Signature")
  valid_773538 = validateParameter(valid_773538, JString, required = false,
                                 default = nil)
  if valid_773538 != nil:
    section.add "X-Amz-Signature", valid_773538
  var valid_773539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773539 = validateParameter(valid_773539, JString, required = false,
                                 default = nil)
  if valid_773539 != nil:
    section.add "X-Amz-SignedHeaders", valid_773539
  var valid_773540 = header.getOrDefault("X-Amz-Credential")
  valid_773540 = validateParameter(valid_773540, JString, required = false,
                                 default = nil)
  if valid_773540 != nil:
    section.add "X-Amz-Credential", valid_773540
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773541: Call_DeleteFieldLevelEncryptionProfile20190326_773529;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Remove a field-level encryption profile.
  ## 
  let valid = call_773541.validator(path, query, header, formData, body)
  let scheme = call_773541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773541.url(scheme.get, call_773541.host, call_773541.base,
                         call_773541.route, valid.getOrDefault("path"))
  result = hook(call_773541, url, valid)

proc call*(call_773542: Call_DeleteFieldLevelEncryptionProfile20190326_773529;
          Id: string): Recallable =
  ## deleteFieldLevelEncryptionProfile20190326
  ## Remove a field-level encryption profile.
  ##   Id: string (required)
  ##     : Request the ID of the profile you want to delete from CloudFront.
  var path_773543 = newJObject()
  add(path_773543, "Id", newJString(Id))
  result = call_773542.call(path_773543, nil, nil, nil, nil)

var deleteFieldLevelEncryptionProfile20190326* = Call_DeleteFieldLevelEncryptionProfile20190326_773529(
    name: "deleteFieldLevelEncryptionProfile20190326",
    meth: HttpMethod.HttpDelete, host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/field-level-encryption-profile/{Id}",
    validator: validate_DeleteFieldLevelEncryptionProfile20190326_773530,
    base: "/", url: url_DeleteFieldLevelEncryptionProfile20190326_773531,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublicKey20190326_773544 = ref object of OpenApiRestCall_772597
proc url_GetPublicKey20190326_773546(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-03-26/public-key/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetPublicKey20190326_773545(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the public key information.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Request the ID for the public key.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_773547 = path.getOrDefault("Id")
  valid_773547 = validateParameter(valid_773547, JString, required = true,
                                 default = nil)
  if valid_773547 != nil:
    section.add "Id", valid_773547
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
  var valid_773548 = header.getOrDefault("X-Amz-Date")
  valid_773548 = validateParameter(valid_773548, JString, required = false,
                                 default = nil)
  if valid_773548 != nil:
    section.add "X-Amz-Date", valid_773548
  var valid_773549 = header.getOrDefault("X-Amz-Security-Token")
  valid_773549 = validateParameter(valid_773549, JString, required = false,
                                 default = nil)
  if valid_773549 != nil:
    section.add "X-Amz-Security-Token", valid_773549
  var valid_773550 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773550 = validateParameter(valid_773550, JString, required = false,
                                 default = nil)
  if valid_773550 != nil:
    section.add "X-Amz-Content-Sha256", valid_773550
  var valid_773551 = header.getOrDefault("X-Amz-Algorithm")
  valid_773551 = validateParameter(valid_773551, JString, required = false,
                                 default = nil)
  if valid_773551 != nil:
    section.add "X-Amz-Algorithm", valid_773551
  var valid_773552 = header.getOrDefault("X-Amz-Signature")
  valid_773552 = validateParameter(valid_773552, JString, required = false,
                                 default = nil)
  if valid_773552 != nil:
    section.add "X-Amz-Signature", valid_773552
  var valid_773553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773553 = validateParameter(valid_773553, JString, required = false,
                                 default = nil)
  if valid_773553 != nil:
    section.add "X-Amz-SignedHeaders", valid_773553
  var valid_773554 = header.getOrDefault("X-Amz-Credential")
  valid_773554 = validateParameter(valid_773554, JString, required = false,
                                 default = nil)
  if valid_773554 != nil:
    section.add "X-Amz-Credential", valid_773554
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773555: Call_GetPublicKey20190326_773544; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the public key information.
  ## 
  let valid = call_773555.validator(path, query, header, formData, body)
  let scheme = call_773555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773555.url(scheme.get, call_773555.host, call_773555.base,
                         call_773555.route, valid.getOrDefault("path"))
  result = hook(call_773555, url, valid)

proc call*(call_773556: Call_GetPublicKey20190326_773544; Id: string): Recallable =
  ## getPublicKey20190326
  ## Get the public key information.
  ##   Id: string (required)
  ##     : Request the ID for the public key.
  var path_773557 = newJObject()
  add(path_773557, "Id", newJString(Id))
  result = call_773556.call(path_773557, nil, nil, nil, nil)

var getPublicKey20190326* = Call_GetPublicKey20190326_773544(
    name: "getPublicKey20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/public-key/{Id}",
    validator: validate_GetPublicKey20190326_773545, base: "/",
    url: url_GetPublicKey20190326_773546, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePublicKey20190326_773558 = ref object of OpenApiRestCall_772597
proc url_DeletePublicKey20190326_773560(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-03-26/public-key/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeletePublicKey20190326_773559(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Remove a public key you previously added to CloudFront.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the public key you want to remove from CloudFront.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_773561 = path.getOrDefault("Id")
  valid_773561 = validateParameter(valid_773561, JString, required = true,
                                 default = nil)
  if valid_773561 != nil:
    section.add "Id", valid_773561
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the public key identity to delete. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773562 = header.getOrDefault("X-Amz-Date")
  valid_773562 = validateParameter(valid_773562, JString, required = false,
                                 default = nil)
  if valid_773562 != nil:
    section.add "X-Amz-Date", valid_773562
  var valid_773563 = header.getOrDefault("X-Amz-Security-Token")
  valid_773563 = validateParameter(valid_773563, JString, required = false,
                                 default = nil)
  if valid_773563 != nil:
    section.add "X-Amz-Security-Token", valid_773563
  var valid_773564 = header.getOrDefault("If-Match")
  valid_773564 = validateParameter(valid_773564, JString, required = false,
                                 default = nil)
  if valid_773564 != nil:
    section.add "If-Match", valid_773564
  var valid_773565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773565 = validateParameter(valid_773565, JString, required = false,
                                 default = nil)
  if valid_773565 != nil:
    section.add "X-Amz-Content-Sha256", valid_773565
  var valid_773566 = header.getOrDefault("X-Amz-Algorithm")
  valid_773566 = validateParameter(valid_773566, JString, required = false,
                                 default = nil)
  if valid_773566 != nil:
    section.add "X-Amz-Algorithm", valid_773566
  var valid_773567 = header.getOrDefault("X-Amz-Signature")
  valid_773567 = validateParameter(valid_773567, JString, required = false,
                                 default = nil)
  if valid_773567 != nil:
    section.add "X-Amz-Signature", valid_773567
  var valid_773568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773568 = validateParameter(valid_773568, JString, required = false,
                                 default = nil)
  if valid_773568 != nil:
    section.add "X-Amz-SignedHeaders", valid_773568
  var valid_773569 = header.getOrDefault("X-Amz-Credential")
  valid_773569 = validateParameter(valid_773569, JString, required = false,
                                 default = nil)
  if valid_773569 != nil:
    section.add "X-Amz-Credential", valid_773569
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773570: Call_DeletePublicKey20190326_773558; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove a public key you previously added to CloudFront.
  ## 
  let valid = call_773570.validator(path, query, header, formData, body)
  let scheme = call_773570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773570.url(scheme.get, call_773570.host, call_773570.base,
                         call_773570.route, valid.getOrDefault("path"))
  result = hook(call_773570, url, valid)

proc call*(call_773571: Call_DeletePublicKey20190326_773558; Id: string): Recallable =
  ## deletePublicKey20190326
  ## Remove a public key you previously added to CloudFront.
  ##   Id: string (required)
  ##     : The ID of the public key you want to remove from CloudFront.
  var path_773572 = newJObject()
  add(path_773572, "Id", newJString(Id))
  result = call_773571.call(path_773572, nil, nil, nil, nil)

var deletePublicKey20190326* = Call_DeletePublicKey20190326_773558(
    name: "deletePublicKey20190326", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/public-key/{Id}",
    validator: validate_DeletePublicKey20190326_773559, base: "/",
    url: url_DeletePublicKey20190326_773560, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStreamingDistribution20190326_773573 = ref object of OpenApiRestCall_772597
proc url_GetStreamingDistribution20190326_773575(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/streaming-distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetStreamingDistribution20190326_773574(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The streaming distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_773576 = path.getOrDefault("Id")
  valid_773576 = validateParameter(valid_773576, JString, required = true,
                                 default = nil)
  if valid_773576 != nil:
    section.add "Id", valid_773576
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
  var valid_773577 = header.getOrDefault("X-Amz-Date")
  valid_773577 = validateParameter(valid_773577, JString, required = false,
                                 default = nil)
  if valid_773577 != nil:
    section.add "X-Amz-Date", valid_773577
  var valid_773578 = header.getOrDefault("X-Amz-Security-Token")
  valid_773578 = validateParameter(valid_773578, JString, required = false,
                                 default = nil)
  if valid_773578 != nil:
    section.add "X-Amz-Security-Token", valid_773578
  var valid_773579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773579 = validateParameter(valid_773579, JString, required = false,
                                 default = nil)
  if valid_773579 != nil:
    section.add "X-Amz-Content-Sha256", valid_773579
  var valid_773580 = header.getOrDefault("X-Amz-Algorithm")
  valid_773580 = validateParameter(valid_773580, JString, required = false,
                                 default = nil)
  if valid_773580 != nil:
    section.add "X-Amz-Algorithm", valid_773580
  var valid_773581 = header.getOrDefault("X-Amz-Signature")
  valid_773581 = validateParameter(valid_773581, JString, required = false,
                                 default = nil)
  if valid_773581 != nil:
    section.add "X-Amz-Signature", valid_773581
  var valid_773582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773582 = validateParameter(valid_773582, JString, required = false,
                                 default = nil)
  if valid_773582 != nil:
    section.add "X-Amz-SignedHeaders", valid_773582
  var valid_773583 = header.getOrDefault("X-Amz-Credential")
  valid_773583 = validateParameter(valid_773583, JString, required = false,
                                 default = nil)
  if valid_773583 != nil:
    section.add "X-Amz-Credential", valid_773583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773584: Call_GetStreamingDistribution20190326_773573;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
  ## 
  let valid = call_773584.validator(path, query, header, formData, body)
  let scheme = call_773584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773584.url(scheme.get, call_773584.host, call_773584.base,
                         call_773584.route, valid.getOrDefault("path"))
  result = hook(call_773584, url, valid)

proc call*(call_773585: Call_GetStreamingDistribution20190326_773573; Id: string): Recallable =
  ## getStreamingDistribution20190326
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
  ##   Id: string (required)
  ##     : The streaming distribution's ID.
  var path_773586 = newJObject()
  add(path_773586, "Id", newJString(Id))
  result = call_773585.call(path_773586, nil, nil, nil, nil)

var getStreamingDistribution20190326* = Call_GetStreamingDistribution20190326_773573(
    name: "getStreamingDistribution20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/streaming-distribution/{Id}",
    validator: validate_GetStreamingDistribution20190326_773574, base: "/",
    url: url_GetStreamingDistribution20190326_773575,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStreamingDistribution20190326_773587 = ref object of OpenApiRestCall_772597
proc url_DeleteStreamingDistribution20190326_773589(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/streaming-distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteStreamingDistribution20190326_773588(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_773590 = path.getOrDefault("Id")
  valid_773590 = validateParameter(valid_773590, JString, required = true,
                                 default = nil)
  if valid_773590 != nil:
    section.add "Id", valid_773590
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when you disabled the streaming distribution. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773591 = header.getOrDefault("X-Amz-Date")
  valid_773591 = validateParameter(valid_773591, JString, required = false,
                                 default = nil)
  if valid_773591 != nil:
    section.add "X-Amz-Date", valid_773591
  var valid_773592 = header.getOrDefault("X-Amz-Security-Token")
  valid_773592 = validateParameter(valid_773592, JString, required = false,
                                 default = nil)
  if valid_773592 != nil:
    section.add "X-Amz-Security-Token", valid_773592
  var valid_773593 = header.getOrDefault("If-Match")
  valid_773593 = validateParameter(valid_773593, JString, required = false,
                                 default = nil)
  if valid_773593 != nil:
    section.add "If-Match", valid_773593
  var valid_773594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773594 = validateParameter(valid_773594, JString, required = false,
                                 default = nil)
  if valid_773594 != nil:
    section.add "X-Amz-Content-Sha256", valid_773594
  var valid_773595 = header.getOrDefault("X-Amz-Algorithm")
  valid_773595 = validateParameter(valid_773595, JString, required = false,
                                 default = nil)
  if valid_773595 != nil:
    section.add "X-Amz-Algorithm", valid_773595
  var valid_773596 = header.getOrDefault("X-Amz-Signature")
  valid_773596 = validateParameter(valid_773596, JString, required = false,
                                 default = nil)
  if valid_773596 != nil:
    section.add "X-Amz-Signature", valid_773596
  var valid_773597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773597 = validateParameter(valid_773597, JString, required = false,
                                 default = nil)
  if valid_773597 != nil:
    section.add "X-Amz-SignedHeaders", valid_773597
  var valid_773598 = header.getOrDefault("X-Amz-Credential")
  valid_773598 = validateParameter(valid_773598, JString, required = false,
                                 default = nil)
  if valid_773598 != nil:
    section.add "X-Amz-Credential", valid_773598
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773599: Call_DeleteStreamingDistribution20190326_773587;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ## 
  let valid = call_773599.validator(path, query, header, formData, body)
  let scheme = call_773599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773599.url(scheme.get, call_773599.host, call_773599.base,
                         call_773599.route, valid.getOrDefault("path"))
  result = hook(call_773599, url, valid)

proc call*(call_773600: Call_DeleteStreamingDistribution20190326_773587; Id: string): Recallable =
  ## deleteStreamingDistribution20190326
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ##   Id: string (required)
  ##     : The distribution ID. 
  var path_773601 = newJObject()
  add(path_773601, "Id", newJString(Id))
  result = call_773600.call(path_773601, nil, nil, nil, nil)

var deleteStreamingDistribution20190326* = Call_DeleteStreamingDistribution20190326_773587(
    name: "deleteStreamingDistribution20190326", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/streaming-distribution/{Id}",
    validator: validate_DeleteStreamingDistribution20190326_773588, base: "/",
    url: url_DeleteStreamingDistribution20190326_773589,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCloudFrontOriginAccessIdentity20190326_773616 = ref object of OpenApiRestCall_772597
proc url_UpdateCloudFrontOriginAccessIdentity20190326_773618(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateCloudFrontOriginAccessIdentity20190326_773617(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Update an origin access identity. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identity's id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_773619 = path.getOrDefault("Id")
  valid_773619 = validateParameter(valid_773619, JString, required = true,
                                 default = nil)
  if valid_773619 != nil:
    section.add "Id", valid_773619
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the identity's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773620 = header.getOrDefault("X-Amz-Date")
  valid_773620 = validateParameter(valid_773620, JString, required = false,
                                 default = nil)
  if valid_773620 != nil:
    section.add "X-Amz-Date", valid_773620
  var valid_773621 = header.getOrDefault("X-Amz-Security-Token")
  valid_773621 = validateParameter(valid_773621, JString, required = false,
                                 default = nil)
  if valid_773621 != nil:
    section.add "X-Amz-Security-Token", valid_773621
  var valid_773622 = header.getOrDefault("If-Match")
  valid_773622 = validateParameter(valid_773622, JString, required = false,
                                 default = nil)
  if valid_773622 != nil:
    section.add "If-Match", valid_773622
  var valid_773623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773623 = validateParameter(valid_773623, JString, required = false,
                                 default = nil)
  if valid_773623 != nil:
    section.add "X-Amz-Content-Sha256", valid_773623
  var valid_773624 = header.getOrDefault("X-Amz-Algorithm")
  valid_773624 = validateParameter(valid_773624, JString, required = false,
                                 default = nil)
  if valid_773624 != nil:
    section.add "X-Amz-Algorithm", valid_773624
  var valid_773625 = header.getOrDefault("X-Amz-Signature")
  valid_773625 = validateParameter(valid_773625, JString, required = false,
                                 default = nil)
  if valid_773625 != nil:
    section.add "X-Amz-Signature", valid_773625
  var valid_773626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773626 = validateParameter(valid_773626, JString, required = false,
                                 default = nil)
  if valid_773626 != nil:
    section.add "X-Amz-SignedHeaders", valid_773626
  var valid_773627 = header.getOrDefault("X-Amz-Credential")
  valid_773627 = validateParameter(valid_773627, JString, required = false,
                                 default = nil)
  if valid_773627 != nil:
    section.add "X-Amz-Credential", valid_773627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773629: Call_UpdateCloudFrontOriginAccessIdentity20190326_773616;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update an origin access identity. 
  ## 
  let valid = call_773629.validator(path, query, header, formData, body)
  let scheme = call_773629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773629.url(scheme.get, call_773629.host, call_773629.base,
                         call_773629.route, valid.getOrDefault("path"))
  result = hook(call_773629, url, valid)

proc call*(call_773630: Call_UpdateCloudFrontOriginAccessIdentity20190326_773616;
          Id: string; body: JsonNode): Recallable =
  ## updateCloudFrontOriginAccessIdentity20190326
  ## Update an origin access identity. 
  ##   Id: string (required)
  ##     : The identity's id.
  ##   body: JObject (required)
  var path_773631 = newJObject()
  var body_773632 = newJObject()
  add(path_773631, "Id", newJString(Id))
  if body != nil:
    body_773632 = body
  result = call_773630.call(path_773631, nil, nil, nil, body_773632)

var updateCloudFrontOriginAccessIdentity20190326* = Call_UpdateCloudFrontOriginAccessIdentity20190326_773616(
    name: "updateCloudFrontOriginAccessIdentity20190326",
    meth: HttpMethod.HttpPut, host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/origin-access-identity/cloudfront/{Id}/config",
    validator: validate_UpdateCloudFrontOriginAccessIdentity20190326_773617,
    base: "/", url: url_UpdateCloudFrontOriginAccessIdentity20190326_773618,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFrontOriginAccessIdentityConfig20190326_773602 = ref object of OpenApiRestCall_772597
proc url_GetCloudFrontOriginAccessIdentityConfig20190326_773604(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetCloudFrontOriginAccessIdentityConfig20190326_773603(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## Get the configuration information about an origin access identity. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identity's ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_773605 = path.getOrDefault("Id")
  valid_773605 = validateParameter(valid_773605, JString, required = true,
                                 default = nil)
  if valid_773605 != nil:
    section.add "Id", valid_773605
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
  var valid_773606 = header.getOrDefault("X-Amz-Date")
  valid_773606 = validateParameter(valid_773606, JString, required = false,
                                 default = nil)
  if valid_773606 != nil:
    section.add "X-Amz-Date", valid_773606
  var valid_773607 = header.getOrDefault("X-Amz-Security-Token")
  valid_773607 = validateParameter(valid_773607, JString, required = false,
                                 default = nil)
  if valid_773607 != nil:
    section.add "X-Amz-Security-Token", valid_773607
  var valid_773608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773608 = validateParameter(valid_773608, JString, required = false,
                                 default = nil)
  if valid_773608 != nil:
    section.add "X-Amz-Content-Sha256", valid_773608
  var valid_773609 = header.getOrDefault("X-Amz-Algorithm")
  valid_773609 = validateParameter(valid_773609, JString, required = false,
                                 default = nil)
  if valid_773609 != nil:
    section.add "X-Amz-Algorithm", valid_773609
  var valid_773610 = header.getOrDefault("X-Amz-Signature")
  valid_773610 = validateParameter(valid_773610, JString, required = false,
                                 default = nil)
  if valid_773610 != nil:
    section.add "X-Amz-Signature", valid_773610
  var valid_773611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773611 = validateParameter(valid_773611, JString, required = false,
                                 default = nil)
  if valid_773611 != nil:
    section.add "X-Amz-SignedHeaders", valid_773611
  var valid_773612 = header.getOrDefault("X-Amz-Credential")
  valid_773612 = validateParameter(valid_773612, JString, required = false,
                                 default = nil)
  if valid_773612 != nil:
    section.add "X-Amz-Credential", valid_773612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773613: Call_GetCloudFrontOriginAccessIdentityConfig20190326_773602;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the configuration information about an origin access identity. 
  ## 
  let valid = call_773613.validator(path, query, header, formData, body)
  let scheme = call_773613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773613.url(scheme.get, call_773613.host, call_773613.base,
                         call_773613.route, valid.getOrDefault("path"))
  result = hook(call_773613, url, valid)

proc call*(call_773614: Call_GetCloudFrontOriginAccessIdentityConfig20190326_773602;
          Id: string): Recallable =
  ## getCloudFrontOriginAccessIdentityConfig20190326
  ## Get the configuration information about an origin access identity. 
  ##   Id: string (required)
  ##     : The identity's ID. 
  var path_773615 = newJObject()
  add(path_773615, "Id", newJString(Id))
  result = call_773614.call(path_773615, nil, nil, nil, nil)

var getCloudFrontOriginAccessIdentityConfig20190326* = Call_GetCloudFrontOriginAccessIdentityConfig20190326_773602(
    name: "getCloudFrontOriginAccessIdentityConfig20190326",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/origin-access-identity/cloudfront/{Id}/config",
    validator: validate_GetCloudFrontOriginAccessIdentityConfig20190326_773603,
    base: "/", url: url_GetCloudFrontOriginAccessIdentityConfig20190326_773604,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDistribution20190326_773647 = ref object of OpenApiRestCall_772597
proc url_UpdateDistribution20190326_773649(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-03-26/distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateDistribution20190326_773648(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the configuration for a web distribution. </p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using this API action, follow the steps here to get the current configuration and then make your updates, to make sure that you include all of the required fields. To view a summary, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>The update process includes getting the current distribution configuration, updating the XML document that is returned to make your changes, and then submitting an <code>UpdateDistribution</code> request to make the updates.</p> <p>For information about updating a distribution using the CloudFront console instead, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-creating-console.html">Creating a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <p> <b>To update a web distribution using the CloudFront API</b> </p> <ol> <li> <p>Submit a <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_GetDistributionConfig.html">GetDistributionConfig</a> request to get the current configuration and an <code>Etag</code> header for the distribution.</p> <note> <p>If you update the distribution again, you must get a new <code>Etag</code> header.</p> </note> </li> <li> <p>Update the XML document that was returned in the response to your <code>GetDistributionConfig</code> request to include your changes. </p> <important> <p>When you edit the XML file, be aware of the following:</p> <ul> <li> <p>You must strip out the ETag parameter that is returned.</p> </li> <li> <p>Additional fields are required when you update a distribution. There may be fields included in the XML file for features that you haven't configured for your distribution. This is expected and required to successfully update the distribution.</p> </li> <li> <p>You can't change the value of <code>CallerReference</code>. If you try to change this value, CloudFront returns an <code>IllegalUpdate</code> error. </p> </li> <li> <p>The new configuration replaces the existing configuration; the values that you specify in an <code>UpdateDistribution</code> request are not merged into your existing configuration. When you add, delete, or replace values in an element that allows multiple values (for example, <code>CNAME</code>), you must specify all of the values that you want to appear in the updated distribution. In addition, you must update the corresponding <code>Quantity</code> element.</p> </li> </ul> </important> </li> <li> <p>Submit an <code>UpdateDistribution</code> request to update the configuration for your distribution:</p> <ul> <li> <p>In the request body, include the XML document that you updated in Step 2. The request body must include an XML document with a <code>DistributionConfig</code> element.</p> </li> <li> <p>Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GetDistributionConfig</code> request in Step 1.</p> </li> </ul> </li> <li> <p>Review the response to the <code>UpdateDistribution</code> request to confirm that the configuration was successfully updated.</p> </li> <li> <p>Optional: Submit a <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_GetDistribution.html">GetDistribution</a> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> </ol>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution's id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_773650 = path.getOrDefault("Id")
  valid_773650 = validateParameter(valid_773650, JString, required = true,
                                 default = nil)
  if valid_773650 != nil:
    section.add "Id", valid_773650
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the distribution's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773651 = header.getOrDefault("X-Amz-Date")
  valid_773651 = validateParameter(valid_773651, JString, required = false,
                                 default = nil)
  if valid_773651 != nil:
    section.add "X-Amz-Date", valid_773651
  var valid_773652 = header.getOrDefault("X-Amz-Security-Token")
  valid_773652 = validateParameter(valid_773652, JString, required = false,
                                 default = nil)
  if valid_773652 != nil:
    section.add "X-Amz-Security-Token", valid_773652
  var valid_773653 = header.getOrDefault("If-Match")
  valid_773653 = validateParameter(valid_773653, JString, required = false,
                                 default = nil)
  if valid_773653 != nil:
    section.add "If-Match", valid_773653
  var valid_773654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773654 = validateParameter(valid_773654, JString, required = false,
                                 default = nil)
  if valid_773654 != nil:
    section.add "X-Amz-Content-Sha256", valid_773654
  var valid_773655 = header.getOrDefault("X-Amz-Algorithm")
  valid_773655 = validateParameter(valid_773655, JString, required = false,
                                 default = nil)
  if valid_773655 != nil:
    section.add "X-Amz-Algorithm", valid_773655
  var valid_773656 = header.getOrDefault("X-Amz-Signature")
  valid_773656 = validateParameter(valid_773656, JString, required = false,
                                 default = nil)
  if valid_773656 != nil:
    section.add "X-Amz-Signature", valid_773656
  var valid_773657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773657 = validateParameter(valid_773657, JString, required = false,
                                 default = nil)
  if valid_773657 != nil:
    section.add "X-Amz-SignedHeaders", valid_773657
  var valid_773658 = header.getOrDefault("X-Amz-Credential")
  valid_773658 = validateParameter(valid_773658, JString, required = false,
                                 default = nil)
  if valid_773658 != nil:
    section.add "X-Amz-Credential", valid_773658
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773660: Call_UpdateDistribution20190326_773647; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the configuration for a web distribution. </p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using this API action, follow the steps here to get the current configuration and then make your updates, to make sure that you include all of the required fields. To view a summary, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>The update process includes getting the current distribution configuration, updating the XML document that is returned to make your changes, and then submitting an <code>UpdateDistribution</code> request to make the updates.</p> <p>For information about updating a distribution using the CloudFront console instead, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-creating-console.html">Creating a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <p> <b>To update a web distribution using the CloudFront API</b> </p> <ol> <li> <p>Submit a <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_GetDistributionConfig.html">GetDistributionConfig</a> request to get the current configuration and an <code>Etag</code> header for the distribution.</p> <note> <p>If you update the distribution again, you must get a new <code>Etag</code> header.</p> </note> </li> <li> <p>Update the XML document that was returned in the response to your <code>GetDistributionConfig</code> request to include your changes. </p> <important> <p>When you edit the XML file, be aware of the following:</p> <ul> <li> <p>You must strip out the ETag parameter that is returned.</p> </li> <li> <p>Additional fields are required when you update a distribution. There may be fields included in the XML file for features that you haven't configured for your distribution. This is expected and required to successfully update the distribution.</p> </li> <li> <p>You can't change the value of <code>CallerReference</code>. If you try to change this value, CloudFront returns an <code>IllegalUpdate</code> error. </p> </li> <li> <p>The new configuration replaces the existing configuration; the values that you specify in an <code>UpdateDistribution</code> request are not merged into your existing configuration. When you add, delete, or replace values in an element that allows multiple values (for example, <code>CNAME</code>), you must specify all of the values that you want to appear in the updated distribution. In addition, you must update the corresponding <code>Quantity</code> element.</p> </li> </ul> </important> </li> <li> <p>Submit an <code>UpdateDistribution</code> request to update the configuration for your distribution:</p> <ul> <li> <p>In the request body, include the XML document that you updated in Step 2. The request body must include an XML document with a <code>DistributionConfig</code> element.</p> </li> <li> <p>Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GetDistributionConfig</code> request in Step 1.</p> </li> </ul> </li> <li> <p>Review the response to the <code>UpdateDistribution</code> request to confirm that the configuration was successfully updated.</p> </li> <li> <p>Optional: Submit a <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_GetDistribution.html">GetDistribution</a> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> </ol>
  ## 
  let valid = call_773660.validator(path, query, header, formData, body)
  let scheme = call_773660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773660.url(scheme.get, call_773660.host, call_773660.base,
                         call_773660.route, valid.getOrDefault("path"))
  result = hook(call_773660, url, valid)

proc call*(call_773661: Call_UpdateDistribution20190326_773647; Id: string;
          body: JsonNode): Recallable =
  ## updateDistribution20190326
  ## <p>Updates the configuration for a web distribution. </p> <important> <p>When you update a distribution, there are more required fields than when you create a distribution. When you update your distribution by using this API action, follow the steps here to get the current configuration and then make your updates, to make sure that you include all of the required fields. To view a summary, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-overview-required-fields.html">Required Fields for Create Distribution and Update Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> </important> <p>The update process includes getting the current distribution configuration, updating the XML document that is returned to make your changes, and then submitting an <code>UpdateDistribution</code> request to make the updates.</p> <p>For information about updating a distribution using the CloudFront console instead, see <a href="https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-creating-console.html">Creating a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <p> <b>To update a web distribution using the CloudFront API</b> </p> <ol> <li> <p>Submit a <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_GetDistributionConfig.html">GetDistributionConfig</a> request to get the current configuration and an <code>Etag</code> header for the distribution.</p> <note> <p>If you update the distribution again, you must get a new <code>Etag</code> header.</p> </note> </li> <li> <p>Update the XML document that was returned in the response to your <code>GetDistributionConfig</code> request to include your changes. </p> <important> <p>When you edit the XML file, be aware of the following:</p> <ul> <li> <p>You must strip out the ETag parameter that is returned.</p> </li> <li> <p>Additional fields are required when you update a distribution. There may be fields included in the XML file for features that you haven't configured for your distribution. This is expected and required to successfully update the distribution.</p> </li> <li> <p>You can't change the value of <code>CallerReference</code>. If you try to change this value, CloudFront returns an <code>IllegalUpdate</code> error. </p> </li> <li> <p>The new configuration replaces the existing configuration; the values that you specify in an <code>UpdateDistribution</code> request are not merged into your existing configuration. When you add, delete, or replace values in an element that allows multiple values (for example, <code>CNAME</code>), you must specify all of the values that you want to appear in the updated distribution. In addition, you must update the corresponding <code>Quantity</code> element.</p> </li> </ul> </important> </li> <li> <p>Submit an <code>UpdateDistribution</code> request to update the configuration for your distribution:</p> <ul> <li> <p>In the request body, include the XML document that you updated in Step 2. The request body must include an XML document with a <code>DistributionConfig</code> element.</p> </li> <li> <p>Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GetDistributionConfig</code> request in Step 1.</p> </li> </ul> </li> <li> <p>Review the response to the <code>UpdateDistribution</code> request to confirm that the configuration was successfully updated.</p> </li> <li> <p>Optional: Submit a <a href="https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_GetDistribution.html">GetDistribution</a> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> </ol>
  ##   Id: string (required)
  ##     : The distribution's id.
  ##   body: JObject (required)
  var path_773662 = newJObject()
  var body_773663 = newJObject()
  add(path_773662, "Id", newJString(Id))
  if body != nil:
    body_773663 = body
  result = call_773661.call(path_773662, nil, nil, nil, body_773663)

var updateDistribution20190326* = Call_UpdateDistribution20190326_773647(
    name: "updateDistribution20190326", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/distribution/{Id}/config",
    validator: validate_UpdateDistribution20190326_773648, base: "/",
    url: url_UpdateDistribution20190326_773649,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDistributionConfig20190326_773633 = ref object of OpenApiRestCall_772597
proc url_GetDistributionConfig20190326_773635(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-03-26/distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetDistributionConfig20190326_773634(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the configuration information about a distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution's ID. If the ID is empty, an empty distribution configuration is returned.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_773636 = path.getOrDefault("Id")
  valid_773636 = validateParameter(valid_773636, JString, required = true,
                                 default = nil)
  if valid_773636 != nil:
    section.add "Id", valid_773636
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
  var valid_773637 = header.getOrDefault("X-Amz-Date")
  valid_773637 = validateParameter(valid_773637, JString, required = false,
                                 default = nil)
  if valid_773637 != nil:
    section.add "X-Amz-Date", valid_773637
  var valid_773638 = header.getOrDefault("X-Amz-Security-Token")
  valid_773638 = validateParameter(valid_773638, JString, required = false,
                                 default = nil)
  if valid_773638 != nil:
    section.add "X-Amz-Security-Token", valid_773638
  var valid_773639 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773639 = validateParameter(valid_773639, JString, required = false,
                                 default = nil)
  if valid_773639 != nil:
    section.add "X-Amz-Content-Sha256", valid_773639
  var valid_773640 = header.getOrDefault("X-Amz-Algorithm")
  valid_773640 = validateParameter(valid_773640, JString, required = false,
                                 default = nil)
  if valid_773640 != nil:
    section.add "X-Amz-Algorithm", valid_773640
  var valid_773641 = header.getOrDefault("X-Amz-Signature")
  valid_773641 = validateParameter(valid_773641, JString, required = false,
                                 default = nil)
  if valid_773641 != nil:
    section.add "X-Amz-Signature", valid_773641
  var valid_773642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773642 = validateParameter(valid_773642, JString, required = false,
                                 default = nil)
  if valid_773642 != nil:
    section.add "X-Amz-SignedHeaders", valid_773642
  var valid_773643 = header.getOrDefault("X-Amz-Credential")
  valid_773643 = validateParameter(valid_773643, JString, required = false,
                                 default = nil)
  if valid_773643 != nil:
    section.add "X-Amz-Credential", valid_773643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773644: Call_GetDistributionConfig20190326_773633; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the configuration information about a distribution. 
  ## 
  let valid = call_773644.validator(path, query, header, formData, body)
  let scheme = call_773644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773644.url(scheme.get, call_773644.host, call_773644.base,
                         call_773644.route, valid.getOrDefault("path"))
  result = hook(call_773644, url, valid)

proc call*(call_773645: Call_GetDistributionConfig20190326_773633; Id: string): Recallable =
  ## getDistributionConfig20190326
  ## Get the configuration information about a distribution. 
  ##   Id: string (required)
  ##     : The distribution's ID. If the ID is empty, an empty distribution configuration is returned.
  var path_773646 = newJObject()
  add(path_773646, "Id", newJString(Id))
  result = call_773645.call(path_773646, nil, nil, nil, nil)

var getDistributionConfig20190326* = Call_GetDistributionConfig20190326_773633(
    name: "getDistributionConfig20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/distribution/{Id}/config",
    validator: validate_GetDistributionConfig20190326_773634, base: "/",
    url: url_GetDistributionConfig20190326_773635,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFieldLevelEncryptionConfig20190326_773678 = ref object of OpenApiRestCall_772597
proc url_UpdateFieldLevelEncryptionConfig20190326_773680(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/field-level-encryption/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateFieldLevelEncryptionConfig20190326_773679(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Update a field-level encryption configuration. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the configuration you want to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_773681 = path.getOrDefault("Id")
  valid_773681 = validateParameter(valid_773681, JString, required = true,
                                 default = nil)
  if valid_773681 != nil:
    section.add "Id", valid_773681
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the configuration identity to update. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773682 = header.getOrDefault("X-Amz-Date")
  valid_773682 = validateParameter(valid_773682, JString, required = false,
                                 default = nil)
  if valid_773682 != nil:
    section.add "X-Amz-Date", valid_773682
  var valid_773683 = header.getOrDefault("X-Amz-Security-Token")
  valid_773683 = validateParameter(valid_773683, JString, required = false,
                                 default = nil)
  if valid_773683 != nil:
    section.add "X-Amz-Security-Token", valid_773683
  var valid_773684 = header.getOrDefault("If-Match")
  valid_773684 = validateParameter(valid_773684, JString, required = false,
                                 default = nil)
  if valid_773684 != nil:
    section.add "If-Match", valid_773684
  var valid_773685 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773685 = validateParameter(valid_773685, JString, required = false,
                                 default = nil)
  if valid_773685 != nil:
    section.add "X-Amz-Content-Sha256", valid_773685
  var valid_773686 = header.getOrDefault("X-Amz-Algorithm")
  valid_773686 = validateParameter(valid_773686, JString, required = false,
                                 default = nil)
  if valid_773686 != nil:
    section.add "X-Amz-Algorithm", valid_773686
  var valid_773687 = header.getOrDefault("X-Amz-Signature")
  valid_773687 = validateParameter(valid_773687, JString, required = false,
                                 default = nil)
  if valid_773687 != nil:
    section.add "X-Amz-Signature", valid_773687
  var valid_773688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773688 = validateParameter(valid_773688, JString, required = false,
                                 default = nil)
  if valid_773688 != nil:
    section.add "X-Amz-SignedHeaders", valid_773688
  var valid_773689 = header.getOrDefault("X-Amz-Credential")
  valid_773689 = validateParameter(valid_773689, JString, required = false,
                                 default = nil)
  if valid_773689 != nil:
    section.add "X-Amz-Credential", valid_773689
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773691: Call_UpdateFieldLevelEncryptionConfig20190326_773678;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update a field-level encryption configuration. 
  ## 
  let valid = call_773691.validator(path, query, header, formData, body)
  let scheme = call_773691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773691.url(scheme.get, call_773691.host, call_773691.base,
                         call_773691.route, valid.getOrDefault("path"))
  result = hook(call_773691, url, valid)

proc call*(call_773692: Call_UpdateFieldLevelEncryptionConfig20190326_773678;
          Id: string; body: JsonNode): Recallable =
  ## updateFieldLevelEncryptionConfig20190326
  ## Update a field-level encryption configuration. 
  ##   Id: string (required)
  ##     : The ID of the configuration you want to update.
  ##   body: JObject (required)
  var path_773693 = newJObject()
  var body_773694 = newJObject()
  add(path_773693, "Id", newJString(Id))
  if body != nil:
    body_773694 = body
  result = call_773692.call(path_773693, nil, nil, nil, body_773694)

var updateFieldLevelEncryptionConfig20190326* = Call_UpdateFieldLevelEncryptionConfig20190326_773678(
    name: "updateFieldLevelEncryptionConfig20190326", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/field-level-encryption/{Id}/config",
    validator: validate_UpdateFieldLevelEncryptionConfig20190326_773679,
    base: "/", url: url_UpdateFieldLevelEncryptionConfig20190326_773680,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFieldLevelEncryptionConfig20190326_773664 = ref object of OpenApiRestCall_772597
proc url_GetFieldLevelEncryptionConfig20190326_773666(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/field-level-encryption/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetFieldLevelEncryptionConfig20190326_773665(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the field-level encryption configuration information.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Request the ID for the field-level encryption configuration information.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_773667 = path.getOrDefault("Id")
  valid_773667 = validateParameter(valid_773667, JString, required = true,
                                 default = nil)
  if valid_773667 != nil:
    section.add "Id", valid_773667
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
  var valid_773668 = header.getOrDefault("X-Amz-Date")
  valid_773668 = validateParameter(valid_773668, JString, required = false,
                                 default = nil)
  if valid_773668 != nil:
    section.add "X-Amz-Date", valid_773668
  var valid_773669 = header.getOrDefault("X-Amz-Security-Token")
  valid_773669 = validateParameter(valid_773669, JString, required = false,
                                 default = nil)
  if valid_773669 != nil:
    section.add "X-Amz-Security-Token", valid_773669
  var valid_773670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773670 = validateParameter(valid_773670, JString, required = false,
                                 default = nil)
  if valid_773670 != nil:
    section.add "X-Amz-Content-Sha256", valid_773670
  var valid_773671 = header.getOrDefault("X-Amz-Algorithm")
  valid_773671 = validateParameter(valid_773671, JString, required = false,
                                 default = nil)
  if valid_773671 != nil:
    section.add "X-Amz-Algorithm", valid_773671
  var valid_773672 = header.getOrDefault("X-Amz-Signature")
  valid_773672 = validateParameter(valid_773672, JString, required = false,
                                 default = nil)
  if valid_773672 != nil:
    section.add "X-Amz-Signature", valid_773672
  var valid_773673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773673 = validateParameter(valid_773673, JString, required = false,
                                 default = nil)
  if valid_773673 != nil:
    section.add "X-Amz-SignedHeaders", valid_773673
  var valid_773674 = header.getOrDefault("X-Amz-Credential")
  valid_773674 = validateParameter(valid_773674, JString, required = false,
                                 default = nil)
  if valid_773674 != nil:
    section.add "X-Amz-Credential", valid_773674
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773675: Call_GetFieldLevelEncryptionConfig20190326_773664;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the field-level encryption configuration information.
  ## 
  let valid = call_773675.validator(path, query, header, formData, body)
  let scheme = call_773675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773675.url(scheme.get, call_773675.host, call_773675.base,
                         call_773675.route, valid.getOrDefault("path"))
  result = hook(call_773675, url, valid)

proc call*(call_773676: Call_GetFieldLevelEncryptionConfig20190326_773664;
          Id: string): Recallable =
  ## getFieldLevelEncryptionConfig20190326
  ## Get the field-level encryption configuration information.
  ##   Id: string (required)
  ##     : Request the ID for the field-level encryption configuration information.
  var path_773677 = newJObject()
  add(path_773677, "Id", newJString(Id))
  result = call_773676.call(path_773677, nil, nil, nil, nil)

var getFieldLevelEncryptionConfig20190326* = Call_GetFieldLevelEncryptionConfig20190326_773664(
    name: "getFieldLevelEncryptionConfig20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/field-level-encryption/{Id}/config",
    validator: validate_GetFieldLevelEncryptionConfig20190326_773665, base: "/",
    url: url_GetFieldLevelEncryptionConfig20190326_773666,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFieldLevelEncryptionProfile20190326_773709 = ref object of OpenApiRestCall_772597
proc url_UpdateFieldLevelEncryptionProfile20190326_773711(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/field-level-encryption-profile/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateFieldLevelEncryptionProfile20190326_773710(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Update a field-level encryption profile. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The ID of the field-level encryption profile request. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_773712 = path.getOrDefault("Id")
  valid_773712 = validateParameter(valid_773712, JString, required = true,
                                 default = nil)
  if valid_773712 != nil:
    section.add "Id", valid_773712
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the profile identity to update. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773713 = header.getOrDefault("X-Amz-Date")
  valid_773713 = validateParameter(valid_773713, JString, required = false,
                                 default = nil)
  if valid_773713 != nil:
    section.add "X-Amz-Date", valid_773713
  var valid_773714 = header.getOrDefault("X-Amz-Security-Token")
  valid_773714 = validateParameter(valid_773714, JString, required = false,
                                 default = nil)
  if valid_773714 != nil:
    section.add "X-Amz-Security-Token", valid_773714
  var valid_773715 = header.getOrDefault("If-Match")
  valid_773715 = validateParameter(valid_773715, JString, required = false,
                                 default = nil)
  if valid_773715 != nil:
    section.add "If-Match", valid_773715
  var valid_773716 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773716 = validateParameter(valid_773716, JString, required = false,
                                 default = nil)
  if valid_773716 != nil:
    section.add "X-Amz-Content-Sha256", valid_773716
  var valid_773717 = header.getOrDefault("X-Amz-Algorithm")
  valid_773717 = validateParameter(valid_773717, JString, required = false,
                                 default = nil)
  if valid_773717 != nil:
    section.add "X-Amz-Algorithm", valid_773717
  var valid_773718 = header.getOrDefault("X-Amz-Signature")
  valid_773718 = validateParameter(valid_773718, JString, required = false,
                                 default = nil)
  if valid_773718 != nil:
    section.add "X-Amz-Signature", valid_773718
  var valid_773719 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773719 = validateParameter(valid_773719, JString, required = false,
                                 default = nil)
  if valid_773719 != nil:
    section.add "X-Amz-SignedHeaders", valid_773719
  var valid_773720 = header.getOrDefault("X-Amz-Credential")
  valid_773720 = validateParameter(valid_773720, JString, required = false,
                                 default = nil)
  if valid_773720 != nil:
    section.add "X-Amz-Credential", valid_773720
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773722: Call_UpdateFieldLevelEncryptionProfile20190326_773709;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update a field-level encryption profile. 
  ## 
  let valid = call_773722.validator(path, query, header, formData, body)
  let scheme = call_773722.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773722.url(scheme.get, call_773722.host, call_773722.base,
                         call_773722.route, valid.getOrDefault("path"))
  result = hook(call_773722, url, valid)

proc call*(call_773723: Call_UpdateFieldLevelEncryptionProfile20190326_773709;
          Id: string; body: JsonNode): Recallable =
  ## updateFieldLevelEncryptionProfile20190326
  ## Update a field-level encryption profile. 
  ##   Id: string (required)
  ##     : The ID of the field-level encryption profile request. 
  ##   body: JObject (required)
  var path_773724 = newJObject()
  var body_773725 = newJObject()
  add(path_773724, "Id", newJString(Id))
  if body != nil:
    body_773725 = body
  result = call_773723.call(path_773724, nil, nil, nil, body_773725)

var updateFieldLevelEncryptionProfile20190326* = Call_UpdateFieldLevelEncryptionProfile20190326_773709(
    name: "updateFieldLevelEncryptionProfile20190326", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/field-level-encryption-profile/{Id}/config",
    validator: validate_UpdateFieldLevelEncryptionProfile20190326_773710,
    base: "/", url: url_UpdateFieldLevelEncryptionProfile20190326_773711,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFieldLevelEncryptionProfileConfig20190326_773695 = ref object of OpenApiRestCall_772597
proc url_GetFieldLevelEncryptionProfileConfig20190326_773697(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/field-level-encryption-profile/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetFieldLevelEncryptionProfileConfig20190326_773696(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the field-level encryption profile configuration information.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Get the ID for the field-level encryption profile configuration information.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_773698 = path.getOrDefault("Id")
  valid_773698 = validateParameter(valid_773698, JString, required = true,
                                 default = nil)
  if valid_773698 != nil:
    section.add "Id", valid_773698
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
  var valid_773699 = header.getOrDefault("X-Amz-Date")
  valid_773699 = validateParameter(valid_773699, JString, required = false,
                                 default = nil)
  if valid_773699 != nil:
    section.add "X-Amz-Date", valid_773699
  var valid_773700 = header.getOrDefault("X-Amz-Security-Token")
  valid_773700 = validateParameter(valid_773700, JString, required = false,
                                 default = nil)
  if valid_773700 != nil:
    section.add "X-Amz-Security-Token", valid_773700
  var valid_773701 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773701 = validateParameter(valid_773701, JString, required = false,
                                 default = nil)
  if valid_773701 != nil:
    section.add "X-Amz-Content-Sha256", valid_773701
  var valid_773702 = header.getOrDefault("X-Amz-Algorithm")
  valid_773702 = validateParameter(valid_773702, JString, required = false,
                                 default = nil)
  if valid_773702 != nil:
    section.add "X-Amz-Algorithm", valid_773702
  var valid_773703 = header.getOrDefault("X-Amz-Signature")
  valid_773703 = validateParameter(valid_773703, JString, required = false,
                                 default = nil)
  if valid_773703 != nil:
    section.add "X-Amz-Signature", valid_773703
  var valid_773704 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773704 = validateParameter(valid_773704, JString, required = false,
                                 default = nil)
  if valid_773704 != nil:
    section.add "X-Amz-SignedHeaders", valid_773704
  var valid_773705 = header.getOrDefault("X-Amz-Credential")
  valid_773705 = validateParameter(valid_773705, JString, required = false,
                                 default = nil)
  if valid_773705 != nil:
    section.add "X-Amz-Credential", valid_773705
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773706: Call_GetFieldLevelEncryptionProfileConfig20190326_773695;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the field-level encryption profile configuration information.
  ## 
  let valid = call_773706.validator(path, query, header, formData, body)
  let scheme = call_773706.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773706.url(scheme.get, call_773706.host, call_773706.base,
                         call_773706.route, valid.getOrDefault("path"))
  result = hook(call_773706, url, valid)

proc call*(call_773707: Call_GetFieldLevelEncryptionProfileConfig20190326_773695;
          Id: string): Recallable =
  ## getFieldLevelEncryptionProfileConfig20190326
  ## Get the field-level encryption profile configuration information.
  ##   Id: string (required)
  ##     : Get the ID for the field-level encryption profile configuration information.
  var path_773708 = newJObject()
  add(path_773708, "Id", newJString(Id))
  result = call_773707.call(path_773708, nil, nil, nil, nil)

var getFieldLevelEncryptionProfileConfig20190326* = Call_GetFieldLevelEncryptionProfileConfig20190326_773695(
    name: "getFieldLevelEncryptionProfileConfig20190326",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/field-level-encryption-profile/{Id}/config",
    validator: validate_GetFieldLevelEncryptionProfileConfig20190326_773696,
    base: "/", url: url_GetFieldLevelEncryptionProfileConfig20190326_773697,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvalidation20190326_773726 = ref object of OpenApiRestCall_772597
proc url_GetInvalidation20190326_773728(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path, "`DistributionId` is a required path parameter"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-03-26/distribution/"),
               (kind: VariableSegment, value: "DistributionId"),
               (kind: ConstantSegment, value: "/invalidation/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetInvalidation20190326_773727(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the information about an invalidation. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identifier for the invalidation request, for example, <code>IDFDVBD632BHDS5</code>.
  ##   DistributionId: JString (required)
  ##                 : The distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_773729 = path.getOrDefault("Id")
  valid_773729 = validateParameter(valid_773729, JString, required = true,
                                 default = nil)
  if valid_773729 != nil:
    section.add "Id", valid_773729
  var valid_773730 = path.getOrDefault("DistributionId")
  valid_773730 = validateParameter(valid_773730, JString, required = true,
                                 default = nil)
  if valid_773730 != nil:
    section.add "DistributionId", valid_773730
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
  var valid_773731 = header.getOrDefault("X-Amz-Date")
  valid_773731 = validateParameter(valid_773731, JString, required = false,
                                 default = nil)
  if valid_773731 != nil:
    section.add "X-Amz-Date", valid_773731
  var valid_773732 = header.getOrDefault("X-Amz-Security-Token")
  valid_773732 = validateParameter(valid_773732, JString, required = false,
                                 default = nil)
  if valid_773732 != nil:
    section.add "X-Amz-Security-Token", valid_773732
  var valid_773733 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773733 = validateParameter(valid_773733, JString, required = false,
                                 default = nil)
  if valid_773733 != nil:
    section.add "X-Amz-Content-Sha256", valid_773733
  var valid_773734 = header.getOrDefault("X-Amz-Algorithm")
  valid_773734 = validateParameter(valid_773734, JString, required = false,
                                 default = nil)
  if valid_773734 != nil:
    section.add "X-Amz-Algorithm", valid_773734
  var valid_773735 = header.getOrDefault("X-Amz-Signature")
  valid_773735 = validateParameter(valid_773735, JString, required = false,
                                 default = nil)
  if valid_773735 != nil:
    section.add "X-Amz-Signature", valid_773735
  var valid_773736 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773736 = validateParameter(valid_773736, JString, required = false,
                                 default = nil)
  if valid_773736 != nil:
    section.add "X-Amz-SignedHeaders", valid_773736
  var valid_773737 = header.getOrDefault("X-Amz-Credential")
  valid_773737 = validateParameter(valid_773737, JString, required = false,
                                 default = nil)
  if valid_773737 != nil:
    section.add "X-Amz-Credential", valid_773737
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773738: Call_GetInvalidation20190326_773726; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the information about an invalidation. 
  ## 
  let valid = call_773738.validator(path, query, header, formData, body)
  let scheme = call_773738.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773738.url(scheme.get, call_773738.host, call_773738.base,
                         call_773738.route, valid.getOrDefault("path"))
  result = hook(call_773738, url, valid)

proc call*(call_773739: Call_GetInvalidation20190326_773726; Id: string;
          DistributionId: string): Recallable =
  ## getInvalidation20190326
  ## Get the information about an invalidation. 
  ##   Id: string (required)
  ##     : The identifier for the invalidation request, for example, <code>IDFDVBD632BHDS5</code>.
  ##   DistributionId: string (required)
  ##                 : The distribution's ID.
  var path_773740 = newJObject()
  add(path_773740, "Id", newJString(Id))
  add(path_773740, "DistributionId", newJString(DistributionId))
  result = call_773739.call(path_773740, nil, nil, nil, nil)

var getInvalidation20190326* = Call_GetInvalidation20190326_773726(
    name: "getInvalidation20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/distribution/{DistributionId}/invalidation/{Id}",
    validator: validate_GetInvalidation20190326_773727, base: "/",
    url: url_GetInvalidation20190326_773728, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePublicKey20190326_773755 = ref object of OpenApiRestCall_772597
proc url_UpdatePublicKey20190326_773757(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-03-26/public-key/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdatePublicKey20190326_773756(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Update public key information. Note that the only value you can change is the comment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : ID of the public key to be updated.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_773758 = path.getOrDefault("Id")
  valid_773758 = validateParameter(valid_773758, JString, required = true,
                                 default = nil)
  if valid_773758 != nil:
    section.add "Id", valid_773758
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the public key to update. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773759 = header.getOrDefault("X-Amz-Date")
  valid_773759 = validateParameter(valid_773759, JString, required = false,
                                 default = nil)
  if valid_773759 != nil:
    section.add "X-Amz-Date", valid_773759
  var valid_773760 = header.getOrDefault("X-Amz-Security-Token")
  valid_773760 = validateParameter(valid_773760, JString, required = false,
                                 default = nil)
  if valid_773760 != nil:
    section.add "X-Amz-Security-Token", valid_773760
  var valid_773761 = header.getOrDefault("If-Match")
  valid_773761 = validateParameter(valid_773761, JString, required = false,
                                 default = nil)
  if valid_773761 != nil:
    section.add "If-Match", valid_773761
  var valid_773762 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773762 = validateParameter(valid_773762, JString, required = false,
                                 default = nil)
  if valid_773762 != nil:
    section.add "X-Amz-Content-Sha256", valid_773762
  var valid_773763 = header.getOrDefault("X-Amz-Algorithm")
  valid_773763 = validateParameter(valid_773763, JString, required = false,
                                 default = nil)
  if valid_773763 != nil:
    section.add "X-Amz-Algorithm", valid_773763
  var valid_773764 = header.getOrDefault("X-Amz-Signature")
  valid_773764 = validateParameter(valid_773764, JString, required = false,
                                 default = nil)
  if valid_773764 != nil:
    section.add "X-Amz-Signature", valid_773764
  var valid_773765 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773765 = validateParameter(valid_773765, JString, required = false,
                                 default = nil)
  if valid_773765 != nil:
    section.add "X-Amz-SignedHeaders", valid_773765
  var valid_773766 = header.getOrDefault("X-Amz-Credential")
  valid_773766 = validateParameter(valid_773766, JString, required = false,
                                 default = nil)
  if valid_773766 != nil:
    section.add "X-Amz-Credential", valid_773766
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773768: Call_UpdatePublicKey20190326_773755; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update public key information. Note that the only value you can change is the comment.
  ## 
  let valid = call_773768.validator(path, query, header, formData, body)
  let scheme = call_773768.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773768.url(scheme.get, call_773768.host, call_773768.base,
                         call_773768.route, valid.getOrDefault("path"))
  result = hook(call_773768, url, valid)

proc call*(call_773769: Call_UpdatePublicKey20190326_773755; Id: string;
          body: JsonNode): Recallable =
  ## updatePublicKey20190326
  ## Update public key information. Note that the only value you can change is the comment.
  ##   Id: string (required)
  ##     : ID of the public key to be updated.
  ##   body: JObject (required)
  var path_773770 = newJObject()
  var body_773771 = newJObject()
  add(path_773770, "Id", newJString(Id))
  if body != nil:
    body_773771 = body
  result = call_773769.call(path_773770, nil, nil, nil, body_773771)

var updatePublicKey20190326* = Call_UpdatePublicKey20190326_773755(
    name: "updatePublicKey20190326", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/public-key/{Id}/config",
    validator: validate_UpdatePublicKey20190326_773756, base: "/",
    url: url_UpdatePublicKey20190326_773757, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPublicKeyConfig20190326_773741 = ref object of OpenApiRestCall_772597
proc url_GetPublicKeyConfig20190326_773743(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-03-26/public-key/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetPublicKeyConfig20190326_773742(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Return public key configuration informaation
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : Request the ID for the public key configuration.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_773744 = path.getOrDefault("Id")
  valid_773744 = validateParameter(valid_773744, JString, required = true,
                                 default = nil)
  if valid_773744 != nil:
    section.add "Id", valid_773744
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
  var valid_773745 = header.getOrDefault("X-Amz-Date")
  valid_773745 = validateParameter(valid_773745, JString, required = false,
                                 default = nil)
  if valid_773745 != nil:
    section.add "X-Amz-Date", valid_773745
  var valid_773746 = header.getOrDefault("X-Amz-Security-Token")
  valid_773746 = validateParameter(valid_773746, JString, required = false,
                                 default = nil)
  if valid_773746 != nil:
    section.add "X-Amz-Security-Token", valid_773746
  var valid_773747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773747 = validateParameter(valid_773747, JString, required = false,
                                 default = nil)
  if valid_773747 != nil:
    section.add "X-Amz-Content-Sha256", valid_773747
  var valid_773748 = header.getOrDefault("X-Amz-Algorithm")
  valid_773748 = validateParameter(valid_773748, JString, required = false,
                                 default = nil)
  if valid_773748 != nil:
    section.add "X-Amz-Algorithm", valid_773748
  var valid_773749 = header.getOrDefault("X-Amz-Signature")
  valid_773749 = validateParameter(valid_773749, JString, required = false,
                                 default = nil)
  if valid_773749 != nil:
    section.add "X-Amz-Signature", valid_773749
  var valid_773750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773750 = validateParameter(valid_773750, JString, required = false,
                                 default = nil)
  if valid_773750 != nil:
    section.add "X-Amz-SignedHeaders", valid_773750
  var valid_773751 = header.getOrDefault("X-Amz-Credential")
  valid_773751 = validateParameter(valid_773751, JString, required = false,
                                 default = nil)
  if valid_773751 != nil:
    section.add "X-Amz-Credential", valid_773751
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773752: Call_GetPublicKeyConfig20190326_773741; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Return public key configuration informaation
  ## 
  let valid = call_773752.validator(path, query, header, formData, body)
  let scheme = call_773752.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773752.url(scheme.get, call_773752.host, call_773752.base,
                         call_773752.route, valid.getOrDefault("path"))
  result = hook(call_773752, url, valid)

proc call*(call_773753: Call_GetPublicKeyConfig20190326_773741; Id: string): Recallable =
  ## getPublicKeyConfig20190326
  ## Return public key configuration informaation
  ##   Id: string (required)
  ##     : Request the ID for the public key configuration.
  var path_773754 = newJObject()
  add(path_773754, "Id", newJString(Id))
  result = call_773753.call(path_773754, nil, nil, nil, nil)

var getPublicKeyConfig20190326* = Call_GetPublicKeyConfig20190326_773741(
    name: "getPublicKeyConfig20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/public-key/{Id}/config",
    validator: validate_GetPublicKeyConfig20190326_773742, base: "/",
    url: url_GetPublicKeyConfig20190326_773743,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStreamingDistribution20190326_773786 = ref object of OpenApiRestCall_772597
proc url_UpdateStreamingDistribution20190326_773788(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/streaming-distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateStreamingDistribution20190326_773787(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Update a streaming distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The streaming distribution's id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_773789 = path.getOrDefault("Id")
  valid_773789 = validateParameter(valid_773789, JString, required = true,
                                 default = nil)
  if valid_773789 != nil:
    section.add "Id", valid_773789
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the streaming distribution's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773790 = header.getOrDefault("X-Amz-Date")
  valid_773790 = validateParameter(valid_773790, JString, required = false,
                                 default = nil)
  if valid_773790 != nil:
    section.add "X-Amz-Date", valid_773790
  var valid_773791 = header.getOrDefault("X-Amz-Security-Token")
  valid_773791 = validateParameter(valid_773791, JString, required = false,
                                 default = nil)
  if valid_773791 != nil:
    section.add "X-Amz-Security-Token", valid_773791
  var valid_773792 = header.getOrDefault("If-Match")
  valid_773792 = validateParameter(valid_773792, JString, required = false,
                                 default = nil)
  if valid_773792 != nil:
    section.add "If-Match", valid_773792
  var valid_773793 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773793 = validateParameter(valid_773793, JString, required = false,
                                 default = nil)
  if valid_773793 != nil:
    section.add "X-Amz-Content-Sha256", valid_773793
  var valid_773794 = header.getOrDefault("X-Amz-Algorithm")
  valid_773794 = validateParameter(valid_773794, JString, required = false,
                                 default = nil)
  if valid_773794 != nil:
    section.add "X-Amz-Algorithm", valid_773794
  var valid_773795 = header.getOrDefault("X-Amz-Signature")
  valid_773795 = validateParameter(valid_773795, JString, required = false,
                                 default = nil)
  if valid_773795 != nil:
    section.add "X-Amz-Signature", valid_773795
  var valid_773796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773796 = validateParameter(valid_773796, JString, required = false,
                                 default = nil)
  if valid_773796 != nil:
    section.add "X-Amz-SignedHeaders", valid_773796
  var valid_773797 = header.getOrDefault("X-Amz-Credential")
  valid_773797 = validateParameter(valid_773797, JString, required = false,
                                 default = nil)
  if valid_773797 != nil:
    section.add "X-Amz-Credential", valid_773797
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773799: Call_UpdateStreamingDistribution20190326_773786;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update a streaming distribution. 
  ## 
  let valid = call_773799.validator(path, query, header, formData, body)
  let scheme = call_773799.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773799.url(scheme.get, call_773799.host, call_773799.base,
                         call_773799.route, valid.getOrDefault("path"))
  result = hook(call_773799, url, valid)

proc call*(call_773800: Call_UpdateStreamingDistribution20190326_773786;
          Id: string; body: JsonNode): Recallable =
  ## updateStreamingDistribution20190326
  ## Update a streaming distribution. 
  ##   Id: string (required)
  ##     : The streaming distribution's id.
  ##   body: JObject (required)
  var path_773801 = newJObject()
  var body_773802 = newJObject()
  add(path_773801, "Id", newJString(Id))
  if body != nil:
    body_773802 = body
  result = call_773800.call(path_773801, nil, nil, nil, body_773802)

var updateStreamingDistribution20190326* = Call_UpdateStreamingDistribution20190326_773786(
    name: "updateStreamingDistribution20190326", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/streaming-distribution/{Id}/config",
    validator: validate_UpdateStreamingDistribution20190326_773787, base: "/",
    url: url_UpdateStreamingDistribution20190326_773788,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStreamingDistributionConfig20190326_773772 = ref object of OpenApiRestCall_772597
proc url_GetStreamingDistributionConfig20190326_773774(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/streaming-distribution/"),
               (kind: VariableSegment, value: "Id"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetStreamingDistributionConfig20190326_773773(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the configuration information about a streaming distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The streaming distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_773775 = path.getOrDefault("Id")
  valid_773775 = validateParameter(valid_773775, JString, required = true,
                                 default = nil)
  if valid_773775 != nil:
    section.add "Id", valid_773775
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
  var valid_773776 = header.getOrDefault("X-Amz-Date")
  valid_773776 = validateParameter(valid_773776, JString, required = false,
                                 default = nil)
  if valid_773776 != nil:
    section.add "X-Amz-Date", valid_773776
  var valid_773777 = header.getOrDefault("X-Amz-Security-Token")
  valid_773777 = validateParameter(valid_773777, JString, required = false,
                                 default = nil)
  if valid_773777 != nil:
    section.add "X-Amz-Security-Token", valid_773777
  var valid_773778 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773778 = validateParameter(valid_773778, JString, required = false,
                                 default = nil)
  if valid_773778 != nil:
    section.add "X-Amz-Content-Sha256", valid_773778
  var valid_773779 = header.getOrDefault("X-Amz-Algorithm")
  valid_773779 = validateParameter(valid_773779, JString, required = false,
                                 default = nil)
  if valid_773779 != nil:
    section.add "X-Amz-Algorithm", valid_773779
  var valid_773780 = header.getOrDefault("X-Amz-Signature")
  valid_773780 = validateParameter(valid_773780, JString, required = false,
                                 default = nil)
  if valid_773780 != nil:
    section.add "X-Amz-Signature", valid_773780
  var valid_773781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773781 = validateParameter(valid_773781, JString, required = false,
                                 default = nil)
  if valid_773781 != nil:
    section.add "X-Amz-SignedHeaders", valid_773781
  var valid_773782 = header.getOrDefault("X-Amz-Credential")
  valid_773782 = validateParameter(valid_773782, JString, required = false,
                                 default = nil)
  if valid_773782 != nil:
    section.add "X-Amz-Credential", valid_773782
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773783: Call_GetStreamingDistributionConfig20190326_773772;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the configuration information about a streaming distribution. 
  ## 
  let valid = call_773783.validator(path, query, header, formData, body)
  let scheme = call_773783.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773783.url(scheme.get, call_773783.host, call_773783.base,
                         call_773783.route, valid.getOrDefault("path"))
  result = hook(call_773783, url, valid)

proc call*(call_773784: Call_GetStreamingDistributionConfig20190326_773772;
          Id: string): Recallable =
  ## getStreamingDistributionConfig20190326
  ## Get the configuration information about a streaming distribution. 
  ##   Id: string (required)
  ##     : The streaming distribution's ID.
  var path_773785 = newJObject()
  add(path_773785, "Id", newJString(Id))
  result = call_773784.call(path_773785, nil, nil, nil, nil)

var getStreamingDistributionConfig20190326* = Call_GetStreamingDistributionConfig20190326_773772(
    name: "getStreamingDistributionConfig20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/streaming-distribution/{Id}/config",
    validator: validate_GetStreamingDistributionConfig20190326_773773, base: "/",
    url: url_GetStreamingDistributionConfig20190326_773774,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDistributionsByWebACLId20190326_773803 = ref object of OpenApiRestCall_772597
proc url_ListDistributionsByWebACLId20190326_773805(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "WebACLId" in path, "`WebACLId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2019-03-26/distributionsByWebACLId/"),
               (kind: VariableSegment, value: "WebACLId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListDistributionsByWebACLId20190326_773804(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   WebACLId: JString (required)
  ##           : The ID of the AWS WAF web ACL that you want to list the associated distributions. If you specify "null" for the ID, the request returns a list of the distributions that aren't associated with a web ACL. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `WebACLId` field"
  var valid_773806 = path.getOrDefault("WebACLId")
  valid_773806 = validateParameter(valid_773806, JString, required = true,
                                 default = nil)
  if valid_773806 != nil:
    section.add "WebACLId", valid_773806
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use <code>Marker</code> and <code>MaxItems</code> to control pagination of results. If you have more than <code>MaxItems</code> distributions that satisfy the request, the response includes a <code>NextMarker</code> element. To get the next page of results, submit another request. For the value of <code>Marker</code>, specify the value of <code>NextMarker</code> from the last response. (For the first request, omit <code>Marker</code>.) 
  ##   MaxItems: JString
  ##           : The maximum number of distributions that you want CloudFront to return in the response body. The maximum and default values are both 100.
  section = newJObject()
  var valid_773807 = query.getOrDefault("Marker")
  valid_773807 = validateParameter(valid_773807, JString, required = false,
                                 default = nil)
  if valid_773807 != nil:
    section.add "Marker", valid_773807
  var valid_773808 = query.getOrDefault("MaxItems")
  valid_773808 = validateParameter(valid_773808, JString, required = false,
                                 default = nil)
  if valid_773808 != nil:
    section.add "MaxItems", valid_773808
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
  var valid_773809 = header.getOrDefault("X-Amz-Date")
  valid_773809 = validateParameter(valid_773809, JString, required = false,
                                 default = nil)
  if valid_773809 != nil:
    section.add "X-Amz-Date", valid_773809
  var valid_773810 = header.getOrDefault("X-Amz-Security-Token")
  valid_773810 = validateParameter(valid_773810, JString, required = false,
                                 default = nil)
  if valid_773810 != nil:
    section.add "X-Amz-Security-Token", valid_773810
  var valid_773811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773811 = validateParameter(valid_773811, JString, required = false,
                                 default = nil)
  if valid_773811 != nil:
    section.add "X-Amz-Content-Sha256", valid_773811
  var valid_773812 = header.getOrDefault("X-Amz-Algorithm")
  valid_773812 = validateParameter(valid_773812, JString, required = false,
                                 default = nil)
  if valid_773812 != nil:
    section.add "X-Amz-Algorithm", valid_773812
  var valid_773813 = header.getOrDefault("X-Amz-Signature")
  valid_773813 = validateParameter(valid_773813, JString, required = false,
                                 default = nil)
  if valid_773813 != nil:
    section.add "X-Amz-Signature", valid_773813
  var valid_773814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773814 = validateParameter(valid_773814, JString, required = false,
                                 default = nil)
  if valid_773814 != nil:
    section.add "X-Amz-SignedHeaders", valid_773814
  var valid_773815 = header.getOrDefault("X-Amz-Credential")
  valid_773815 = validateParameter(valid_773815, JString, required = false,
                                 default = nil)
  if valid_773815 != nil:
    section.add "X-Amz-Credential", valid_773815
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773816: Call_ListDistributionsByWebACLId20190326_773803;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
  ## 
  let valid = call_773816.validator(path, query, header, formData, body)
  let scheme = call_773816.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773816.url(scheme.get, call_773816.host, call_773816.base,
                         call_773816.route, valid.getOrDefault("path"))
  result = hook(call_773816, url, valid)

proc call*(call_773817: Call_ListDistributionsByWebACLId20190326_773803;
          WebACLId: string; Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listDistributionsByWebACLId20190326
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
  ##   Marker: string
  ##         : Use <code>Marker</code> and <code>MaxItems</code> to control pagination of results. If you have more than <code>MaxItems</code> distributions that satisfy the request, the response includes a <code>NextMarker</code> element. To get the next page of results, submit another request. For the value of <code>Marker</code>, specify the value of <code>NextMarker</code> from the last response. (For the first request, omit <code>Marker</code>.) 
  ##   MaxItems: string
  ##           : The maximum number of distributions that you want CloudFront to return in the response body. The maximum and default values are both 100.
  ##   WebACLId: string (required)
  ##           : The ID of the AWS WAF web ACL that you want to list the associated distributions. If you specify "null" for the ID, the request returns a list of the distributions that aren't associated with a web ACL. 
  var path_773818 = newJObject()
  var query_773819 = newJObject()
  add(query_773819, "Marker", newJString(Marker))
  add(query_773819, "MaxItems", newJString(MaxItems))
  add(path_773818, "WebACLId", newJString(WebACLId))
  result = call_773817.call(path_773818, query_773819, nil, nil, nil)

var listDistributionsByWebACLId20190326* = Call_ListDistributionsByWebACLId20190326_773803(
    name: "listDistributionsByWebACLId20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/distributionsByWebACLId/{WebACLId}",
    validator: validate_ListDistributionsByWebACLId20190326_773804, base: "/",
    url: url_ListDistributionsByWebACLId20190326_773805,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource20190326_773820 = ref object of OpenApiRestCall_772597
proc url_ListTagsForResource20190326_773822(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForResource20190326_773821(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List tags for a CloudFront resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Resource: JString (required)
  ##           :  An ARN of a CloudFront resource.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Resource` field"
  var valid_773823 = query.getOrDefault("Resource")
  valid_773823 = validateParameter(valid_773823, JString, required = true,
                                 default = nil)
  if valid_773823 != nil:
    section.add "Resource", valid_773823
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
  var valid_773824 = header.getOrDefault("X-Amz-Date")
  valid_773824 = validateParameter(valid_773824, JString, required = false,
                                 default = nil)
  if valid_773824 != nil:
    section.add "X-Amz-Date", valid_773824
  var valid_773825 = header.getOrDefault("X-Amz-Security-Token")
  valid_773825 = validateParameter(valid_773825, JString, required = false,
                                 default = nil)
  if valid_773825 != nil:
    section.add "X-Amz-Security-Token", valid_773825
  var valid_773826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773826 = validateParameter(valid_773826, JString, required = false,
                                 default = nil)
  if valid_773826 != nil:
    section.add "X-Amz-Content-Sha256", valid_773826
  var valid_773827 = header.getOrDefault("X-Amz-Algorithm")
  valid_773827 = validateParameter(valid_773827, JString, required = false,
                                 default = nil)
  if valid_773827 != nil:
    section.add "X-Amz-Algorithm", valid_773827
  var valid_773828 = header.getOrDefault("X-Amz-Signature")
  valid_773828 = validateParameter(valid_773828, JString, required = false,
                                 default = nil)
  if valid_773828 != nil:
    section.add "X-Amz-Signature", valid_773828
  var valid_773829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773829 = validateParameter(valid_773829, JString, required = false,
                                 default = nil)
  if valid_773829 != nil:
    section.add "X-Amz-SignedHeaders", valid_773829
  var valid_773830 = header.getOrDefault("X-Amz-Credential")
  valid_773830 = validateParameter(valid_773830, JString, required = false,
                                 default = nil)
  if valid_773830 != nil:
    section.add "X-Amz-Credential", valid_773830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773831: Call_ListTagsForResource20190326_773820; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List tags for a CloudFront resource.
  ## 
  let valid = call_773831.validator(path, query, header, formData, body)
  let scheme = call_773831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773831.url(scheme.get, call_773831.host, call_773831.base,
                         call_773831.route, valid.getOrDefault("path"))
  result = hook(call_773831, url, valid)

proc call*(call_773832: Call_ListTagsForResource20190326_773820; Resource: string): Recallable =
  ## listTagsForResource20190326
  ## List tags for a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  var query_773833 = newJObject()
  add(query_773833, "Resource", newJString(Resource))
  result = call_773832.call(nil, query_773833, nil, nil, nil)

var listTagsForResource20190326* = Call_ListTagsForResource20190326_773820(
    name: "listTagsForResource20190326", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2019-03-26/tagging#Resource",
    validator: validate_ListTagsForResource20190326_773821, base: "/",
    url: url_ListTagsForResource20190326_773822,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource20190326_773834 = ref object of OpenApiRestCall_772597
proc url_TagResource20190326_773836(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource20190326_773835(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Add tags to a CloudFront resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Resource: JString (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Resource` field"
  var valid_773837 = query.getOrDefault("Resource")
  valid_773837 = validateParameter(valid_773837, JString, required = true,
                                 default = nil)
  if valid_773837 != nil:
    section.add "Resource", valid_773837
  var valid_773851 = query.getOrDefault("Operation")
  valid_773851 = validateParameter(valid_773851, JString, required = true,
                                 default = newJString("Tag"))
  if valid_773851 != nil:
    section.add "Operation", valid_773851
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
  var valid_773852 = header.getOrDefault("X-Amz-Date")
  valid_773852 = validateParameter(valid_773852, JString, required = false,
                                 default = nil)
  if valid_773852 != nil:
    section.add "X-Amz-Date", valid_773852
  var valid_773853 = header.getOrDefault("X-Amz-Security-Token")
  valid_773853 = validateParameter(valid_773853, JString, required = false,
                                 default = nil)
  if valid_773853 != nil:
    section.add "X-Amz-Security-Token", valid_773853
  var valid_773854 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773854 = validateParameter(valid_773854, JString, required = false,
                                 default = nil)
  if valid_773854 != nil:
    section.add "X-Amz-Content-Sha256", valid_773854
  var valid_773855 = header.getOrDefault("X-Amz-Algorithm")
  valid_773855 = validateParameter(valid_773855, JString, required = false,
                                 default = nil)
  if valid_773855 != nil:
    section.add "X-Amz-Algorithm", valid_773855
  var valid_773856 = header.getOrDefault("X-Amz-Signature")
  valid_773856 = validateParameter(valid_773856, JString, required = false,
                                 default = nil)
  if valid_773856 != nil:
    section.add "X-Amz-Signature", valid_773856
  var valid_773857 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773857 = validateParameter(valid_773857, JString, required = false,
                                 default = nil)
  if valid_773857 != nil:
    section.add "X-Amz-SignedHeaders", valid_773857
  var valid_773858 = header.getOrDefault("X-Amz-Credential")
  valid_773858 = validateParameter(valid_773858, JString, required = false,
                                 default = nil)
  if valid_773858 != nil:
    section.add "X-Amz-Credential", valid_773858
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773860: Call_TagResource20190326_773834; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add tags to a CloudFront resource.
  ## 
  let valid = call_773860.validator(path, query, header, formData, body)
  let scheme = call_773860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773860.url(scheme.get, call_773860.host, call_773860.base,
                         call_773860.route, valid.getOrDefault("path"))
  result = hook(call_773860, url, valid)

proc call*(call_773861: Call_TagResource20190326_773834; Resource: string;
          body: JsonNode; Operation: string = "Tag"): Recallable =
  ## tagResource20190326
  ## Add tags to a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: string (required)
  ##   body: JObject (required)
  var query_773862 = newJObject()
  var body_773863 = newJObject()
  add(query_773862, "Resource", newJString(Resource))
  add(query_773862, "Operation", newJString(Operation))
  if body != nil:
    body_773863 = body
  result = call_773861.call(nil, query_773862, nil, nil, body_773863)

var tagResource20190326* = Call_TagResource20190326_773834(
    name: "tagResource20190326", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/tagging#Operation=Tag&Resource",
    validator: validate_TagResource20190326_773835, base: "/",
    url: url_TagResource20190326_773836, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource20190326_773864 = ref object of OpenApiRestCall_772597
proc url_UntagResource20190326_773866(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResource20190326_773865(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Remove tags from a CloudFront resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Resource: JString (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Resource` field"
  var valid_773867 = query.getOrDefault("Resource")
  valid_773867 = validateParameter(valid_773867, JString, required = true,
                                 default = nil)
  if valid_773867 != nil:
    section.add "Resource", valid_773867
  var valid_773868 = query.getOrDefault("Operation")
  valid_773868 = validateParameter(valid_773868, JString, required = true,
                                 default = newJString("Untag"))
  if valid_773868 != nil:
    section.add "Operation", valid_773868
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
  var valid_773869 = header.getOrDefault("X-Amz-Date")
  valid_773869 = validateParameter(valid_773869, JString, required = false,
                                 default = nil)
  if valid_773869 != nil:
    section.add "X-Amz-Date", valid_773869
  var valid_773870 = header.getOrDefault("X-Amz-Security-Token")
  valid_773870 = validateParameter(valid_773870, JString, required = false,
                                 default = nil)
  if valid_773870 != nil:
    section.add "X-Amz-Security-Token", valid_773870
  var valid_773871 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773871 = validateParameter(valid_773871, JString, required = false,
                                 default = nil)
  if valid_773871 != nil:
    section.add "X-Amz-Content-Sha256", valid_773871
  var valid_773872 = header.getOrDefault("X-Amz-Algorithm")
  valid_773872 = validateParameter(valid_773872, JString, required = false,
                                 default = nil)
  if valid_773872 != nil:
    section.add "X-Amz-Algorithm", valid_773872
  var valid_773873 = header.getOrDefault("X-Amz-Signature")
  valid_773873 = validateParameter(valid_773873, JString, required = false,
                                 default = nil)
  if valid_773873 != nil:
    section.add "X-Amz-Signature", valid_773873
  var valid_773874 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773874 = validateParameter(valid_773874, JString, required = false,
                                 default = nil)
  if valid_773874 != nil:
    section.add "X-Amz-SignedHeaders", valid_773874
  var valid_773875 = header.getOrDefault("X-Amz-Credential")
  valid_773875 = validateParameter(valid_773875, JString, required = false,
                                 default = nil)
  if valid_773875 != nil:
    section.add "X-Amz-Credential", valid_773875
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773877: Call_UntagResource20190326_773864; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from a CloudFront resource.
  ## 
  let valid = call_773877.validator(path, query, header, formData, body)
  let scheme = call_773877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773877.url(scheme.get, call_773877.host, call_773877.base,
                         call_773877.route, valid.getOrDefault("path"))
  result = hook(call_773877, url, valid)

proc call*(call_773878: Call_UntagResource20190326_773864; Resource: string;
          body: JsonNode; Operation: string = "Untag"): Recallable =
  ## untagResource20190326
  ## Remove tags from a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: string (required)
  ##   body: JObject (required)
  var query_773879 = newJObject()
  var body_773880 = newJObject()
  add(query_773879, "Resource", newJString(Resource))
  add(query_773879, "Operation", newJString(Operation))
  if body != nil:
    body_773880 = body
  result = call_773878.call(nil, query_773879, nil, nil, body_773880)

var untagResource20190326* = Call_UntagResource20190326_773864(
    name: "untagResource20190326", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2019-03-26/tagging#Operation=Untag&Resource",
    validator: validate_UntagResource20190326_773865, base: "/",
    url: url_UntagResource20190326_773866, schemes: {Scheme.Https, Scheme.Http})
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
